-- Commission, negotiability, private note and assigned consultant fields.
alter table public.properties
  add column if not exists commission_amount numeric,
  add column if not exists consultant_share numeric,
  add column if not exists negotiable boolean not null default false,
  add column if not exists private_note text,
  add column if not exists assigned_to uuid references public.profiles(id) on delete set null;
create index if not exists properties_assigned_to_idx on public.properties(assigned_to);
