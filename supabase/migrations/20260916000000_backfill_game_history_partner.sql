-- Make existing game results visible to the player's current partner through
-- the game_history RLS policy. New Sudoku results populate partner_id directly.
UPDATE game_history AS history
SET partner_id = users.partner_id
FROM app_users AS users
WHERE history.user_id = users.id
  AND history.partner_id IS NULL
  AND users.partner_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_game_history_partner_id
ON game_history(partner_id);
