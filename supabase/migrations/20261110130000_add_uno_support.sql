-- UNO Express support for Kita Story.
-- Public match state lives in uno_matches. Hands & deck order are private and
-- only accessible through SECURITY DEFINER RPCs.

CREATE TABLE IF NOT EXISTS uno_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    guest_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'invited',
    phase TEXT NOT NULL DEFAULT 'playing',
    current_actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    host_card_count INTEGER NOT NULL DEFAULT 0,
    guest_card_count INTEGER NOT NULL DEFAULT 0,
    top_card JSONB,
    chosen_color TEXT,
    deck_count INTEGER NOT NULL DEFAULT 0,
    discard JSONB NOT NULL DEFAULT '[]'::jsonb,
    turn_cards JSONB NOT NULL DEFAULT '[]'::jsonb,
    pending_draw INTEGER NOT NULL DEFAULT 0,
    pending_draw_target UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    draw_response_started BOOLEAN NOT NULL DEFAULT FALSE,
    extra_turns INTEGER NOT NULL DEFAULT 0,
    version BIGINT NOT NULL DEFAULT 0,
    last_action JSONB,
    winner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    uno_called_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    pause_requested_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    resume_requested_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    rematch_requested_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    abandon_reason TEXT,
    host_last_seen_at TIMESTAMPTZ,
    guest_last_seen_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (now() + interval '5 minutes'),
    accepted_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uno_matches_status_check CHECK (status IN (
        'invited', 'in_progress', 'paused', 'completed',
        'cancelled', 'expired', 'abandoned', 'rejected'
    )),
    CONSTRAINT uno_matches_phase_check CHECK (phase IN (
        'playing', 'draw_response', 'game_over'
    )),
    CONSTRAINT uno_matches_chosen_color_check CHECK (
        chosen_color IS NULL OR chosen_color IN ('red', 'yellow', 'green', 'blue')
    )
);

CREATE TABLE IF NOT EXISTS uno_hands (
    match_id UUID NOT NULL REFERENCES uno_matches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cards JSONB NOT NULL DEFAULT '[]'::jsonb,
    card_count INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (match_id, user_id)
);

