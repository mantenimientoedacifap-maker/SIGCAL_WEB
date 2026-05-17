-- SIGCAL - Fase 5 advisor fixes
-- Indexes for new catalog audit foreign keys reported by Supabase advisors.

create index if not exists idx_calibration_providers_updated_by
on public.calibration_providers(updated_by);

create index if not exists idx_workshops_updated_by
on public.workshops(updated_by);

create index if not exists idx_borrowers_updated_by
on public.borrowers(updated_by);
