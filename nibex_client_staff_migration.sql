-- ============================================================
-- NIBEX: Client Staff Registry
-- ============================================================
-- Purpose: enumerable, known set of a client business's own staff,
-- each given a permanent pseudonymous code. This is the foundation
-- for scrubbing real names out of free-text notes before anything
-- reaches a third-party AI call.
--
-- Run this in Supabase: Table Editor -> SQL Editor -> paste and run.
-- ============================================================

create table if not exists nibex_client_staff (
  id uuid primary key default gen_random_uuid(),
  client_code text not null references nibex_clients(client_code) on delete cascade,
  staff_code text not null unique,
  full_name text not null,
  role_title text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_client_staff_client_code on nibex_client_staff(client_code);
create index if not exists idx_client_staff_full_name on nibex_client_staff(full_name);

-- Row Level Security — mirror whatever pattern nibex_clients already uses.
-- This is a reasonable default (authenticated users can read/write);
-- adjust to match your existing nibex_clients policies exactly if they differ.
alter table nibex_client_staff enable row level security;

create policy "Authenticated users can view client staff"
  on nibex_client_staff for select
  to authenticated
  using (true);

create policy "Authenticated users can insert client staff"
  on nibex_client_staff for insert
  to authenticated
  with check (true);

create policy "Authenticated users can update client staff"
  on nibex_client_staff for update
  to authenticated
  using (true);

create policy "Authenticated users can delete client staff"
  on nibex_client_staff for delete
  to authenticated
  using (true);

-- Keep updated_at current on edit
create or replace function update_client_staff_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_client_staff_updated_at
  before update on nibex_client_staff
  for each row
  execute function update_client_staff_updated_at();
