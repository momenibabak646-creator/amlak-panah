-- Secure property sharing and private image access for Amlak Panah.
begin;
alter table public.property_access enable row level security;
drop policy if exists "property access read" on public.property_access;
drop policy if exists "property access insert" on public.property_access;
drop policy if exists "property access delete" on public.property_access;
create policy "property access read" on public.property_access for select to authenticated
using (user_id=(select auth.uid()) or granted_by=(select auth.uid()) or exists(select 1 from public.properties p where p.id=property_access.property_id and (p.owner_id=(select auth.uid()) or public.is_manager())));
create policy "property access insert" on public.property_access for insert to authenticated
with check (granted_by=(select auth.uid()) and exists(select 1 from public.properties p where p.id=property_access.property_id and (p.owner_id=(select auth.uid()) or public.is_manager())));
create policy "property access delete" on public.property_access for delete to authenticated
using (exists(select 1 from public.properties p where p.id=property_access.property_id and (p.owner_id=(select auth.uid()) or public.is_manager())));
drop policy if exists "property read" on public.properties;
create policy "property read" on public.properties for select to authenticated
using (owner_id=(select auth.uid()) or public.is_manager() or public.can_view_all_properties() or exists(select 1 from public.property_access a where a.property_id=properties.id and a.user_id=(select auth.uid())));
drop policy if exists "View property images" on public.property_images;
drop policy if exists "property images read" on public.property_images;
drop policy if exists "Add property images" on public.property_images;
drop policy if exists "property images insert" on public.property_images;
create policy "property images read" on public.property_images for select to authenticated
using (exists(select 1 from public.properties p where p.id=property_images.property_id and (p.owner_id=(select auth.uid()) or public.is_manager() or public.can_view_all_properties() or exists(select 1 from public.property_access a where a.property_id=p.id and a.user_id=(select auth.uid())))));
create policy "property images insert" on public.property_images for insert to authenticated
with check (exists(select 1 from public.properties p where p.id=property_images.property_id and (p.owner_id=(select auth.uid()) or public.is_manager())));
drop policy if exists "Authenticated users can view property images" on storage.objects;
drop policy if exists "Authenticated users can upload property images" on storage.objects;
drop policy if exists "Authenticated users can delete property images" on storage.objects;
drop policy if exists "panah_view_property_images" on storage.objects;
create policy "panah_view_property_images" on storage.objects for select to authenticated
using (bucket_id='property-images' and exists(select 1 from public.property_images pi join public.properties p on p.id=pi.property_id where pi.image_url=storage.objects.name and (p.owner_id=(select auth.uid()) or public.is_manager() or public.can_view_all_properties() or exists(select 1 from public.property_access a where a.property_id=p.id and a.user_id=(select auth.uid())))));
create index if not exists property_access_property_id_idx on public.property_access(property_id);
create index if not exists property_access_user_id_idx on public.property_access(user_id);
create index if not exists property_images_property_id_idx on public.property_images(property_id);
create index if not exists customers_owner_id_idx on public.customers(owner_id);
create index if not exists followups_owner_id_idx on public.followups(owner_id);
create index if not exists followups_customer_id_idx on public.followups(customer_id);
create index if not exists followups_property_id_idx on public.followups(property_id);
create index if not exists profiles_created_by_idx on public.profiles(created_by);
alter function public.generate_property_code() set search_path='';
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.can_view_all_properties() from anon;
revoke all on function public.is_manager() from anon;
commit;
