-- UNO play & draw RPCs.

CREATE OR REPLACE FUNCTION uno_play_card(
    p_match_id UUID,
    p_expected_version BIGINT,
    p_card_id TEXT,
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
    v_hand JSONB;
    v_new_hand JSONB := '[]'::jsonb;
    v_card JSONB;
    v_elem JSONB;
    v_found BOOLEAN := FALSE;
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

    IF v_match.phase = 'draw_response' THEN
        IF v_match.pending_draw_target IS DISTINCT FROM v_uid THEN
            RAISE EXCEPTION 'not_your_response';
        END IF;
    ELSE
        IF v_match.current_actor_id IS DISTINCT FROM v_uid THEN
            RAISE EXCEPTION 'not_your_turn';
        END IF;
    END IF;

    SELECT cards INTO v_hand FROM uno_hands
    WHERE match_id = p_match_id AND user_id = v_uid FOR UPDATE;

    IF v_hand IS NULL THEN
        RAISE EXCEPTION 'hand_not_found';
    END IF;

    FOR v_elem IN SELECT value FROM jsonb_array_elements(v_hand) AS t(value) LOOP
        IF v_elem ->> 'id' = p_card_id THEN
            v_card := v_elem;
            v_found := TRUE;
        ELSE
            v_new_hand := v_new_hand || jsonb_build_array(v_elem);
        END IF;
    END LOOP;

    IF NOT v_found THEN
        RAISE EXCEPTION 'card_not_in_hand';
    END IF;

    IF v_match.phase = 'draw_response'
       AND COALESCE(v_card ->> 'type', '') NOT IN ('draw_one', 'draw_two') THEN
        RAISE EXCEPTION 'invalid_draw_response';
    END IF;

    UPDATE uno_hands
    SET cards = v_new_hand,
        card_count = jsonb_array_length(v_new_hand),
        updated_at = now()
    WHERE match_id = p_match_id AND user_id = v_uid;

    UPDATE uno_matches
    SET phase = COALESCE(p_public_state ->> 'phase', phase),
        current_actor_id = CASE
            WHEN p_public_state ? 'current_actor_id'
                THEN NULLIF(p_public_state ->> 'current_actor_id', '')::UUID
            ELSE current_actor_id
        END,
        host_card_count = CASE
            WHEN v_uid = v_match.host_id THEN jsonb_array_length(v_new_hand)
            ELSE host_card_count
        END,
        guest_card_count = CASE
            WHEN v_uid = v_match.guest_id THEN jsonb_array_length(v_new_hand)
            ELSE guest_card_count
        END,
        top_card = COALESCE(p_public_state -> 'top_card', top_card),
        chosen_color = CASE
            WHEN p_public_state ? 'chosen_color'
                THEN NULLIF(p_public_state ->> 'chosen_color', '')
            ELSE chosen_color
        END,
        deck_count = COALESCE((p_public_state ->> 'deck_count')::INT, deck_count),
        discard = COALESCE(p_public_state -> 'discard', discard),
        turn_cards = COALESCE(p_public_state -> 'turn_cards', turn_cards),
        pending_draw = COALESCE((p_public_state ->> 'pending_draw')::INT, pending_draw),
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
        uno_called_by = NULL,
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

    RETURN jsonb_build_object(
        'public_state', to_jsonb(v_match),
        'my_hand', v_new_hand
    );
END;
$$;

GRANT EXECUTE ON FUNCTION uno_play_card(UUID, BIGINT, TEXT, JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION uno_draw_cards(
    p_match_id UUID,
    p_expected_version BIGINT,
    p_count INT,
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
    v_deck JSONB;
    v_discard JSONB;
    v_hand JSONB;
    v_new_hand JSONB;
    v_drawn JSONB := '[]'::jsonb;
    v_card JSONB;
    v_top JSONB;
    v_i INT;
    v_to_draw INT;
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

    IF v_match.phase = 'draw_response' THEN
        IF v_match.pending_draw_target IS DISTINCT FROM v_uid THEN
            RAISE EXCEPTION 'not_your_response';
        END IF;
        IF p_count <> v_match.pending_draw THEN
            RAISE EXCEPTION 'invalid_penalty_count';
        END IF;
    ELSE
        IF v_match.current_actor_id IS DISTINCT FROM v_uid THEN
            RAISE EXCEPTION 'not_your_turn';
        END IF;
        IF p_count <> 1 THEN
            RAISE EXCEPTION 'invalid_draw_count';
        END IF;
    END IF;

    SELECT cards INTO v_deck FROM uno_decks
    WHERE match_id = p_match_id FOR UPDATE;

    SELECT cards INTO v_hand FROM uno_hands
    WHERE match_id = p_match_id AND user_id = v_uid FOR UPDATE;

    v_deck := COALESCE(v_deck, '[]'::jsonb);
    v_hand := COALESCE(v_hand, '[]'::jsonb);
    v_discard := COALESCE(v_match.discard, '[]'::jsonb);
    v_to_draw := LEAST(GREATEST(p_count, 0), jsonb_array_length(v_deck));

    IF v_to_draw < p_count AND jsonb_array_length(v_discard) > 1 THEN
        v_top := v_discard -> (jsonb_array_length(v_discard) - 1);
        v_deck := uno_shuffle_cards(
            v_deck || (v_discard - (jsonb_array_length(v_discard) - 1))
        );
        v_discard := jsonb_build_array(v_top);
        v_to_draw := LEAST(GREATEST(p_count, 0), jsonb_array_length(v_deck));
    END IF;

    FOR v_i IN 1..v_to_draw LOOP
        v_card := v_deck -> (jsonb_array_length(v_deck) - 1);
        v_deck := v_deck - (jsonb_array_length(v_deck) - 1);
        v_drawn := v_drawn || jsonb_build_array(v_card);
    END LOOP;

    v_new_hand := v_hand || v_drawn;

    UPDATE uno_hands
    SET cards = v_new_hand,
        card_count = jsonb_array_length(v_new_hand),
        updated_at = now()
    WHERE match_id = p_match_id AND user_id = v_uid;

    UPDATE uno_decks SET cards = v_deck, updated_at = now()
    WHERE match_id = p_match_id;

    UPDATE uno_matches
    SET phase = COALESCE(p_public_state ->> 'phase', phase),
        current_actor_id = CASE
            WHEN p_public_state ? 'current_actor_id'
                THEN NULLIF(p_public_state ->> 'current_actor_id', '')::UUID
            ELSE current_actor_id
        END,
        host_card_count = CASE
            WHEN v_uid = v_match.host_id THEN jsonb_array_length(v_new_hand)
            ELSE host_card_count
        END,
        guest_card_count = CASE
            WHEN v_uid = v_match.guest_id THEN jsonb_array_length(v_new_hand)
            ELSE guest_card_count
        END,
        deck_count = jsonb_array_length(v_deck),
        discard = v_discard,
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
        uno_called_by = NULL,
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

    RETURN jsonb_build_object(
        'public_state', to_jsonb(v_match),
        'my_hand', v_new_hand,
        'drawn_cards', v_drawn
    );
END;
$$;

GRANT EXECUTE ON FUNCTION uno_draw_cards(UUID, BIGINT, INT, JSONB) TO authenticated;
