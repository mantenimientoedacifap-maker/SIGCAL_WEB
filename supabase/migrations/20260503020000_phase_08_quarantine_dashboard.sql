-- SIGCAL - Fase 8
-- Cuarentena operativa para herramientas vencidas o no recuperables.

alter table public.tools
  add column if not exists quarantine_reason text,
  add column if not exists quarantine_notes text,
  add column if not exists quarantine_marked_at timestamptz;

alter table public.tools
  drop constraint if exists tools_quarantine_reason_check;

alter table public.tools
  add constraint tools_quarantine_reason_check
  check (
    quarantine_reason is null
    or quarantine_reason in (
      'IRREPARABLE',
      'INOPERATIVA',
      'NO_CALIBRABLE',
      'NO_CONFORME'
    )
  );

create index if not exists idx_tools_quarantine_reason
on public.tools(quarantine_reason)
where quarantine_reason is not null;

create index if not exists idx_tools_quarantine_marked_at
on public.tools(quarantine_marked_at)
where quarantine_marked_at is not null;
