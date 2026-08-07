-- ============================================================
-- NIBEX: Report Snapshots (locked, permanent records)
-- ============================================================
-- Purpose: once a report is generated, it becomes a fixed, dated record
-- that never changes — even if the underlying session is edited later.
-- The live session stays fully editable; only generated reports are locked.
--
-- Run this in Supabase: SQL Editor -> paste and run.
-- ============================================================

create table if not exists nibex_reports (
  id uuid primary key default gen_random_uuid(),
  session_id text not null,
  client_code text,
  business_name text not null,
  tier text not null,
  generated_at timestamptz not null default now(),
  snapshot jsonb not null
);

create index if not exists idx_reports_session_id on nibex_reports(session_id);
create index if not exists idx_reports_client_code on nibex_reports(client_code);

alter table nibex_reports enable row level security;

create policy "Authenticated users can view reports"
  on nibex_reports for select
  to authenticated
  using (true);

create policy "Authenticated users can create reports"
  on nibex_reports for insert
  to authenticated
  with check (true);

-- Deliberately no UPDATE or DELETE policy — a locked report should not
-- normally be editable or removable through the app. If a correction is
-- ever genuinely needed, that should be a rare, manual database action,
-- not something the app itself can do casually.

-- Grants — required in addition to the RLS policies above (see the pattern
-- already hit three times today with nibex_clients, nibex_client_staff,
-- and nibex_sessions — RLS alone is not enough, the role needs the grant too)
GRANT SELECT, INSERT ON public.nibex_reports TO authenticated;
