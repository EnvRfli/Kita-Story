ALTER TABLE public.app_users
ADD COLUMN IF NOT EXISTS gender TEXT;

ALTER TABLE public.app_users
DROP CONSTRAINT IF EXISTS app_users_gender_check;

ALTER TABLE public.app_users
ADD CONSTRAINT app_users_gender_check
CHECK (gender IS NULL OR gender IN ('female', 'male'));

COMMENT ON COLUMN public.app_users.gender IS
'Optional user gender. Supported values: female, male; NULL means unspecified.';

-- Example for assigning a known gender to an existing account:
-- UPDATE public.app_users SET gender = 'female' WHERE id = '<user-uuid>';
