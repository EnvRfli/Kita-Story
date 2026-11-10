-- Ludo couple realtime improvements:
-- - game versioning for optimistic concurrency
-- - last action metadata for client-side step animation
-- - invite expiry and richer lifecycle statuses
-- - idempotent game history per user + match

ALTER TABLE ludo_matches
    ADD COLUMN IF NOT EXISTS game_version BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_action JSONB,
    ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ DEFAULT (now() + interval '5 minutes'),
    ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS finished_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS abandon_reason TEXT;

-- Backfill expiry for old pending invites.
UPDATE ludo_matches
SET expires_at = created_at + interval '5 minutes'
WHERE expires_at IS NULL;

-- Refresh status constraint with the complete lifecycle.
ALTER TABLE ludo_matches DROP CONSTRAINT IF EXISTS ludo_matches_status_check;
ALTER TABLE ludo_matches
    ADD CONSTRAINT ludo_matches_status_check
    CHECK (status IN (
        'invited',
        'accepted',
        'in_progress',
        'completed',
        'rejected',
        'cancelled',
        'expired',
        'abandoned'
    ));

-- Keep updated_at accurate for every write.
CREATE OR REPLACE FUNCTION set_ludo_match_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_ludo_matches_updated_at ON ludo_matches;
CREATE TRIGGER trg_ludo_matches_updated_at
BEFORE UPDATE ON ludo_matches
FOR EACH ROW
EXECUTE FUNCTION set_ludo_match_updated_at();

-- Clean stale duplicate active rows before enforcing the pair uniqueness.
WITH ranked AS (
    SELECT id,
           status,
           ROW_NUMBER() OVER (
               PARTITION BY LEAST(host_id::text, guest_id::text),
                            GREATEST(host_id::text, guest_id::text)
               ORDER BY
                   CASE WHEN status IN ('accepted', 'in_progress') THEN 0 ELSE 1 END,
                   created_at DESC
           ) AS rn
    FROM ludo_matches
    WHERE status IN ('invited', 'accepted', 'in_progress')
)
UPDATE ludo_matches
SET status = CASE WHEN status = 'invited' THEN 'cancelled' ELSE 'abandoned' END,
    abandon_reason = 'duplicate_cleanup',
    updated_at = now()
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- Only one active match per couple pair. LEAST/GREATEST makes the pair order-independent.
CREATE UNIQUE INDEX IF NOT EXISTS uniq_ludo_active_pair
ON ludo_matches (
    LEAST(host_id::text, guest_id::text),
    GREATEST(host_id::text, guest_id::text)
)
WHERE status IN ('invited', 'accepted', 'in_progress');

-- Helpful indexes for invite lookups.
CREATE INDEX IF NOT EXISTS idx_ludo_matches_guest_status
ON ludo_matches(guest_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ludo_matches_host_status
ON ludo_matches(host_id, status, created_at DESC);

-- Keep the realtime publication in sync.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND tablename = 'ludo_matches'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE ludo_matches;
  END IF;
END $$;

-- Game history: allow one row per user per match so both players are recorded.
ALTER TABLE game_history
    ADD COLUMN IF NOT EXISTS match_id UUID;

UPDATE game_history
SET match_id = id
WHERE game_type = 'ludo' AND match_id IS NULL;

-- Remove accidental duplicates before enforcing idempotency.
DELETE FROM game_history a
USING game_history b
WHERE a.ctid < b.ctid
  AND a.user_id = b.user_id
  AND a.match_id = b.match_id
  AND a.match_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_game_history_user_match
ON game_history(user_id, match_id)
WHERE match_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_game_history_match_id
ON game_history(match_id);
