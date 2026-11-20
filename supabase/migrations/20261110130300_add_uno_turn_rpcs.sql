-- UNO end-turn, call UNO, catch UNO RPCs.

CREATE OR REPLACE FUNCTION uno_end_turn(
    p_match_id UUID,
    p_expected_version BIGINT,
    p_public_state JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_match uno_matches%ROWTYPE;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    SELECT * INTO v_match FROM uno_matches
    WHERE id = p_match_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'match_not_found';
    END IF;
    IF v_uid NOT IN (v_match.host_id, v_match.guest_id) THEN
        RAISE EXCEPTION 'not_participant';
    END IF;
    IF v_match.status <> 'in_progress' THEN
        RAISE EXCEPTION 'match_not_active';
    END IF;
    IF v_match.version <> p_expected_version THEN
        RAISE EXCEPTION 'version_conflict';
    END IF;
    IF v_match.current_actor_id IS DISTINCT FROM v_uid THEN
        RAISE EXCEPTION 'not_your_turn';
    END IF;

    UPDATE uno_matches
    SET phase = COALESCE(p_public_state ->> 'phase', phase),
        current_actor_id = CASE
            WHEN p_public_state ? 'current_actor_id'
                THEN NULLIF(p_public_state ->> 'current_actor_id', '')::UUID
            ELSE current_actor_id
        END,
        turn_cards = COALESCE(p_public_state -> 'turn_cards', turn_cards),
        pending_draw = CASE
            WHEN p_public_state ? 'pending_draw'
                THEN (p_public_state ->> 'pending_draw')::INT
            ELSE pending_draw
        END,
        pending_draw_target = CASE
            WHEN p_public_state ? 'pending_draw_target'
                THEN NULLIF(p_public_state ->> 'pending_draw_target', '')::UUID
            ELSE pending_draw_target
        END,
        draw_response_started = COALESCE(
            (p_public_state ->> 'draw_response_started')::BOOLEAN,
            draw_response_started
        ),
        extra_turns = COALESCE((p_public_state ->> 'extra_turns')::INT, extra_turns),
        uno_called_by = CASE
            WHEN p_public_state ? 'uno_called_by'
                THEN NULLIF(p_public_state ->> 'uno_called_by', '')::UUID
            ELSE uno_called_by
        END,
        last_action = COALESCE(p_public_state -> 'last_action', last_action),
        winner_id = CASE
            WHEN p_public_state ? 'winner_id'
                THEN NULLIF(p_public_state ->> 'winner_id', '')::UUID
            ELSE winner_id
        END,
        status = COALESCE(p_public_state ->> 'status', status),
        finished_at = CASE
            WHEN p_public_state ? 'finished_at'
                THEN NULLIF(p_public_state ->> 'finished_at', '')::TIMESTAMPTZ
            ELSE finished_at
        END,
        version = version + 1,
        updated_at = now()
    WHERE id = p_match_id
    RETURNING * INTO v_match;

    RETURN to_jsonb(v_match);
END;
$$;

GRANT EXECUTE ON FUNCTION uno_end_turn(UUID, BIGINT, JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION uno_call_uno(
    p_match_id UUID,
    p_expected_version BIGINT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_match uno_matches%ROWTYPE;
    v_count INT;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    SELECT * INTO v_match FROM uno_matches
    WHERE id = p_match_id AND (host_id = v_uid OR guest_id = v_uid)
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'match_not_found';
    END IF;
    IF v_match.status <> 'in_progress' THEN
        RAISE EXCEPTION 'match_not_active';
    END IF;
    IF v_match.version <> p_expected_version THEN
        RAISE EXCEPTION 'version_conflict';
    END IF;

    SELECT card_count INTO v_count FROM uno_hands
    WHERE match_id = p_match_id AND user_id = v_uid;

    IF COALESCE(v_count, 0) <> 1 THEN
        RAISE EXCEPTION 'uno_call_not_allowed';
    END IF;

    UPDATE uno_matches
    SET uno_called_by = v_uid,
        version = version + 1,
        last_action = jsonb_build_object(
            'type', 'uno_call', 'actor_id', v_uid, 'created_at', now()
        ),
        updated_at = now()
    WHERE id = p_match_id
    RETURNING * INTO v_match;

    RETURN to_jsonb(v_match);
END;
$$;

GRANT EXECUTE ON FUNCTION uno_call_uno(UUID, BIGINT) TO authenticated;

CREATE OR REPLACE FUNCTION uno_catch_uno(
    p_match_id UUID,
    p_expected_version BIGINT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_match uno_matches%ROWTYPE;
    v_target UUID;
    v_target_count INT;
    v_target_hand JSONB;
    v_deck JSONB;
    v_discard JSONB;
    v_new_hand JSONB;
    v_drawn JSONB := '[]'::jsonb;
    v_card JSONB;
    v_top JSONB;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    SELECT * INTO v_match FROM uno_matches
    WHERE id = p_match_id AND (host_id = v_uid OR guest_id = v_uid)
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'match_not_found';
    END IF;
    IF v_match.status <> 'in_progress' THEN
        RAISE EXCEPTION 'match_not_active';
    END IF;
    IF v_match.version <> p_expected_version THEN
        RAISE EXCEPTION 'version_conflict';
    END IF;

    v_target := CASE
        WHEN v_match.host_id = v_uid THEN v_match.guest_id
        ELSE v_match.host_id
    END;

    SELECT card_count, cards INTO v_target_count, v_target_hand
    FROM uno_hands
    WHERE match_id = p_match_id AND user_id = v_target
    FOR UPDATE;

    IF COALESCE(v_target_count, 0) <> 1 THEN
        RAISE EXCEPTION 'catch_not_allowed';
    END IF;
    IF v_match.uno_called_by IS NOT DISTINCT FROM v_target THEN
        RAISE EXCEPTION 'uno_already_called';
    END IF;

    SELECT cards INTO v_deck FROM uno_decks
    WHERE match_id = p_match_id FOR UPDATE;

    v_deck := COALESCE(v_deck, '[]'::jsonb);
    v_target_hand := COALESCE(v_target_hand, '[]'::jsonb);
    v_discard := COALESCE(v_match.discard, '[]'::jsonb);

    IF jsonb_array_length(v_deck) = 0 AND jsonb_array_length(v_discard) > 1 THEN
        v_top := v_discard -> (jsonb_array_length(v_discard) - 1);
        v_deck := uno_shuffle_cards(v_discard - (jsonb_array_length(v_discard) - 1));
        v_discard := jsonb_build_array(v_top);
    END IF;

    IF jsonb_array_length(v_deck) > 0 THEN
        v_card := v_deck -> (jsonb_array_length(v_deck) - 1);
        v_deck := v_deck - (jsonb_array_length(v_deck) - 1);
        v_drawn := jsonb_build_array(v_card);
    END IF;

    v_new_hand := v_target_hand || v_drawn;

    UPDATE uno_hands
    SET cards = v_new_hand,
        card_count = jsonb_array_length(v_new_hand),
        updated_at = now()
    WHERE match_id = p_match_id AND user_id = v_target;

    UPDATE uno_decks SET cards = v_deck, updated_at = now()
    WHERE match_id = p_match_id;

    UPDATE uno_matches
    SET host_card_count = CASE
            WHEN v_target = v_match.host_id THEN jsonb_array_length(v_new_hand)
            ELSE host_card_count
        END,
        guest_card_count = CASE
            WHEN v_target = v_match.guest_id THEN jsonb_array_length(v_new_hand)
            ELSE guest_card_count
        END,
        deck_count = jsonb_array_length(v_deck),
        discard = v_discard,
        uno_called_by = NULL,
        version = version + 1,
        last_action = jsonb_build_object(
            'id', gen_random_uuid()::text,
            'type', 'catch_uno',
            'actor_id', v_uid,
            'target_id', v_target,
            'created_at', now()
        ),
        updated_at = now()
    WHERE id = p_match_id
    RETURNING * INTO v_match;

    RETURN jsonb_build_object(
        'public_state', to_jsonb(v_match),
        'drawn_cards', v_drawn
    );
END;
$$;

GRANT EXECUTE ON FUNCTION uno_catch_uno(UUID, BIGINT) TO authenticated;
