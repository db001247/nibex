-- nibex_clients: Client registry for NIBEX pseudonymisation architecture
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New query)
--
-- Security model:
--   nibex_sessions can be breached without re-identifying any client.
--   Only this table links client codes to real identities.
--   Never export, share, or include in AI calls.

CREATE TABLE IF NOT EXISTS public.nibex_clients (
  client_code              TEXT PRIMARY KEY,          -- NCX-YYYY-NNNNN
  business_name            TEXT NOT NULL,             -- real trading name as entered
  business_name_normalised TEXT NOT NULL,             -- lowercased, suffixes removed, for dedup
  registered_name          TEXT,                      -- CH registered name if different
  companies_house_number   TEXT,
  first_assessment_date    DATE NOT NULL DEFAULT CURRENT_DATE,
  last_assessment_date     DATE NOT NULL DEFAULT CURRENT_DATE,
  created_by               UUID REFERENCES auth.users(id),
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast normalised name lookup (deduplication)
CREATE INDEX IF NOT EXISTS idx_nibex_clients_normalised
  ON public.nibex_clients (business_name_normalised);

-- Index for CH number lookup
CREATE INDEX IF NOT EXISTS idx_nibex_clients_ch_number
  ON public.nibex_clients (companies_house_number)
  WHERE companies_house_number IS NOT NULL;

-- ── Row Level Security ─────────────────────────────────────────
ALTER TABLE public.nibex_clients ENABLE ROW LEVEL SECURITY;

-- Only authenticated users can read or write
-- In production restrict further to specific user IDs or a role
CREATE POLICY "Authenticated users can read clients"
  ON public.nibex_clients FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert clients"
  ON public.nibex_clients FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update clients"
  ON public.nibex_clients FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete clients"
  ON public.nibex_clients FOR DELETE
  USING (auth.role() = 'authenticated');

-- ── Verify ────────────────────────────────────────────────────
SELECT 'nibex_clients table created with RLS' AS status;
