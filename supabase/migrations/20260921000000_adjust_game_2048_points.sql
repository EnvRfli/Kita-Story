-- Migration: 20260921000000_adjust_game_2048_points.sql
-- Description: Adjusts 2048 gamification points (divided by 2) and recalibrates existing records in database

BEGIN;

-- 1. Hitung penyesuaian poin dan selisih pengurangan per user untuk game 2048
WITH adjustments AS (
  SELECT 
    id,
    user_id,
    points_earned AS old_points,
    -- Pembagian 2 dengan pembulatan ke atas (1.5 -> 2, 2.5 -> 3)
    CEIL(points_earned / 2.0)::INTEGER AS new_points,
    (points_earned - CEIL(points_earned / 2.0)::INTEGER) AS diff_points
  FROM public.user_point_logs
  WHERE activity_type IN ('play_2048', 'game_2048_milestone')
),
user_deductions AS (
  SELECT 
    user_id,
    SUM(diff_points) AS total_deduct
  FROM adjustments
  GROUP BY user_id
)
-- 2. Kurangi saldo app_users.points sesuai total selisih poin 2048 yang dipangkas
UPDATE public.app_users u
SET points = GREATEST(0, COALESCE(u.points, 0) - ud.total_deduct)
FROM user_deductions ud
WHERE u.id = ud.user_id;

-- 3. Perbarui riwayat log user_point_logs untuk game 2048
UPDATE public.user_point_logs
SET 
  points_earned = CEIL(points_earned / 2.0)::INTEGER,
  description = REGEXP_REPLACE(
    description, 
    '\(\+\d+ poin\)', 
    '(+' || CEIL(points_earned / 2.0)::INTEGER || ' poin)'
  )
WHERE activity_type IN ('play_2048', 'game_2048_milestone');

-- 4. Perbarui data pencapaian milestone di game_achievements (jika ada)
UPDATE public.game_achievements
SET points_awarded = CASE milestone
  WHEN 128 THEN 1
  WHEN 256 THEN 2
  WHEN 512 THEN 3
  WHEN 1024 THEN 5
  WHEN 2048 THEN 10
  WHEN 4096 THEN 15
  ELSE CASE
    WHEN milestone >= 8192 AND (milestone & (milestone - 1)) = 0 THEN 25
    ELSE CEIL(points_awarded / 2.0)::INTEGER
  END
END
WHERE game_type = '2048';

-- 5. Perbarui Stored Procedure RPC claim_2048_milestone dengan nilai poin baru
CREATE OR REPLACE FUNCTION public.claim_2048_milestone(p_milestone INTEGER)
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
    WHEN 128 THEN 1
    WHEN 256 THEN 2
    WHEN 512 THEN 3
    WHEN 1024 THEN 5
    WHEN 2048 THEN 10
    WHEN 4096 THEN 15
    ELSE CASE
      WHEN p_milestone >= 8192
        AND (p_milestone & (p_milestone - 1)) = 0 THEN 25
      ELSE NULL
    END
  END;

  IF v_points IS NULL THEN
    RAISE EXCEPTION 'Invalid 2048 milestone: %', p_milestone;
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
    v_points
  )
  ON CONFLICT (user_id, game_type, milestone) DO NOTHING
  RETURNING id INTO v_achievement_id;

  IF v_achievement_id IS NULL THEN
    RETURN FALSE;
  END IF;

  UPDATE app_users
  SET points = COALESCE(points, 0) + v_points
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
    v_points,
    v_achievement_id,
    now()
  );

  RETURN TRUE;
END;
$$;

COMMIT;
