-- SIGCAL - Fase 4
-- Perfil enriquecido, preferencias, documentos, prestamos y trazabilidad por herramienta.

alter table public.profiles
  add column if not exists first_name text,
  add column if not exists last_name text,
  add column if not exists phone_country_code text,
  add column if not exists phone_country_name text,
  add column if not exists phone_number text,
  add column if not exists avatar_path text,
  add column if not exists theme_preference text not null default 'light',
  add column if not exists language_preference text not null default 'es-PE';

alter table public.tools
  add column if not exists photo_url text,
  add column if not exists acquisition_date date,
  add column if not exists manufacturer_certificate_url text,
  add column if not exists traceability_notes text;

do $$
begin
  create type public.loan_status as enum ('ABIERTO', 'RETORNADO', 'VENCIDO', 'CANCELADO');
exception
  when duplicate_object then null;
end $$;

create table if not exists public.tool_documents (
  id uuid primary key default gen_random_uuid(),
  tool_id uuid not null references public.tools(id) on delete cascade,
  calibration_id uuid references public.calibrations(id) on delete set null,
  document_type text not null default 'GENERAL',
  title text not null,
  file_name text,
  file_url text,
  mime_type text,
  size_kb integer,
  uploaded_by uuid references auth.users(id) default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tool_loans (
  id uuid primary key default gen_random_uuid(),
  tool_id uuid not null references public.tools(id) on delete cascade,
  workshop text not null,
  borrower_name text not null,
  loan_date date not null default current_date,
  expected_return_date date,
  returned_at timestamptz,
  status public.loan_status not null default 'ABIERTO',
  qr_payload text not null default ('SIGCAL-VALE-' || gen_random_uuid()::text),
  observations text,
  created_by uuid references auth.users(id) default auth.uid(),
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tool_traceability (
  id uuid primary key default gen_random_uuid(),
  tool_id uuid not null references public.tools(id) on delete cascade,
  trace_type text not null,
  title text not null,
  description text,
  event_date date not null default current_date,
  document_url text,
  created_by uuid references auth.users(id) default auth.uid(),
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_avatar_path on public.profiles(avatar_path);
create index if not exists idx_profiles_language_preference on public.profiles(language_preference);
create index if not exists idx_tool_documents_tool_id on public.tool_documents(tool_id);
create index if not exists idx_tool_documents_calibration_id on public.tool_documents(calibration_id);
create index if not exists idx_tool_loans_tool_id on public.tool_loans(tool_id);
create index if not exists idx_tool_loans_status on public.tool_loans(status);
create index if not exists idx_tool_traceability_tool_id on public.tool_traceability(tool_id);
create index if not exists idx_tool_traceability_event_date on public.tool_traceability(event_date);

create trigger set_tool_documents_updated_at
before update on public.tool_documents
for each row execute function public.set_updated_at();

create trigger set_tool_loans_updated_at
before update on public.tool_loans
for each row execute function public.set_updated_at();

create trigger set_tool_traceability_updated_at
before update on public.tool_traceability
for each row execute function public.set_updated_at();

drop policy if exists "profiles_update_own_preferences" on public.profiles;
create policy "profiles_update_own_preferences"
on public.profiles
for update
to authenticated
using (auth_user_id = (select auth.uid()))
with check (
  auth_user_id = (select auth.uid())
  and role = app_private.current_user_role()
  and active = true
);

alter table public.tool_documents enable row level security;
alter table public.tool_loans enable row level security;
alter table public.tool_traceability enable row level security;

grant select, insert, update, delete on public.tool_documents to authenticated;
grant select, insert, update, delete on public.tool_loans to authenticated;
grant select, insert, update, delete on public.tool_traceability to authenticated;

drop policy if exists "tool_documents_select_authenticated" on public.tool_documents;
create policy "tool_documents_select_authenticated"
on public.tool_documents
for select
to authenticated
using (true);

drop policy if exists "tool_documents_manage_lider_admin" on public.tool_documents;
create policy "tool_documents_manage_lider_admin"
on public.tool_documents
for all
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "tool_loans_select_authenticated" on public.tool_loans;
create policy "tool_loans_select_authenticated"
on public.tool_loans
for select
to authenticated
using (true);

drop policy if exists "tool_loans_manage_lider_admin" on public.tool_loans;
create policy "tool_loans_manage_lider_admin"
on public.tool_loans
for all
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "tool_traceability_select_authenticated" on public.tool_traceability;
create policy "tool_traceability_select_authenticated"
on public.tool_traceability
for select
to authenticated
using (true);

drop policy if exists "tool_traceability_manage_lider_admin" on public.tool_traceability;
create policy "tool_traceability_manage_lider_admin"
on public.tool_traceability
for all
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-avatars',
  'profile-avatars',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "profile_avatars_read_own" on storage.objects;
create policy "profile_avatars_read_own"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'profile-avatars'
  and owner = (select auth.uid())
);

drop policy if exists "profile_avatars_insert_own" on storage.objects;
create policy "profile_avatars_insert_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'profile-avatars'
  and owner = (select auth.uid())
);

drop policy if exists "profile_avatars_update_own" on storage.objects;
create policy "profile_avatars_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'profile-avatars'
  and owner = (select auth.uid())
)
with check (
  bucket_id = 'profile-avatars'
  and owner = (select auth.uid())
);

drop policy if exists "profile_avatars_delete_own" on storage.objects;
create policy "profile_avatars_delete_own"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'profile-avatars'
  and owner = (select auth.uid())
);

create or replace function app_private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  insert into public.profiles (
    auth_user_id,
    email,
    full_name,
    first_name,
    last_name,
    role
  )
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'first_name',
    new.raw_user_meta_data ->> 'last_name',
    'usuario'
  )
  on conflict (auth_user_id) do update
  set email = excluded.email,
      full_name = coalesce(public.profiles.full_name, excluded.full_name),
      first_name = coalesce(public.profiles.first_name, excluded.first_name),
      last_name = coalesce(public.profiles.last_name, excluded.last_name),
      updated_at = now();

  return new;
end;
$$;

with sample_tool as (
  select id, internal_code
  from public.tools
  where internal_code in ('TW-40291', 'MM-22110', 'SC-88122')
)
insert into public.tool_documents (tool_id, document_type, title, file_name, file_url, mime_type, size_kb)
select id, 'CERTIFICADO', 'Certificado de calibracion historico', 'certificate-' || lower(coalesce(internal_code, 'tool')) || '.pdf', null, 'application/pdf', 1240
from sample_tool
on conflict do nothing;

with sample_tool as (
  select id, internal_code
  from public.tools
  where internal_code = 'MM-22110'
)
insert into public.tool_loans (tool_id, workshop, borrower_name, loan_date, expected_return_date, status, qr_payload, observations)
select id, 'Taller de Avionica', 'Tco. Juan Perez', current_date - interval '3 days', current_date + interval '4 days', 'ABIERTO', 'SIGCAL-VALE-' || coalesce(internal_code, id::text), 'Prestamo operativo para inspeccion programada.'
from sample_tool
on conflict do nothing;

with sample_tool as (
  select id, internal_code, nomenclature
  from public.tools
  where internal_code in ('TW-40291', 'MM-22110', 'SC-88122')
)
insert into public.tool_traceability (tool_id, trace_type, title, description, event_date)
select id, 'FABRICANTE', 'Ingreso de fabricante', 'Registro inicial de trazabilidad para ' || nomenclature, current_date - interval '420 days'
from sample_tool
on conflict do nothing;
