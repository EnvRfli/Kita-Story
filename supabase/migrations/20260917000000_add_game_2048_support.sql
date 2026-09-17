ALTER TABLE game_history
  ADD COLUMN IF NOT EXISTS highest_tile INTEGER,
  ADD COLUMN IF NOT EXISTS moves_count INTEGER;

CREATE TABLE IF NOT EXISTS game_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  game_type TEXT NOT NULL,
  milestone INTEGER NOT NULL CHECK (milestone > 0),
  points_awarded INTEGER NOT NULL CHECK (points_awarded >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, game_type, milestone)
);

ALTER TABLE game_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own game achievements"
ON game_achievements FOR SELECT USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.claim_2048_milestone(
  p_milestone INTEGER,
  p_points INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_achievement_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_milestone <= 0 OR p_points < 0 THEN
    RAISE EXCEPTION 'Invalid 2048 milestone reward';
  END IF;

  INSERT INTO game_achievements (
    user_id,
    game_type,
    milestone,
    points_awarded
  )
  VALUES (
    v_user_id,
    '2048',
    p_milestone,
    p_points
  )
  ON CONFLICT (user_id, game_type, milestone) DO NOTHING
  RETURNING id INTO v_achievement_id;

  IF v_achievement_id IS NULL THEN
    RETURN FALSE;
  END IF;

  UPDATE app_users
  SET points = COALESCE(points, 0) + p_points
  WHERE id = v_user_id;

  INSERT INTO user_point_logs (
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
    'game_2048_milestone',
    'Milestone 2048 tercapai',
    format('Mencapai ubin %s di permainan 2048', p_milestone),
    p_points,
    v_achievement_id,
    now()
  );

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.claim_2048_milestone(INTEGER, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_2048_milestone(INTEGER, INTEGER) TO authenticated;