CREATE TABLE IF NOT EXISTS uno_decks (
    match_id UUID PRIMARY KEY REFERENCES uno_matches(id) ON DELETE CASCADE,
    cards JSONB NOT NULL DEFAULT '[]'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_uno_matches_host_id ON uno_matches(host_id);
CREATE INDEX IF NOT EXISTS idx_uno_matches_guest_id ON uno_matches(guest_id);
CREATE INDEX IF NOT EXISTS idx_uno_matches_status ON uno_matches(status);
CREATE INDEX IF NOT EXISTS idx_uno_matches_guest_status
    ON uno_matches(guest_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_uno_matches_host_status
    ON uno_matches(host_id, status, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS uniq_uno_active_pair
ON uno_matches (
    LEAST(host_id::text, guest_id::text),
    GREATEST(host_id::text, guest_id::text)
)
WHERE status IN ('invited', 'in_progress', 'paused');

ALTER TABLE uno_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE uno_hands ENABLE ROW LEVEL SECURITY;
ALTER TABLE uno_decks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "uno participants can view matches" ON uno_matches;
CREATE POLICY "uno participants can view matches"
ON uno_matches FOR SELECT
USING (auth.uid() = host_id OR auth.uid() = guest_id);

DROP POLICY IF EXISTS "uno participants can update pending invites" ON uno_matches;
CREATE POLICY "uno participants can update pending invites"
ON uno_matches FOR UPDATE
USING (
    (auth.uid() = host_id OR auth.uid() = guest_id)
    AND status = 'invited'
)
WITH CHECK (status IN ('rejected', 'cancelled', 'expired'));

REVOKE ALL ON TABLE uno_hands FROM anon, authenticated;
REVOKE ALL ON TABLE uno_decks FROM anon, authenticated;

CREATE OR REPLACE FUNCTION set_uno_match_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_uno_matches_updated_at ON uno_matches;
CREATE TRIGGER trg_uno_matches_updated_at
BEFORE UPDATE ON uno_matches
FOR EACH ROW
EXECUTE FUNCTION set_uno_match_updated_at();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND tablename = 'uno_matches'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE uno_matches;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION uno_build_deck()
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_colors TEXT[] := ARRAY['red', 'yellow', 'green', 'blue'];
    v_color TEXT;
    v_num INT;
    v_i INT;
    v_cards JSONB := '[]'::jsonb;
BEGIN
    FOREACH v_color IN ARRAY v_colors LOOP
        v_cards := v_cards || jsonb_build_array(jsonb_build_object(
            'id', v_color || '-0-1', 'color', v_color, 'type', 'number', 'number', 0
        ));

        FOR v_num IN 1..3 LOOP
            FOR v_i IN 1..3 LOOP
                v_cards := v_cards || jsonb_build_array(jsonb_build_object(
                    'id', v_color || '-' || v_num || '-' || v_i,
                    'color', v_color, 'type', 'number', 'number', v_num
                ));
            END LOOP;
        END LOOP;

        FOR v_num IN 4..9 LOOP
            FOR v_i IN 1..2 LOOP
                v_cards := v_cards || jsonb_build_array(jsonb_build_object(
                    'id', v_color || '-' || v_num || '-' || v_i,
                    'color', v_color, 'type', 'number', 'number', v_num
                ));
            END LOOP;
        END LOOP;

        FOR v_i IN 1..2 LOOP
            v_cards := v_cards || jsonb_build_array(jsonb_build_object(
                'id', v_color || '-skip-' || v_i,
                'color', v_color, 'type', 'skip', 'number', NULL
            ));
            v_cards := v_cards || jsonb_build_array(jsonb_build_object(
                'id', v_color || '-reverse-' || v_i,
                'color', v_color, 'type', 'reverse', 'number', NULL
            ));
        END LOOP;

        v_cards := v_cards || jsonb_build_array(jsonb_build_object(
            'id', v_color || '-draw_one-1',
            'color', v_color, 'type', 'draw_one', 'number', NULL
        ));
    END LOOP;

    FOR v_i IN 1..4 LOOP
        v_cards := v_cards || jsonb_build_array(jsonb_build_object(
            'id', 'wild-' || v_i, 'color', NULL, 'type', 'wild', 'number', NULL
        ));
    END LOOP;

    FOR v_i IN 1..4 LOOP
        v_cards := v_cards || jsonb_build_array(jsonb_build_object(
            'id', 'draw_two-' || v_i, 'color', NULL, 'type', 'draw_two', 'number', NULL
        ));
    END LOOP;

    RETURN v_cards;
END;
$$;

CREATE OR REPLACE FUNCTION uno_shuffle_cards(p_cards JSONB)
RETURNS JSONB
LANGUAGE sql
AS $$
    SELECT COALESCE(jsonb_agg(elem ORDER BY random()), '[]'::jsonb)
    FROM jsonb_array_elements(COALESCE(p_cards, '[]'::jsonb)) AS elem;
$$;

REVOKE ALL ON FUNCTION uno_build_deck() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION uno_shuffle_cards(JSONB) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION game_supersede_pending_invites(
    p_user_a UUID,
    p_user_b UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL OR auth.uid() NOT IN (p_user_a, p_user_b) THEN
        RAISE EXCEPTION 'not_allowed';
    END IF;

    UPDATE uno_matches
    SET status = 'cancelled', abandon_reason = 'superseded', updated_at = now()
    WHERE status = 'invited'
      AND ((host_id = p_user_a AND guest_id = p_user_b)
        OR (host_id = p_user_b AND guest_id = p_user_a));

    UPDATE ludo_matches
    SET status = 'cancelled', abandon_reason = 'superseded', updated_at = now()
    WHERE status = 'invited'
      AND ((host_id = p_user_a AND guest_id = p_user_b)
        OR (host_id = p_user_b AND guest_id = p_user_a));
END;
$$;

GRANT EXECUTE ON FUNCTION game_supersede_pending_invites(UUID, UUID) TO authenticated;
