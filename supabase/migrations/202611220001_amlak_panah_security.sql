-- Supabase migration for Amlak Panah.
-- Existing tables and the private property-images bucket are reused.
create extension if not exists pgcrypto;

alter table public.properties
  add column if not exists id uuid default gen_random_uuid(),
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists title text,
  add column if not exists property_type text,
  add column if not exists address text,
  add column if not exists area numeric,
  add column if not exists price numeric,
  add column if not exists phone text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create unique index if not exists properties_id_uidx on public.properties(id);
create index if not exists properties_user_id_idx on public.properties(user_id);

alter table public.properties enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='properties' and policyname='Users read own properties') then
    create policy "Users read own properties" on public.properties for select to authenticated using (user_id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='properties' and policyname='Users insert own properties') then
    create policy "Users insert own properties" on public.properties for insert to authenticated with check (user_id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='properties' and policyname='Users update own properties') then
    create policy "Users update own properties" on public.properties for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='properties' and policyname='Users delete own properties') then
    create policy "Users delete own properties" on public.properties for delete to authenticated using (user_id = auth.uid());
  end if;
end $$;

-- The existing private bucket named property-images is intentionally not recreated.
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='Amlak users upload own property images') then
    create policy "Amlak users upload own property images" on storage.objects
      for insert to authenticated
      with check (bucket_id = 'property-images' and (storage.foldername(name))[1] = auth.uid()::text);
  end if;
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='Amlak users read own property images') then
    create policy "Amlak users read own property images" on storage.objects
      for select to authenticated
      using (bucket_id = 'property-images' and (storage.foldername(name))[1] = auth.uid()::text);
  end if;
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='Amlak users delete own property images') then
    create policy "Amlak users delete own property images" on storage.objects
      for delete to authenticated
      using (bucket_id = 'property-images' and (storage.foldername(name))[1] = auth.uid()::text);
  end if;
end $$;
