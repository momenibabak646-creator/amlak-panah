-- Add indexes for foreign keys used by ownership, follow-up, sharing and image policies.
create index if not exists customers_owner_id_idx on public.customers(owner_id);
create index if not exists followups_owner_id_idx on public.followups(owner_id);
create index if not exists followups_customer_id_idx on public.followups(customer_id);
create index if not exists followups_property_id_idx on public.followups(property_id);
create index if not exists profiles_created_by_idx on public.profiles(created_by);
create index if not exists property_access_granted_by_idx on public.property_access(granted_by);
create index if not exists property_access_user_id_idx on public.property_access(user_id);
create index if not exists property_images_property_id_idx on public.property_images(property_id);
