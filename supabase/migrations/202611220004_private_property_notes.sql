-- Keep confidential office notes separate from shared property rows.
create table if not exists public.property_private_notes (
 property_id uuid primary key references public.properties(id) on delete cascade,
 note text not null default '',
 updated_at timestamptz not null default now()
);
alter table public.property_private_notes enable row level security;
create policy "private notes read" on public.property_private_notes for select to authenticated
using (exists(select 1 from public.properties p where p.id=property_private_notes.property_id and (p.owner_id=(select auth.uid()) or public.is_manager())));
create policy "private notes insert" on public.property_private_notes for insert to authenticated
with check (exists(select 1 from public.properties p where p.id=property_private_notes.property_id and (p.owner_id=(select auth.uid()) or public.is_manager())));
create policy "private notes update" on public.property_private_notes for update to authenticated
using (exists(select 1 from public.properties p where p.id=property_private_notes.property_id and (p.owner_id=(select auth.uid()) or public.is_manager())))
with check (exists(select 1 from public.properties p where p.id=property_private_notes.property_id and (p.owner_id=(select auth.uid()) or public.is_manager())));
create policy "private notes delete" on public.property_private_notes for delete to authenticated
using (exists(select 1 from public.properties p where p.id=property_private_notes.property_id and (p.owner_id=(select auth.uid()) or public.is_manager())));
