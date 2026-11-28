-- املاک پناه — مهاجرت 010: حداقل‌سازی دسترسی API و جداسازی اطلاعات مالی مدیر
-- این مهاجرت داده‌های ملکی را حذف نمی‌کند. ستون‌های قدیمی مالی فقط از دسترس API کلاینت خارج می‌شوند.

DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT schemaname, tablename
    FROM pg_tables
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format(
      'REVOKE TRUNCATE, TRIGGER, REFERENCES ON TABLE %I.%I FROM anon, authenticated',
      r.schemaname, r.tablename
    );
  END LOOP;
END
$$;

CREATE TABLE IF NOT EXISTS public.property_manager_financials (
  property_id uuid PRIMARY KEY REFERENCES public.properties(id) ON DELETE CASCADE,
  commission_amount numeric,
  consultant_share numeric,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.property_manager_financials ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS manager_financials_select ON public.property_manager_financials;
CREATE POLICY manager_financials_select
  ON public.property_manager_financials FOR SELECT TO authenticated
  USING (private.is_active_user() AND private.is_manager());

DROP POLICY IF EXISTS manager_financials_insert ON public.property_manager_financials;
CREATE POLICY manager_financials_insert
  ON public.property_manager_financials FOR INSERT TO authenticated
  WITH CHECK (private.is_active_user() AND private.is_manager());

DROP POLICY IF EXISTS manager_financials_update ON public.property_manager_financials;
CREATE POLICY manager_financials_update
  ON public.property_manager_financials FOR UPDATE TO authenticated
  USING (private.is_active_user() AND private.is_manager())
  WITH CHECK (private.is_active_user() AND private.is_manager());

DROP POLICY IF EXISTS manager_financials_delete ON public.property_manager_financials;
CREATE POLICY manager_financials_delete
  ON public.property_manager_financials FOR DELETE TO authenticated
  USING (private.is_active_user() AND private.is_manager());

INSERT INTO public.property_private_notes AS existing (property_id, note, updated_at)
SELECT p.id, p.private_note, COALESCE(p.updated_at, now())
FROM public.properties p
WHERE p.private_note IS NOT NULL AND btrim(p.private_note) <> ''
ON CONFLICT (property_id) DO UPDATE
SET note = CASE
      WHEN existing.note IS NULL OR btrim(existing.note) = '' THEN EXCLUDED.note
      ELSE existing.note
    END,
    updated_at = GREATEST(existing.updated_at, EXCLUDED.updated_at);

INSERT INTO public.property_manager_financials AS existing
  (property_id, commission_amount, consultant_share, updated_at)
SELECT p.id, p.commission_amount, p.consultant_share, COALESCE(p.updated_at, now())
FROM public.properties p
WHERE p.commission_amount IS NOT NULL OR p.consultant_share IS NOT NULL
ON CONFLICT (property_id) DO UPDATE
SET commission_amount = COALESCE(existing.commission_amount, EXCLUDED.commission_amount),
    consultant_share = COALESCE(existing.consultant_share, EXCLUDED.consultant_share),
    updated_at = GREATEST(existing.updated_at, EXCLUDED.updated_at);

REVOKE ALL PRIVILEGES ON TABLE public.properties FROM anon, authenticated;

DO $$
DECLARE c record;
BEGIN
  FOR c IN
    SELECT attname
    FROM pg_attribute
    WHERE attrelid = 'public.properties'::regclass
      AND attnum > 0
      AND NOT attisdropped
  LOOP
    EXECUTE format(
      'REVOKE ALL PRIVILEGES (%I) ON TABLE public.properties FROM anon, authenticated',
      c.attname
    );
  END LOOP;
END
$$;

GRANT SELECT (
  id, owner_id, title, property_type, deal_type, city, address, area, price,
  deposit, monthly_rent, bedrooms, description, features, status, created_at,
  phone, seller_name, document_type, building_age, parking, elevator, storage,
  latitude, longitude, transaction_type, neighborhood, file_code, updated_at,
  sold_at, expires_at, negotiable, assigned_to
) ON TABLE public.properties TO authenticated;

GRANT INSERT (
  owner_id, assigned_to, title, property_type, deal_type, city, address, area,
  price, deposit, monthly_rent, bedrooms, description, features, status, phone,
  seller_name, document_type, building_age, parking, elevator, storage,
  latitude, longitude, transaction_type, neighborhood, file_code, updated_at,
  sold_at, expires_at, negotiable
) ON TABLE public.properties TO authenticated;

GRANT UPDATE (
  title, property_type, deal_type, city, address, area, price, deposit,
  monthly_rent, bedrooms, description, features, status, phone, seller_name,
  document_type, building_age, parking, elevator, storage, latitude, longitude,
  transaction_type, neighborhood, file_code, updated_at, sold_at, expires_at,
  negotiable
) ON TABLE public.properties TO authenticated;

GRANT DELETE ON TABLE public.properties TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.property_private_notes TO authenticated;

GRANT SELECT, INSERT, DELETE
  ON TABLE public.property_access TO authenticated;

GRANT SELECT, INSERT, UPDATE
  ON TABLE public.backup_restore_runs TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.property_manager_financials TO authenticated;

COMMENT ON TABLE public.property_manager_financials IS
  'اطلاعات کمیسیون و سهم مشاور؛ دسترسی فقط برای مدیر فعال از طریق RLS.';
