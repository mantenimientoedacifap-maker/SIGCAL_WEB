# 11 — SQL Inicial para Supabase

Este archivo contiene el SQL inicial que Codex debe convertir en un script ejecutable para Supabase.

```sql
create extension if not exists "pgcrypto";

create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists manufacturers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists locations (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists tools (
  id uuid primary key default gen_random_uuid(),
  internal_code text unique,
  nomenclature text not null,
  category_id uuid references categories(id),
  manufacturer_id uuid references manufacturers(id),
  model text,
  serial_number text,
  part_number text,
  description text,
  current_location text,
  current_status text default 'DISPONIBLE',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists calibrations (
  id uuid primary key default gen_random_uuid(),
  tool_id uuid references tools(id) on delete cascade,
  calibration_date date not null,
  validity_months integer not null,
  expiration_date date not null,
  calibration_center text,
  certificate_number text,
  certificate_file_url text,
  result text default 'PENDIENTE',
  observations text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists calibration_shipments (
  id uuid primary key default gen_random_uuid(),
  tool_id uuid references tools(id) on delete cascade,
  calibration_center text not null,
  shipment_date date not null,
  remission_guide_number text,
  remission_guide_file_url text,
  estimated_return_date date,
  actual_return_date date,
  shipment_status text default 'ENVIADO',
  observations text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_tools_internal_code on tools(internal_code);
create index if not exists idx_tools_serial_number on tools(serial_number);
create index if not exists idx_tools_current_location on tools(current_location);
create index if not exists idx_tools_current_status on tools(current_status);

create index if not exists idx_calibrations_tool_id on calibrations(tool_id);
create index if not exists idx_calibrations_expiration_date on calibrations(expiration_date);
create index if not exists idx_calibrations_result on calibrations(result);

create index if not exists idx_shipments_tool_id on calibration_shipments(tool_id);
create index if not exists idx_shipments_status on calibration_shipments(shipment_status);
create index if not exists idx_shipments_estimated_return on calibration_shipments(estimated_return_date);

insert into categories (name, description) values
('Herramienta especial', 'Herramientas especiales sujetas a control'),
('Equipo electrónico', 'Equipos electrónicos sujetos a calibración'),
('Instrumento de medición', 'Instrumentos metrológicos'),
('Equipo de soporte', 'Equipos de apoyo técnico'),
('Otro', 'Otros elementos sujetos a calibración')
on conflict (name) do nothing;

insert into locations (name, description) values
('Almacén', 'Ubicación principal de almacenamiento'),
('Taller', 'Área de trabajo técnico'),
('Línea de vuelo', 'Área operacional de línea de vuelo'),
('Hangar', 'Área de mantenimiento o resguardo'),
('Centro de calibración', 'Proveedor o laboratorio de calibración'),
('En préstamo', 'Asignado temporalmente a usuario o dependencia'),
('Fuera de servicio', 'No disponible para uso'),
('Baja', 'Retirado del servicio'),
('Otro', 'Otra ubicación')
on conflict (name) do nothing;

insert into manufacturers (name) values
('SNAP-ON'),
('ALPHA'),
('FLUKE'),
('MITUTOYO'),
('FACOM'),
('TEKTRONIX'),
('BOSCH'),
('OTRO')
on conflict (name) do nothing;

alter table categories enable row level security;
alter table manufacturers enable row level security;
alter table locations enable row level security;
alter table tools enable row level security;
alter table calibrations enable row level security;
alter table calibration_shipments enable row level security;

create policy "Authenticated users can read categories"
on categories for select
to authenticated
using (true);

create policy "Authenticated users can read manufacturers"
on manufacturers for select
to authenticated
using (true);

create policy "Authenticated users can read locations"
on locations for select
to authenticated
using (true);

create policy "Authenticated users can manage tools"
on tools for all
to authenticated
using (true)
with check (true);

create policy "Authenticated users can manage calibrations"
on calibrations for all
to authenticated
using (true)
with check (true);

create policy "Authenticated users can manage calibration shipments"
on calibration_shipments for all
to authenticated
using (true)
with check (true);
```
