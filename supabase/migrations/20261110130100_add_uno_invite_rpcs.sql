-- UNO invite, state, pause, abandon, rematch RPCs.

CREATE OR REPLACE FUNCTION uno_create_invite(p_guest_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_active UUID;
    v_match uno_matches%ROWTYPE;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;
    IF v_uid = p_guest_id THEN
        RAISE EXCEPTION 'invalid_guest';
    END IF;

    SELECT id INTO v_active
    FROM uno_matches
    WHERE status IN ('in_progress', 'paused')
      AND ((host_id = v_uid AND guest_id = p_guest_id)
        OR (host_id = p_guest_id AND guest_id = v_uid))
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION 'active_match';
    END IF;

    PERFORM game_supersede_pending_invites(v_uid, p_guest_id);

    INSERT INTO uno_matches (host_id, guest_id, status, expires_at, version)
    VALUES (v_uid, p_guest_id, 'invited', now() + interval '5 minutes', 0)
    RETURNING * INTO v_match;

    RETURN to_jsonb(v_match);
END;
$$;

GRANT EXECUTE ON FUNCTION uno_create_invite(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION uno_accept_invite(p_match_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_match uno_matches%ROWTYPE;
    v_deck JSONB;
    v_host_hand JSONB := '[]'::jsonb;
    v_guest_hand JSONB := '[]'::jsonb;
    v_card JSONB;
    v_burn JSONB := '[]'::jsonb;
    v_starter JSONB;
    v_i INT;
    v_actor UUID;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    SELECT * INTO v_match
    FROM uno_matches
    WHERE id = p_match_id AND guest_id = v_uid
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'invite_not_found';
    END IF;
    IF v_match.status <> 'invited' THEN
        RAISE EXCEPTION 'invite_not_pending';
    END IF;
    IF v_match.expires_at IS NOT NULL AND v_match.expires_at < now() THEN
        UPDATE uno_matches SET status = 'expired', updated_at = now()
        WHERE id = p_match_id;
        RAISE EXCEPTION 'invite_expired';
    END IF;

    v_deck := uno_shuffle_cards(uno_build_deck());

    FOR v_i IN 1..7 LOOP
        v_card := v_deck -> (jsonb_array_length(v_deck) - 1);
        v_deck := v_deck - (jsonb_array_length(v_deck) - 1);
        v_host_hand := v_host_hand || jsonb_build_array(v_card);
    END LOOP;

    FOR v_i IN 1..7 LOOP
        v_card := v_deck -> (jsonb_array_length(v_deck) - 1);
        v_deck := v_deck - (jsonb_array_length(v_deck) - 1);
        v_guest_hand := v_guest_hand || jsonb_build_array(v_card);
    END LOOP;

    LOOP
        IF jsonb_array_length(v_deck) = 0 THEN
            IF jsonb_array_length(v_burn) = 0 THEN
                RAISE EXCEPTION 'deck_has_no_number_cards';
            END IF;
            v_deck := uno_shuffle_cards(v_burn);
            v_burn := '[]'::jsonb;
        END IF;
        v_card := v_deck -> (jsonb_array_length(v_deck) - 1);
        v_deck := v_deck - (jsonb_array_length(v_deck) - 1);
        IF v_card ->> 'type' = 'number' THEN
            v_starter := v_card;
            EXIT;
        END IF;
        v_burn := v_burn || jsonb_build_array(v_card);
    END LOOP;

    IF jsonb_array_length(v_burn) > 0 THEN
        v_deck := uno_shuffle_cards(v_deck || v_burn);
    END IF;

    v_actor := CASE WHEN random() < 0.5 THEN v_match.host_id ELSE v_match.guest_id END;

    INSERT INTO uno_hands (match_id, user_id, cards, card_count)
    VALUES
        (p_match_id, v_match.host_id, v_host_hand, jsonb_array_length(v_host_hand)),
        (p_match_id, v_match.guest_id, v_guest_hand, jsonb_array_length(v_guest_hand))
    ON CONFLICT (match_id, user_id) DO UPDATE
    SET cards = EXCLUDED.cards,
        card_count = EXCLUDED.card_count,
        updated_at = now();

    INSERT INTO uno_decks (match_id, cards, updated_at)
    VALUES (p_match_id, v_deck, now())
    ON CONFLICT (match_id) DO UPDATE
    SET cards = EXCLUDED.cards, updated_at = now();

    UPDATE uno_matches
    SET status = 'in_progress',
        phase = 'playing',
        current_actor_id = v_actor,
        host_card_count = jsonb_array_length(v_host_hand),
        guest_card_count = jsonb_array_length(v_guest_hand),
        top_card = v_starter,
        chosen_color = v_starter ->> 'color',
        deck_count = jsonb_array_length(v_deck),
        discard = jsonb_build_array(v_starter),
        turn_cards = '[]'::jsonb,
        pending_draw = 0,
        pending_draw_target = NULL,
        draw_response_started = FALSE,
        extra_turns = 0,
        uno_called_by = NULL,
        version = 1,
        last_action = jsonb_build_object(
            'type', 'deal', 'actor_id', v_uid, 'created_at', now()
        ),
        accepted_at = now(),
        started_at = now(),
        host_last_seen_at = now(),
        guest_last_seen_at = now(),
        updated_at = now()
    WHERE id = p_match_id
    RETURNING * INTO v_match;

    RETURN jsonb_build_object(
        'public_state', to_jsonb(v_match),
        'my_hand', v_guest_hand
    );
END;
$$;

GRANT EXECUTE ON FUNCTION uno_accept_invite(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION uno_get_state(p_match_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_match uno_matches%ROWTYPE;
    v_hand JSONB := '[]'::jsonb;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    SELECT * INTO v_match
    FROM uno_matches
    WHERE id = p_match_id AND (host_id = v_uid OR guest_id = v_uid);

    IF NOT FOUND THEN
        RAISE EXCEPTION 'match_not_found';
    END IF;

    SELECT cards INTO v_hand
    FROM uno_hands
    WHERE match_id = p_match_id AND user_id = v_uid;

    RETURN jsonb_build_object(
        'public_state', to_jsonb(v_match),
        'my_hand', COALESCE(v_hand, '[]'::jsonb)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION uno_get_state(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION uno_heartbeat(p_match_id UUID)
RETURNS VOID
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
    WHERE id = p_match_id AND (host_id = v_uid OR guest_id = v_uid);

    IF NOT FOUND THEN
        RAISE EXCEPTION 'match_not_found';
    END IF;

    UPDATE uno_matches
    SET host_last_seen_at = CASE WHEN host_id = v_uid THEN now() ELSE host_last_seen_at END,
        guest_last_seen_at = CASE WHEN guest_id = v_uid THEN now() ELSE guest_last_seen_at END
    WHERE id = p_match_id;
END;
$$;

GRANT EXECUTE ON FUNCTION uno_heartbeat(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION uno_pause(p_match_id UUID, p_action TEXT)
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
    WHERE id = p_match_id AND (host_id = v_uid OR guest_id = v_uid)
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'match_not_found';
    END IF;

    IF p_action = 'request' THEN
        IF v_match.status <> 'in_progress' THEN
            RAISE EXCEPTION 'cannot_pause';
        END IF;
        UPDATE uno_matches
        SET pause_requested_by = v_uid,
            resume_requested_by = NULL,
            version = version + 1,
            last_action = jsonb_build_object(
                'type', 'pause_request', 'actor_id', v_uid, 'created_at', now()
            )
        WHERE id = p_match_id RETURNING * INTO v_match;
    ELSIF p_action = 'approve' THEN
        IF v_match.pause_requested_by IS NULL OR v_match.pause_requested_by = v_uid THEN
            RAISE EXCEPTION 'not_pause_approver';
        END IF;
        UPDATE uno_matches
        SET status = 'paused',
            pause_requested_by = NULL,
            resume_requested_by = NULL,
            version = version + 1,
            last_action = jsonb_build_object(
                'type', 'pause_approve', 'actor_id', v_uid, 'created_at', now()
            )
        WHERE id = p_match_id RETURNING * INTO v_match;
    ELSIF p_action = 'reject' THEN
        IF v_match.pause_requested_by IS NULL OR v_match.pause_requested_by = v_uid THEN
            RAISE EXCEPTION 'not_pause_approver';
        END IF;
        UPDATE uno_matches
        SET pause_requested_by = NULL,
            version = version + 1,
            last_action = jsonb_build_object(
                'type', 'pause_reject', 'actor_id', v_uid, 'created_at', now()
            )
        WHERE id = p_match_id RETURNING * INTO v_match;
    ELSIF p_action = 'resume_request' THEN
        IF v_match.status <> 'paused' THEN
            RAISE EXCEPTION 'not_paused';
        END IF;
        UPDATE uno_matches
        SET resume_requested_by = v_uid,
            version = version + 1,
            last_action = jsonb_build_object(
                'type', 'resume_request', 'actor_id', v_uid, 'created_at', now()
            )
        WHERE id = p_match_id RETURNING * INTO v_match;
    ELSIF p_action = 'resume_approve' THEN
        IF v_match.status <> 'paused'
           OR v_match.resume_requested_by IS NULL
           OR v_match.resume_requested_by = v_uid THEN
            RAISE EXCEPTION 'not_resume_approver';
        END IF;
        UPDATE uno_matches
        SET status = 'in_progress',
            resume_requested_by = NULL,
            version = version + 1,
            last_action = jsonb_build_object(
                'type', 'resume_approve', 'actor_id', v_uid, 'created_at', now()
            )
        WHERE id = p_match_id RETURNING * INTO v_match;
    ELSIF p_action = 'resume_reject' THEN
        IF v_match.status <> 'paused'
           OR v_match.resume_requested_by IS NULL
           OR v_match.resume_requested_by = v_uid THEN
            RAISE EXCEPTION 'not_resume_approver';
        END IF;
        UPDATE uno_matches
        SET resume_requested_by = NULL,
            version = version + 1,
            last_action = jsonb_build_object(
                'type', 'resume_reject', 'actor_id', v_uid, 'created_at', now()
            )
        WHERE id = p_match_id RETURNING * INTO v_match;
    ELSE
        RAISE EXCEPTION 'invalid_pause_action';
    END IF;

    RETURN to_jsonb(v_match);
END;
$$;

GRANT EXECUTE ON FUNCTION uno_pause(UUID, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION uno_abandon(p_match_id UUID, p_reason TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_match uno_matches%ROWTYPE;
    v_winner UUID;
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
    IF v_match.status NOT IN ('in_progress', 'paused') THEN
        RAISE EXCEPTION 'match_not_active';
    END IF;

    IF p_reason = 'surrender' THEN
        v_winner := CASE WHEN v_match.host_id = v_uid THEN v_match.guest_id ELSE v_match.host_id END;
    ELSIF p_reason = 'timeout' THEN
        IF v_match.host_id = v_uid THEN
            IF v_match.guest_last_seen_at IS NULL
               OR v_match.guest_last_seen_at > now() - interval '5 minutes' THEN
                RAISE EXCEPTION 'opponent_still_active';
            END IF;
        ELSE
            IF v_match.host_last_seen_at IS NULL
               OR v_match.host_last_seen_at > now() - interval '5 minutes' THEN
                RAISE EXCEPTION 'opponent_still_active';
            END IF;
        END IF;
        v_winner := v_uid;
    ELSE
        RAISE EXCEPTION 'invalid_reason';
    END IF;

    UPDATE uno_matches
    SET status = 'abandoned',
        phase = 'game_over',
        winner_id = v_winner,
        abandon_reason = p_reason,
        finished_at = now(),
        version = version + 1,
        last_action = jsonb_build_object(
            'type', 'abandon', 'actor_id', v_uid, 'reason', p_reason, 'created_at', now()
        )
    WHERE id = p_match_id RETURNING * INTO v_match;

    RETURN to_jsonb(v_match);
END;
$$;

GRANT EXECUTE ON FUNCTION uno_abandon(UUID, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION uno_rematch(p_match_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_match uno_matches%ROWTYPE;
    v_other UUID;
    v_pending uno_matches%ROWTYPE;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    SELECT * INTO v_match FROM uno_matches
    WHERE id = p_match_id AND (host_id = v_uid OR guest_id = v_uid);

    IF NOT FOUND THEN
        RAISE EXCEPTION 'match_not_found';
    END IF;
    IF v_match.status NOT IN ('completed', 'abandoned') THEN
        RAISE EXCEPTION 'match_not_finished';
    END IF;

    v_other := CASE WHEN v_match.host_id = v_uid THEN v_match.guest_id ELSE v_match.host_id END;

    SELECT * INTO v_pending FROM uno_matches
    WHERE status = 'invited'
      AND expires_at > now()
      AND ((host_id = v_uid AND guest_id = v_other)
        OR (host_id = v_other AND guest_id = v_uid))
    ORDER BY created_at DESC
    LIMIT 1;

    IF FOUND THEN
        IF v_pending.guest_id = v_uid THEN
            RETURN uno_accept_invite(v_pending.id);
        END IF;
        RETURN jsonb_build_object(
            'public_state', to_jsonb(v_pending),
            'my_hand', '[]'::jsonb
        );
    END IF;

    RETURN jsonb_build_object(
        'public_state', uno_create_invite(v_other),
        'my_hand', '[]'::jsonb
    );
END;
$$;

GRANT EXECUTE ON FUNCTION uno_rematch(UUID) TO authenticated;
