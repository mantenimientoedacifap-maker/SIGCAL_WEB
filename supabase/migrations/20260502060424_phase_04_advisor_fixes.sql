-- SIGCAL - Fase 4
-- Ajustes recomendados por Supabase Advisors para indices y politicas RLS.

create index if not exists idx_tool_documents_uploaded_by on public.tool_documents(uploaded_by);
create index if not exists idx_tool_loans_created_by on public.tool_loans(created_by);
create index if not exists idx_tool_loans_updated_by on public.tool_loans(updated_by);
create index if not exists idx_tool_traceability_created_by on public.tool_traceability(created_by);
create index if not exists idx_tool_traceability_updated_by on public.tool_traceability(updated_by);

drop policy if exists "profiles_lider_update" on public.profiles;
drop policy if exists "profiles_update_own_preferences" on public.profiles;
create policy "profiles_update_lider_or_own_preferences"
on public.profiles
for update
to authenticated
using (
  app_private.has_role('lider')
  or auth_user_id = (select auth.uid())
)
with check (
  app_private.has_role('lider')
  or (
    auth_user_id = (select auth.uid())
    and role = app_private.current_user_role()
    and active = true
  )
);

drop policy if exists "tool_documents_manage_lider_admin" on public.tool_documents;
create policy "tool_documents_insert_lider_admin"
on public.tool_documents
for insert
to authenticated
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "tool_documents_update_lider_admin"
on public.tool_documents
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "tool_documents_delete_lider_admin"
on public.tool_documents
for delete
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "tool_loans_manage_lider_admin" on public.tool_loans;
create policy "tool_loans_insert_lider_admin"
on public.tool_loans
for insert
to authenticated
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "tool_loans_update_lider_admin"
on public.tool_loans
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "tool_loans_delete_lider_admin"
on public.tool_loans
for delete
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

drop policy if exists "tool_traceability_manage_lider_admin" on public.tool_traceability;
create policy "tool_traceability_insert_lider_admin"
on public.tool_traceability
for insert
to authenticated
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "tool_traceability_update_lider_admin"
on public.tool_traceability
for update
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]))
with check (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));

create policy "tool_traceability_delete_lider_admin"
on public.tool_traceability
for delete
to authenticated
using (app_private.has_any_role(array['lider', 'administrador']::public.app_role[]));
