-- SIGCAL - Fase 3
-- Esquema inicial Supabase con autenticacion, roles, RLS y Storage.

create extension if not exists "pgcrypto";

do $$
begin
  create type public.app_role as enum ('lider', 'administrador', 'usuario');
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.physical_status as enum (
    'DISPONIBLE',
    'EN_USO',
    'EN_CALIBRACION',
    'FUERA_DE_SERVICIO',
    'BAJA',
    'EXTRAVIADO'
  );
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.calibration_result as enum (
    'CONFORME',
    'NO_CONFORME',
    'CONDICIONADO',
    'PENDIENTE'
  );
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.shipment_status as enum (
    'PENDIENTE_ENVIO',
    'ENVIADO',
    'RECIBIDO_POR_PROVEEDOR',
    'EN_PROCESO',
    'LISTO_PARA_RECOJO',
    'RETORNADO',
    'OBSERVADO'
  );
exception
  when duplicate_object then null;
end $$;

create schema if not exists app_private;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  role public.app_role not null default 'usuario',
  active boolean not null default true,
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  active boolean not null default true,
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.manufacturers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean not null default true,
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.locations (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  active boolean not null default true,
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tools (
  id uuid primary key default gen_random_uuid(),
  internal_code text unique,
  nomenclature text not null,
  category_id uuid references public.categories(id),
  manufacturer_id uuid references public.manufacturers(id),
  model text,
  serial_number text,
  part_number text,
  description text,
  current_location text,
  current_status public.physical_status not null default 'DISPONIBLE',
  created_by uuid references auth.users(id) default auth.uid(),
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.calibrations (
  id uuid primary key default gen_random_uuid(),
  tool_id uuid not null references public.tools(id) on delete cascade,
  calibration_date date not null,
  validity_months integer not null check (validity_months > 0),
  expiration_date date not null,
  calibration_center text,
  certificate_number text,
  certificate_file_url text,
  result public.calibration_result not null default 'PENDIENTE',
  observations text,
  created_by uuid references auth.users(id) default auth.uid(),
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.calibration_shipments (
  id uuid primary key default gen_random_uuid(),
  tool_id uuid not null references public.tools(id) on delete cascade,
  calibration_center text not null,
  shipment_date date not null,
  remission_guide_number text,
  remission_guide_file_url text,
  estimated_return_date date,
  actual_return_date date,
  shipment_status public.shipment_status not null default 'ENVIADO',
  observations text,
  created_by uuid references auth.users(id) default auth.uid(),
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists updated_by uuid references auth.users(id);

alter table public.categories
  add column if not exists updated_by uuid references auth.users(id);

alter table public.manufacturers
  add column if not exists updated_by uuid references auth.users(id);

alter table public.locations
  add column if not exists updated_by uuid references auth.users(id);

alter table public.tools
  add column if not exists created_by uuid references auth.users(id) default auth.uid(),
  add column if not exists updated_by uuid references auth.users(id);

alter table public.calibrations
  add column if not exists created_by uuid references auth.users(id) default auth.uid(),
  add column if not exists updated_by uuid references auth.users(id);

alter table public.calibration_shipments
  add column if not exists created_by uuid references auth.users(id) default auth.uid(),
  add column if not exists updated_by uuid references auth.users(id);

create index if not exists idx_profiles_auth_user_id on public.profiles(auth_user_id);
create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_profiles_active on public.profiles(active);
create index if not exists idx_profiles_updated_by on public.profiles(updated_by);

create index if not exists idx_tools_internal_code on public.tools(internal_code);
create index if not exists idx_tools_serial_number on public.tools(serial_number);
create index if not exists idx_tools_category_id on public.tools(category_id);
create index if not exists idx_tools_manufacturer_id on public.tools(manufacturer_id);
create index if not exists idx_tools_current_location on public.tools(current_location);
create index if not exists idx_tools_current_status on public.tools(current_status);
create index if not exists idx_tools_created_by on public.tools(created_by);

create index if not exists idx_calibrations_tool_id on public.calibrations(tool_id);
create index if not exists idx_calibrations_expiration_date on public.calibrations(expiration_date);
create index if not exists idx_calibrations_result on public.calibrations(result);
create index if not exists idx_calibrations_created_by on public.calibrations(created_by);

create index if not exists idx_shipments_tool_id on public.calibration_shipments(tool_id);
create index if not exists idx_shipments_status on public.calibration_shipments(shipment_status);
create index if not exists idx_shipments_estimated_return on public.calibration_shipments(estimated_return_date);
create index if not exists idx_shipments_created_by on public.calibration_shipments(created_by);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  new.updated_by = auth.uid();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_categories_updated_at on public.categories;
create trigger set_categories_updated_at
before update on public.categories
for each row execute function public.set_updated_at();

drop trigger if exists set_manufacturers_updated_at on public.manufacturers;
create trigger set_manufacturers_updated_at
before update on public.manufacturers
for each row execute function public.set_updated_at();

drop trigger if exists set_locations_updated_at on public.locations;
create trigger set_locations_updated_at
before update on public.locations
for each row execute function public.set_updated_at();

drop trigger if exists set_tools_updated_at on public.tools;
create trigger set_tools_updated_at
before update on public.tools
for each row execute function public.set_updated_at();

drop trigger if exists set_calibrations_updated_at on public.calibrations;
create trigger set_calibrations_updated_at
before update on public.calibrations
for each row execute function public.set_updated_at();

drop trigger if exists set_shipments_updated_at on public.calibration_shipments;
create trigger set_shipments_updated_at
before update on public.calibration_shipments
for each row execute function public.set_updated_at();

create or replace function app_private.current_user_role()
returns public.app_role
language sql
stable
security definer
set search_path = public
as $$
  select p.role
  from public.profiles p
  where p.auth_user_id = (select auth.uid())
    and p.active = true
  limit 1;
$$;

create or replace function app_private.has_role(required_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select app_private.current_user_role() = required_role;
$$;

create or replace function app_private.has_any_role(required_roles public.app_role[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select app_private.current_user_role() = any(required_roles);
$$;

create or replace function app_private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  insert into public.profiles (auth_user_id, email, full_name, role)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    'usuario'
  )
  on conflict (auth_user_id) do update
  set email = excluded.email,
      full_name = coalesce(public.profiles.full_name, excluded.full_name),
      updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function app_private.handle_new_user();

grant usage on schema public to anon, authenticated;
grant usage on schema app_private to authenticated;

grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.categories to authenticated;
grant select, insert, update, delete on public.manufacturers to authenticated;
grant select, insert, update, delete on public.locations to authenticated;
grant select, insert, update, delete on public.tools to authenticated;
grant select, insert, update, delete on public.calibrations to authenticated;
grant select, insert, update, delete on public.calibration_shipments to authenticated;

grant execute on function app_private.current_user_role() to authenticated;
grant execute on function app_private.has_role(public.app_role) to authenticated;
grant execute on function app_private.has_any_role(public.app_role[]) to authenticated;

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.manufacturers enable row level security;
alter table public.locations enable row level security;
alter table public.tools enable row level security;
alter table public.calibrations enable row level security;
alter table public.calibration_shipments enable row level security;

drop policy if exists "profiles_select_own_or_leadership" on public.profiles;
create policy "profiles_select_own_or_leadership"
on public.profiles
for select
to authenticated
using (
  auth_user_id = (select auth.uid())
  or app_private.has_any_role(array['lider', 'administrador']::public.app_role[])
);

drop policy if exists "profiles_lider_update" on public.profiles;
create policy "profiles_lider_update"
on public.profiles
for update
to authenticated
using (app_private.has_role('lider'))
with check (app_private.has_role('lider'));

drop policy if exists "catalog_select_authenticated" on public.categories;
create policy "catalog_select_authenticated"
on public.categories
for select
to authenticated
using (true);

drop policy if exists "manufacturers_select_authenticated" on public.manufacturers;
create policy "manufacturers_select_authenticated"
on public.manufacturers
for select
to authenticated
using (true);

drop policy if exists "locations_select_authenticated" on public.locations;
create policy "locations_select_authenticated"
on public.locations
for select
to authenticated
using (true);

drop policy if exists "categories_manage_lider_admin" on public.categories;
create policy "categories_manage_lider_admin"
on public.categories
for all
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "manufacturers_manage_lider_admin" on public.manufacturers;
create policy "manufacturers_manage_lider_admin"
on public.manufacturers
for all
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "locations_manage_lider_admin" on public.locations;
create policy "locations_manage_lider_admin"
on public.locations
for all
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "tools_select_authenticated" on public.tools;
create policy "tools_select_authenticated"
on public.tools
for select
to authenticated
using (true);

drop policy if exists "tools_manage_lider_admin" on public.tools;
create policy "tools_manage_lider_admin"
on public.tools
for all
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "calibrations_select_authenticated" on public.calibrations;
create policy "calibrations_select_authenticated"
on public.calibrations
for select
to authenticated
using (true);

drop policy if exists "calibrations_manage_lider_admin" on public.calibrations;
create policy "calibrations_manage_lider_admin"
on public.calibrations
for all
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "shipments_select_authenticated" on public.calibration_shipments;
create policy "shipments_select_authenticated"
on public.calibration_shipments
for select
to authenticated
using (true);

drop policy if exists "shipments_manage_lider_admin" on public.calibration_shipments;
create policy "shipments_manage_lider_admin"
on public.calibration_shipments
for all
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

insert into public.categories (name, description) values
('Herramienta especial', 'Herramientas especiales sujetas a control'),
('Equipo electronico', 'Equipos electronicos sujetos a calibracion'),
('Instrumento de medicion', 'Instrumentos metrologicos'),
('Equipo de soporte', 'Equipos de apoyo tecnico'),
('Otro', 'Otros elementos sujetos a calibracion')
on conflict (name) do nothing;

insert into public.locations (name, description) values
('Almacen', 'Ubicacion principal de almacenamiento'),
('Taller', 'Area de trabajo tecnico'),
('Linea de vuelo', 'Area operacional de linea de vuelo'),
('Hangar', 'Area de mantenimiento o resguardo'),
('Centro de calibracion', 'Proveedor o laboratorio de calibracion'),
('En prestamo', 'Asignado temporalmente a usuario o dependencia'),
('Fuera de servicio', 'No disponible para uso'),
('Baja', 'Retirado del servicio'),
('Otro', 'Otra ubicacion')
on conflict (name) do nothing;

insert into public.manufacturers (name) values
('SNAP-ON'),
('ALPHA'),
('FLUKE'),
('MITUTOYO'),
('FACOM'),
('TEKTRONIX'),
('BOSCH'),
('OTRO')
on conflict (name) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'calibration-certificates',
    'calibration-certificates',
    false,
    10485760,
    array['application/pdf', 'image/jpeg', 'image/png']::text[]
  ),
  (
    'remission-guides',
    'remission-guides',
    false,
    10485760,
    array['application/pdf', 'image/jpeg', 'image/png']::text[]
  ),
  (
    'tool-images',
    'tool-images',
    false,
    10485760,
    array['image/jpeg', 'image/png']::text[]
  ),
  (
    'support-documents',
    'support-documents',
    false,
    10485760,
    array['application/pdf', 'image/jpeg', 'image/png']::text[]
  )
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "sigcal_storage_read_authenticated" on storage.objects;
create policy "sigcal_storage_read_authenticated"
on storage.objects
for select
to authenticated
using (
  bucket_id in (
    'calibration-certificates',
    'remission-guides',
    'tool-images',
    'support-documents'
  )
);

drop policy if exists "sigcal_storage_insert_lider_admin" on storage.objects;
create policy "sigcal_storage_insert_lider_admin"
on storage.objects
for insert
to authenticated
with check (
  bucket_id in (
    'calibration-certificates',
    'remission-guides',
    'tool-images',
    'support-documents'
  )
  and app_private.has_any_role(array['lider', 'administrador']::public.app_role[])
);

drop policy if exists "sigcal_storage_update_lider_admin" on storage.objects;
create policy "sigcal_storage_update_lider_admin"
on storage.objects
for update
to authenticated
using (
  bucket_id in (
    'calibration-certificates',
    'remission-guides',
    'tool-images',
    'support-documents'
  )
  and app_private.has_any_role(array['lider', 'administrador']::public.app_role[])
)
with check (
  bucket_id in (
    'calibration-certificates',
    'remission-guides',
    'tool-images',
    'support-documents'
  )
  and app_private.has_any_role(array['lider', 'administrador']::public.app_role[])
);

drop policy if exists "sigcal_storage_delete_lider_admin" on storage.objects;
create policy "sigcal_storage_delete_lider_admin"
on storage.objects
for delete
to authenticated
using (
  bucket_id in (
    'calibration-certificates',
    'remission-guides',
    'tool-images',
    'support-documents'
  )
  and app_private.has_any_role(array['lider', 'administrador']::public.app_role[])
);
