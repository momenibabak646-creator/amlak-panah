-- The table already has a unique constraint on (property_id, user_id).
-- Remove the identical standalone index to avoid duplicate write overhead.
drop index if exists public.property_access_unique_pair_idx;
