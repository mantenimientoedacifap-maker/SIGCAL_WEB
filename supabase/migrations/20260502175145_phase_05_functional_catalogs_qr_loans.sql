-- SIGCAL - Fase 5
-- Catalogos funcionales, QR unico por herramienta, proveedores, prestatarios y prestamos relacionales.

create table if not exists public.calibration_providers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  contact_name text,
  contact_email text,
  phone text,
  address text,
  active boolean not null default true,
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workshops (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  workshop_type text not null default 'TALLER',
  description text,
  active boolean not null default true,
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.borrowers (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  document_number text,
  email text,
  phone text,
  workshop_id uuid references public.workshops(id),
  active boolean not null default true,
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint borrowers_full_name_document_unique unique (full_name, document_number)
);

alter table public.tools
  add column if not exists qr_code text unique,
  add column if not exists data_sheet_url text;

update public.tools
set qr_code = 'SIGCAL-TOOL-' || id::text
where qr_code is null;

alter table public.tools
  alter column qr_code set default ('SIGCAL-TOOL-' || gen_random_uuid()::text),
  alter column qr_code set not null;

alter table public.calibrations
  add column if not exists provider_id uuid references public.calibration_providers(id);

alter table public.tool_loans
  add column if not exists workshop_id uuid references public.workshops(id),
  add column if not exists borrower_id uuid references public.borrowers(id),
  add column if not exists return_observations text;

create index if not exists idx_calibration_providers_active on public.calibration_providers(active);
create index if not exists idx_workshops_active on public.workshops(active);
create index if not exists idx_borrowers_active on public.borrowers(active);
create index if not exists idx_borrowers_workshop_id on public.borrowers(workshop_id);
create index if not exists idx_tools_qr_code on public.tools(qr_code);
create index if not exists idx_calibrations_provider_id on public.calibrations(provider_id);
create index if not exists idx_tool_loans_workshop_id on public.tool_loans(workshop_id);
create index if not exists idx_tool_loans_borrower_id on public.tool_loans(borrower_id);

create trigger set_calibration_providers_updated_at
before update on public.calibration_providers
for each row execute function public.set_updated_at();

create trigger set_workshops_updated_at
before update on public.workshops
for each row execute function public.set_updated_at();

create trigger set_borrowers_updated_at
before update on public.borrowers
for each row execute function public.set_updated_at();

alter table public.calibration_providers enable row level security;
alter table public.workshops enable row level security;
alter table public.borrowers enable row level security;

grant select, insert, update, delete on public.calibration_providers to authenticated;
grant select, insert, update, delete on public.workshops to authenticated;
grant select, insert, update, delete on public.borrowers to authenticated;

drop policy if exists "calibration_providers_select_authenticated" on public.calibration_providers;
create policy "calibration_providers_select_authenticated"
on public.calibration_providers
for select
to authenticated
using (true);

drop policy if exists "calibration_providers_insert_lider_admin" on public.calibration_providers;
create policy "calibration_providers_insert_lider_admin"
on public.calibration_providers
for insert
to authenticated
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "calibration_providers_update_lider_admin" on public.calibration_providers;
create policy "calibration_providers_update_lider_admin"
on public.calibration_providers
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "calibration_providers_delete_lider_admin" on public.calibration_providers;
create policy "calibration_providers_delete_lider_admin"
on public.calibration_providers
for delete
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "workshops_select_authenticated" on public.workshops;
create policy "workshops_select_authenticated"
on public.workshops
for select
to authenticated
using (true);

drop policy if exists "workshops_insert_lider_admin" on public.workshops;
create policy "workshops_insert_lider_admin"
on public.workshops
for insert
to authenticated
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "workshops_update_lider_admin" on public.workshops;
create policy "workshops_update_lider_admin"
on public.workshops
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "workshops_delete_lider_admin" on public.workshops;
create policy "workshops_delete_lider_admin"
on public.workshops
for delete
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "borrowers_select_authenticated" on public.borrowers;
create policy "borrowers_select_authenticated"
on public.borrowers
for select
to authenticated
using (true);

drop policy if exists "borrowers_insert_lider_admin" on public.borrowers;
create policy "borrowers_insert_lider_admin"
on public.borrowers
for insert
to authenticated
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "borrowers_update_lider_admin" on public.borrowers;
create policy "borrowers_update_lider_admin"
on public.borrowers
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "borrowers_delete_lider_admin" on public.borrowers;
create policy "borrowers_delete_lider_admin"
on public.borrowers
for delete
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

insert into public.categories (name, description) values
('Herramienta Especial', 'Herramientas especiales sujetas a control y calibracion'),
('Equipo Electronico', 'Equipos electronicos sujetos a calibracion'),
('Herramienta Controlada', 'Herramientas controladas por prestamo, trazabilidad o vencimiento')
on conflict (name) do update set description = excluded.description;

insert into public.calibration_providers (name, contact_name, phone, address) values
('INACAL Metrologia', 'Mesa de partes', '+51 01 6408820', 'Lima, Peru'),
('SELEC External Lab', 'Coordinacion tecnica', '+51 999 000 001', 'Lima, Peru'),
('Fluke Service Center', 'Servicio tecnico', '+1 800 443 5853', 'USA'),
('Air Data Lab', 'Laboratorio externo', '+51 999 000 002', 'Lima, Peru'),
('Lab Ambiental FAP', 'Responsable metrologico', '+51 999 000 003', 'Base FAP')
on conflict (name) do update set
  contact_name = excluded.contact_name,
  phone = excluded.phone,
  address = excluded.address;

insert into public.workshops (name, workshop_type, description) values
('Taller de Aeronaves', 'TALLER', 'Area responsable de mantenimiento de aeronaves'),
('Taller de Estructuras', 'TALLER', 'Area responsable de estructuras'),
('Taller de Motores', 'TALLER', 'Area responsable de motores'),
('Taller de Avionica', 'TALLER', 'Area responsable de avionica'),
('Almacen', 'OFICINA', 'Custodia principal de herramientas'),
('Linea de vuelo', 'OFICINA', 'Area operacional de linea de vuelo'),
('Hangar', 'OFICINA', 'Area de resguardo y mantenimiento')
on conflict (name) do update set
  workshop_type = excluded.workshop_type,
  description = excluded.description;

insert into public.borrowers (full_name, document_number, email, phone, workshop_id)
select borrower.full_name, borrower.document_number, borrower.email, borrower.phone, w.id
from (
  values
    ('Tco. Juan Perez', 'JP-001', 'juan.perez@example.com', '+51 999 111 001', 'Taller de Avionica'),
    ('Tco. Maria Torres', 'MT-002', 'maria.torres@example.com', '+51 999 111 002', 'Taller de Aeronaves'),
    ('Tco. Luis Ramos', 'LR-003', 'luis.ramos@example.com', '+51 999 111 003', 'Taller de Motores'),
    ('Tco. Ana Castillo', 'AC-004', 'ana.castillo@example.com', '+51 999 111 004', 'Taller de Estructuras')
) as borrower(full_name, document_number, email, phone, workshop_name)
join public.workshops w on w.name = borrower.workshop_name
on conflict (full_name, document_number) do update set
  email = excluded.email,
  phone = excluded.phone,
  workshop_id = excluded.workshop_id;

update public.calibrations c
set provider_id = p.id
from public.calibration_providers p
where c.provider_id is null
  and c.calibration_center = p.name;

update public.tool_loans tl
set workshop_id = w.id
from public.workshops w
where tl.workshop_id is null
  and tl.workshop = w.name;

update public.tool_loans tl
set borrower_id = b.id
from public.borrowers b
where tl.borrower_id is null
  and tl.borrower_name = b.full_name;
