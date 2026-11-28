-- املاک پناه — مهاجرت 011: حساب‌های جدید فقط با دعوت مدیر فعال می‌شوند.
ALTER TABLE public.profiles
  ALTER COLUMN is_active SET DEFAULT false;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, is_active)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data ->> 'full_name', ''),
    'consultant',
    false
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$function$;

-- کاربر غیرفعال فقط می‌تواند وضعیت حساب خودش را بخواند تا صفحه انتظار نمایش داده شود.
-- مدیر فعال همچنان می‌تواند همه پروفایل‌ها را مدیریت کند.
DROP POLICY IF EXISTS "profile read" ON public.profiles;
CREATE POLICY "profile read"
  ON public.profiles FOR SELECT TO authenticated
  USING (
    id = (SELECT auth.uid())
    OR (private.is_active_user() AND is_manager())
  );
