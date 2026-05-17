-- SIGCAL - Fase 7
-- Inventario premium: codigo interno automatico, baja auditada, catalogos
-- enriquecidos y envios conectados a proveedores.

alter table public.categories
  add column if not exists type_code text;

update public.categories
set type_code = case
  when upper(name) like '%ESPECIAL%' then 'HE'
  when upper(name) like '%ELECTRONICO%' then 'EE'
  when upper(name) like '%CONTROLADA%' then 'HC'
  else coalesce(type_code, 'GN')
end
where type_code is null or btrim(type_code) = '';

alter table public.categories
  alter column type_code set default 'GN',
  alter column type_code set not null;

alter table public.categories
  drop constraint if exists categories_type_code_format_check;

alter table public.categories
  add constraint categories_type_code_format_check
  check (type_code ~ '^[A-Z0-9]{2}$');

create index if not exists idx_categories_type_code
on public.categories(type_code);

create table if not exists public.tool_code_settings (
  id boolean primary key default true,
  symbol text not null default 'C',
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tool_code_settings_singleton check (id),
  constraint tool_code_settings_symbol_check check (symbol ~ '^[A-Z]{1,2}$')
);

create table if not exists public.tool_code_counters (
  type_code text not null,
  year_suffix text not null,
  last_value integer not null default 0 check (last_value >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (type_code, year_suffix)
);

insert into public.tool_code_settings (id, symbol)
values (true, 'C')
on conflict (id) do nothing;

alter table public.tools
  add column if not exists retired_at timestamptz,
  add column if not exists retired_by uuid references auth.users(id),
  add column if not exists retirement_reason text,
  add column if not exists retirement_location text default 'ALMACEN DE BAJAS';

alter table public.calibration_shipments
  add column if not exists provider_id uuid references public.calibration_providers(id);

create index if not exists idx_tools_retired_at on public.tools(retired_at);
create index if not exists idx_tools_retirement_location on public.tools(retirement_location);
create index if not exists idx_shipments_provider_id on public.calibration_shipments(provider_id);

create trigger set_tool_code_settings_updated_at
before update on public.tool_code_settings
for each row execute function public.set_updated_at();

create trigger set_tool_code_counters_updated_at
before update on public.tool_code_counters
for each row execute function public.set_updated_at();

create or replace function app_private.next_tool_internal_code(p_category_id uuid)
returns text
language plpgsql
security definer
set search_path = public, app_private
as $$
declare
  v_symbol text;
  v_type_code text;
  v_year text;
  v_next integer;
begin
  select symbol into v_symbol
  from public.tool_code_settings
  where id = true;

  v_symbol := coalesce(v_symbol, 'C');

  select type_code into v_type_code
  from public.categories
  where id = p_category_id;

  v_type_code := coalesce(v_type_code, 'GN');
  v_year := to_char(now(), 'YY');

  insert into public.tool_code_counters(type_code, year_suffix, last_value)
  values (v_type_code, v_year, 1)
  on conflict (type_code, year_suffix)
  do update set
    last_value = public.tool_code_counters.last_value + 1,
    updated_at = now()
  returning last_value into v_next;

  return v_symbol || '-' || v_type_code || '-' || lpad(v_next::text, 4, '0') || '-' || v_year;
end;
$$;

create or replace function public.set_tool_operational_defaults()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
begin
  if tg_op = 'INSERT' then
    if new.internal_code is null or btrim(new.internal_code) = '' then
      new.internal_code := app_private.next_tool_internal_code(new.category_id);
    end if;
  elsif tg_op = 'UPDATE' then
    if old.internal_code is not null and new.internal_code is distinct from old.internal_code then
      raise exception 'internal_code is immutable after tool creation';
    end if;
  end if;

  new.internal_code := upper(btrim(new.internal_code));
  new.nomenclature := upper(btrim(new.nomenclature));
  new.model := nullif(upper(btrim(coalesce(new.model, ''))), '');
  new.serial_number := nullif(upper(btrim(coalesce(new.serial_number, ''))), '');
  new.part_number := nullif(upper(btrim(coalesce(new.part_number, ''))), '');
  new.current_location := nullif(upper(btrim(coalesce(new.current_location, ''))), '');

  if new.current_status = 'BAJA' and new.retired_at is null then
    new.retired_at := now();
    new.retired_by := coalesce(new.retired_by, auth.uid());
    new.retirement_location := coalesce(new.retirement_location, 'ALMACEN DE BAJAS');
    new.current_location := 'ALMACEN DE BAJAS';
  end if;

  return new;
end;
$$;

drop trigger if exists set_tool_operational_defaults on public.tools;
create trigger set_tool_operational_defaults
before insert or update on public.tools
for each row execute function public.set_tool_operational_defaults();

do $$
declare
  tool_record record;
begin
  for tool_record in
    select id, category_id
    from public.tools
    where internal_code is null or btrim(internal_code) = ''
    order by created_at, id
  loop
    update public.tools
    set internal_code = app_private.next_tool_internal_code(tool_record.category_id)
    where id = tool_record.id;
  end loop;
end $$;

update public.calibration_shipments s
set provider_id = p.id
from public.calibration_providers p
where s.provider_id is null
  and upper(s.calibration_center) = upper(p.name);

alter table public.tool_code_settings enable row level security;
alter table public.tool_code_counters enable row level security;

grant select, update on public.tool_code_settings to authenticated;
grant select on public.tool_code_counters to authenticated;

drop policy if exists "tool_code_settings_select_authenticated" on public.tool_code_settings;
create policy "tool_code_settings_select_authenticated"
on public.tool_code_settings
for select
to authenticated
using (true);

drop policy if exists "tool_code_settings_update_lider_admin" on public.tool_code_settings;
create policy "tool_code_settings_update_lider_admin"
on public.tool_code_settings
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "tool_code_counters_select_lider_admin" on public.tool_code_counters;
create policy "tool_code_counters_select_lider_admin"
on public.tool_code_counters
for select
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));
