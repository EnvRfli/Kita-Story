-- Tetris support: result metadata and one-time line achievements.
-- This migration is self-contained so it also works on environments where the
-- 2048 achievement migration has not been applied yet.

ALTER TABLE public.game_history
  ADD COLUMN IF NOT EXISTS lines_cleared INTEGER,
  ADD COLUMN IF NOT EXISTS level_reached INTEGER;

CREATE INDEX IF NOT EXISTS idx_game_history_tetris_score
ON public.game_history (score DESC)
WHERE game_type = 'tetris';

CREATE TABLE IF NOT EXISTS public.game_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  game_type TEXT NOT NULL,
  milestone INTEGER NOT NULL CHECK (milestone > 0),
  points_awarded INTEGER NOT NULL CHECK (points_awarded >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, game_type, milestone)
);

ALTER TABLE public.game_achievements ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'game_achievements'
      AND policyname = 'Users can view own game achievements'
  ) THEN
    EXECUTE 'CREATE POLICY "Users can view own game achievements" '
      'ON public.game_achievements FOR SELECT '
      'USING (auth.uid() = user_id)';
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.claim_tetris_milestone(p_milestone INTEGER)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_achievement_id UUID;
  v_points INTEGER;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  v_points := CASE p_milestone
    WHEN 10 THEN 2
    WHEN 25 THEN 3
    WHEN 50 THEN 5
    WHEN 100 THEN 10
    WHEN 150 THEN 15
    WHEN 200 THEN 15
    ELSE NULL
  END;

  IF v_points IS NULL THEN
    RAISE EXCEPTION 'Invalid Tetris milestone: %', p_milestone;
  END IF;

  INSERT INTO public.game_achievements (
    user_id,
    game_type,
    milestone,
    points_awarded
  )
  VALUES (
    v_user_id,
    'tetris',
    p_milestone,
    v_points
  )
  ON CONFLICT (user_id, game_type, milestone) DO NOTHING
  RETURNING id INTO v_achievement_id;

  IF v_achievement_id IS NULL THEN
    RETURN FALSE;
  END IF;

  UPDATE public.app_users
  SET points = COALESCE(points, 0) + v_points
  WHERE id = v_user_id;

  INSERT INTO public.user_point_logs (
    user_id,
    activity_type,
    title,
    description,
    points_earned,
    reference_id,
    created_at
  )
  VALUES (
    v_user_id,
    'game_tetris_milestone',
    format('Achievement Tetris %s Garis 🧩', p_milestone),
    format('Berhasil menghapus %s garis di Tetris (+%s poin)', p_milestone, v_points),
    v_points,
    v_achievement_id,
    now()
  );

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.claim_tetris_milestone(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_tetris_milestone(INTEGER) TO authenticated;
