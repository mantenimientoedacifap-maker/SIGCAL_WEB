-- SIGCAL - Fase 3
-- Ajustes recomendados por Supabase Advisors.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  new.updated_by = auth.uid();
  return new;
end;
$$;

create index if not exists idx_categories_updated_by on public.categories(updated_by);
create index if not exists idx_manufacturers_updated_by on public.manufacturers(updated_by);
create index if not exists idx_locations_updated_by on public.locations(updated_by);
create index if not exists idx_tools_updated_by on public.tools(updated_by);
create index if not exists idx_calibrations_updated_by on public.calibrations(updated_by);
create index if not exists idx_shipments_updated_by on public.calibration_shipments(updated_by);

drop policy if exists "categories_manage_lider_admin" on public.categories;
drop policy if exists "manufacturers_manage_lider_admin" on public.manufacturers;
drop policy if exists "locations_manage_lider_admin" on public.locations;
drop policy if exists "tools_manage_lider_admin" on public.tools;
drop policy if exists "calibrations_manage_lider_admin" on public.calibrations;
drop policy if exists "shipments_manage_lider_admin" on public.calibration_shipments;

create policy "categories_insert_lider_admin"
on public.categories
for insert
to authenticated
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "categories_update_lider_admin"
on public.categories
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "categories_delete_lider_admin"
on public.categories
for delete
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "manufacturers_insert_lider_admin"
on public.manufacturers
for insert
to authenticated
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "manufacturers_update_lider_admin"
on public.manufacturers
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "manufacturers_delete_lider_admin"
on public.manufacturers
for delete
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "locations_insert_lider_admin"
on public.locations
for insert
to authenticated
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "locations_update_lider_admin"
on public.locations
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "locations_delete_lider_admin"
on public.locations
for delete
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "tools_insert_lider_admin"
on public.tools
for insert
to authenticated
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "tools_update_lider_admin"
on public.tools
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "tools_delete_lider_admin"
on public.tools
for delete
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "calibrations_insert_lider_admin"
on public.calibrations
for insert
to authenticated
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "calibrations_update_lider_admin"
on public.calibrations
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "calibrations_delete_lider_admin"
on public.calibrations
for delete
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "shipments_insert_lider_admin"
on public.calibration_shipments
for insert
to authenticated
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "shipments_update_lider_admin"
on public.calibration_shipments
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "shipments_delete_lider_admin"
on public.calibration_shipments
for delete
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));
