-- Read-only security regression checks for Amlak Panah.
DO $$
BEGIN
  IF has_table_privilege('authenticated', 'public.properties', 'SELECT') THEN
    RAISE EXCEPTION 'authenticated must not have table-wide SELECT on properties';
  END IF;
  IF has_column_privilege('authenticated', 'public.properties', 'commission_amount', 'SELECT')
     OR has_column_privilege('authenticated', 'public.properties', 'consultant_share', 'SELECT')
     OR has_column_privilege('authenticated', 'public.properties', 'private_note', 'SELECT') THEN
    RAISE EXCEPTION 'sensitive legacy property columns remain readable';
  END IF;
  IF has_column_privilege('authenticated', 'public.properties', 'commission_amount', 'UPDATE')
     OR has_column_privilege('authenticated', 'public.properties', 'private_note', 'INSERT') THEN
    RAISE EXCEPTION 'sensitive legacy property columns remain writable';
  END IF;
  IF has_table_privilege('authenticated', 'public.properties', 'TRUNCATE')
     OR has_table_privilege('anon', 'public.properties', 'TRUNCATE') THEN
    RAISE EXCEPTION 'client roles must not have TRUNCATE on properties';
  END IF;
  IF NOT has_column_privilege('authenticated', 'public.properties', 'title', 'SELECT') THEN
    RAISE EXCEPTION 'safe property columns are not readable';
  END IF;
  IF NOT has_table_privilege('authenticated', 'public.property_access', 'SELECT')
     OR NOT has_table_privilege('authenticated', 'public.property_access', 'INSERT') THEN
    RAISE EXCEPTION 'property_access grants are missing';
  END IF;
  IF NOT has_table_privilege('authenticated', 'public.property_private_notes', 'SELECT')
     OR NOT has_table_privilege('authenticated', 'public.property_private_notes', 'INSERT') THEN
    RAISE EXCEPTION 'property_private_notes grants are missing';
  END IF;
  IF NOT has_table_privilege('authenticated', 'public.backup_restore_runs', 'SELECT')
     OR NOT has_table_privilege('authenticated', 'public.backup_restore_runs', 'INSERT') THEN
    RAISE EXCEPTION 'backup_restore_runs grants are missing';
  END IF;
  IF NOT has_table_privilege('authenticated', 'public.property_manager_financials', 'SELECT') THEN
    RAISE EXCEPTION 'manager financial table grant is missing';
  END IF;

  IF (SELECT column_default FROM information_schema.columns
      WHERE table_schema='public' AND table_name='profiles' AND column_name='is_active') <> 'false' THEN
    RAISE EXCEPTION 'new profile default must be inactive';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='profiles'
      AND policyname='profile read' AND cmd='SELECT'
      AND qual LIKE '%auth.uid%'
  ) THEN
    RAISE EXCEPTION 'profile self-read policy is missing';
  END IF;
END
$$;

SELECT
  has_table_privilege('authenticated', 'public.properties', 'SELECT') AS table_wide_property_select,
  has_column_privilege('authenticated', 'public.properties', 'title', 'SELECT') AS safe_title_select,
  has_column_privilege('authenticated', 'public.properties', 'commission_amount', 'SELECT') AS legacy_commission_select,
  has_column_privilege('authenticated', 'public.properties', 'private_note', 'SELECT') AS legacy_private_note_select,
  has_table_privilege('authenticated', 'public.properties', 'TRUNCATE') AS authenticated_truncate,
  has_table_privilege('anon', 'public.properties', 'TRUNCATE') AS anon_truncate;
