import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/uno/models/uno_action.dart';
import 'package:kita_story/features/games/uno/models/uno_card.dart';
import 'package:kita_story/features/games/uno/models/uno_match_model.dart';

void main() {
  test('UnoMatchModel parses a public row and serializes the RPC patch', () {
    final match = UnoMatchModel.fromJson({
      'id': 'match-1',
      'host_id': 'host',
      'guest_id': 'guest',
      'status': 'in_progress',
      'phase': 'play_response',
      'current_actor_id': 'host',
      'host_card_count': 3,
      'guest_card_count': 5,
      'top_card': {
        'id': 'red-4-1',
        'color': 'red',
        'type': 'number',
        'number': 4,
      },
      'chosen_color': 'red',
      'deck_count': 90,
      'discard': [
        {'id': 'red-4-1', 'color': 'red', 'type': 'number', 'number': 4},
      ],
      'turn_cards': [],
      'pending_draw': 0,
      'pending_draw_target': null,
      'draw_response_started': false,
      'extra_turns': 0,
      'version': 7,
      'last_action': {'id': 'a1', 'type': 'play'},
      'winner_id': null,
      'uno_called_by': null,
      'created_at': '2026-11-10T10:00:00Z',
      'updated_at': '2026-11-10T10:01:00Z',
    });

    expect(match.status, UnoMatchStatus.inProgress);
    expect(match.phase, UnoPhase.playing);
    expect(match.topCard?.number, 4);
    expect(match.chosenColor, UnoColor.red);
    expect(match.version, 7);
    expect(match.discard.length, 1);

    final patch = match.toPublicPatch();
    expect(patch['phase'], 'playing');
    expect(patch['current_actor_id'], 'host');
    expect(patch['pending_draw_target'], isNull);
    expect(patch['status'], 'in_progress');
    expect(patch['top_card'], isA<Map<String, dynamic>>());
  });

  test('UnoAction round-trips card metadata', () {
    final action = UnoAction(
      id: 'a1',
      type: 'play',
      actorId: 'host',
      card: const UnoCard(
        id: 'blue-5-1',
        color: UnoColor.blue,
        type: UnoCardType.number,
        number: 5,
      ),
      createdAt: DateTime.utc(2026, 11, 10),
    );

    final parsed = UnoAction.fromJson(action.toJson());
    expect(parsed.type, 'play');
    expect(parsed.actorId, 'host');
    expect(parsed.card?.color, UnoColor.blue);
    expect(parsed.card?.number, 5);
  });
}
