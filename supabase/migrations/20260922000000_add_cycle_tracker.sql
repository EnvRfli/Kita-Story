-- Cycle / menstrual tracker support.
-- Two tables: per-user cycle settings and per-day logs.
-- Female users own their data; their paired partner can read it.

CREATE TABLE IF NOT EXISTS public.cycle_settings (
  user_id UUID PRIMARY KEY REFERENCES public.app_users(id) ON DELETE CASCADE,
  cycle_length INT NOT NULL DEFAULT 28 CHECK (cycle_length BETWEEN 21 AND 45),
  period_length INT NOT NULL DEFAULT 5 CHECK (period_length BETWEEN 2 AND 10),
  last_period_start DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.cycle_day_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.app_users(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  flow TEXT NOT NULL DEFAULT 'none'
    CHECK (flow IN ('none', 'spotting', 'light', 'medium', 'heavy')),
  mood TEXT,
  symptoms TEXT[] NOT NULL DEFAULT '{}',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, log_date)
);

CREATE INDEX IF NOT EXISTS idx_cycle_day_logs_user_date
  ON public.cycle_day_logs (user_id, log_date DESC);

ALTER TABLE public.cycle_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cycle_day_logs ENABLE ROW LEVEL SECURITY;

-- cycle_settings policies
DROP POLICY IF EXISTS "Users can view own and partner cycle settings" ON public.cycle_settings;
CREATE POLICY "Users can view own and partner cycle settings"
ON public.cycle_settings FOR SELECT
USING (
  auth.uid() = user_id
  OR EXISTS (
    SELECT 1 FROM public.app_users
    WHERE app_users.id = auth.uid()
      AND app_users.partner_id = cycle_settings.user_id
  )
);

DROP POLICY IF EXISTS "Users can insert own cycle settings" ON public.cycle_settings;
CREATE POLICY "Users can insert own cycle settings"
ON public.cycle_settings FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own cycle settings" ON public.cycle_settings;
CREATE POLICY "Users can update own cycle settings"
ON public.cycle_settings FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- cycle_day_logs policies
DROP POLICY IF EXISTS "Users can view own and partner cycle logs" ON public.cycle_day_logs;
CREATE POLICY "Users can view own and partner cycle logs"
ON public.cycle_day_logs FOR SELECT
USING (
  auth.uid() = user_id
  OR EXISTS (
    SELECT 1 FROM public.app_users
    WHERE app_users.id = auth.uid()
      AND app_users.partner_id = cycle_day_logs.user_id
  )
);

DROP POLICY IF EXISTS "Users can insert own cycle logs" ON public.cycle_day_logs;
CREATE POLICY "Users can insert own cycle logs"
ON public.cycle_day_logs FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own cycle logs" ON public.cycle_day_logs;
CREATE POLICY "Users can update own cycle logs"
ON public.cycle_day_logs FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own cycle logs" ON public.cycle_day_logs;
CREATE POLICY "Users can delete own cycle logs"
ON public.cycle_day_logs FOR DELETE
USING (auth.uid() = user_id);

COMMENT ON TABLE public.cycle_settings IS
'Per-user menstrual cycle preferences. cycle_length and period_length are in days.';
COMMENT ON TABLE public.cycle_day_logs IS
'Daily menstrual logs: flow, mood, symptoms and notes. One row per user per date.';
