-- Phase 11: Habilita edición y anulación de calibraciones con trazabilidad.
--
-- Añade un campo `status` a la tabla `calibrations` para distinguir registros
-- activos de los anulados, más metadatos de anulación.
-- También actualiza políticas RLS para reflejar el nuevo campo.

begin;

-- 1. Añadir columnas de estado a la tabla calibrations
alter table public.calibrations
  add column if not exists status text not null default 'ACTIVO',
  add column if not exists annulment_reason text,
  add column if not exists annulled_at timestamptz;

-- 2. Actualizar políticas RLS para que lider/admin puedan modificar los
--    nuevos campos (las políticas existentes ya permiten UPDATE, solo
--    aseguramos que los roles correctos sigan teniendo acceso).
--    No se necesita nueva política; las existentes cubren la operación.
--    Pero sí regeneramos las políticas por si acaso:

drop policy if exists "calibrations_manage_lider_admin" on public.calibrations;
create policy "calibrations_manage_lider_admin"
on public.calibrations
for all
to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and (p.role = 'lider' or p.role = 'administrador')
  )
)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and (p.role = 'lider' or p.role = 'administrador')
  )
);

commit;
