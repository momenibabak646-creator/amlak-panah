-- Base schema compatibility migration for the existing Amlak Panah project.
-- Ownership is represented by properties.owner_id; do not introduce a second user_id column.
create extension if not exists pgcrypto;

alter table public.properties
  add column if not exists owner_id uuid references auth.users(id) on delete cascade,
  add column if not exists title text,
  add column if not exists property_type text,
  add column if not exists deal_type text,
  add column if not exists city text,
  add column if not exists address text,
  add column if not exists neighborhood text,
  add column if not exists area numeric,
  add column if not exists price numeric,
  add column if not exists deposit numeric,
  add column if not exists monthly_rent numeric,
  add column if not exists phone text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create index if not exists properties_owner_id_idx on public.properties(owner_id);
alter table public.properties enable row level security;

alter table public.property_images
  add column if not exists property_id uuid references public.properties(id) on delete cascade,
  add column if not exists image_url text,
  add column if not exists created_at timestamptz default now();
alter table public.property_images enable row level security;

-- The existing property-images bucket stays private. Scoped Storage and row
-- policies are defined in 202611220002_secure_property_sharing_and_images.sql.
