import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/games/uno/models/uno_card.dart';
import 'package:kita_story/features/games/uno/models/uno_match_model.dart';
import 'package:kita_story/features/games/uno/providers/uno_game_provider.dart';
import 'package:kita_story/features/games/uno/repositories/uno_repository.dart';
import 'package:kita_story/features/games/uno/services/uno_realtime_service.dart';
import 'package:kita_story/features/games/uno/services/uno_sound_service.dart';

class _FakeUnoRepository extends UnoRepository {
  _FakeUnoRepository(this.snapshot);

  UnoStateSnapshot snapshot;
  UnoStateSnapshot? playResult;
  UnoDrawResult? drawResult;
  UnoMatchModel? endTurnResult;

  @override
  Stream<UnoMatchModel> watchMatch(String matchId) => const Stream.empty();

  @override
  Future<UnoStateSnapshot> fetchState(String matchId) async => snapshot;

  @override
  Future<void> heartbeat(String matchId) async {}

  @override
  Future<UnoStateSnapshot> playCard({
    required String matchId,
    required int expectedVersion,
    required String cardId,
    required Map<String, dynamic> publicState,
  }) async {
    return playResult ?? snapshot;
  }

  @override
  Future<UnoDrawResult> drawCards({
    required String matchId,
    required int expectedVersion,
    required int count,
    required Map<String, dynamic> publicState,
  }) async {
    return drawResult!;
  }

  @override
  Future<UnoMatchModel> endTurn({
    required String matchId,
    required int expectedVersion,
    required Map<String, dynamic> publicState,
  }) async {
    return endTurnResult ?? snapshot.match;
  }

  @override
  Future<UnoMatchModel> pause({
    required String matchId,
    required String action,
  }) async {
    return snapshot.match;
  }

  @override
  Future<UnoMatchModel> abandon({
    required String matchId,
    required String reason,
  }) async {
    return snapshot.match;
  }

  @override
  Future<UnoStateSnapshot> rematch(String matchId) async => snapshot;

  @override
  Future<void> recordGameHistory({
    required String matchId,
    required String userId,
    required String? partnerId,
    required bool isWinner,
    required int durationSeconds,
    required int totalMoves,
  }) async {}
}

class _FakeUnoRealtimeService extends UnoRealtimeService {
  final _events = StreamController<UnoRealtimeEvent>.broadcast();
  final _presence = StreamController<Set<String>>.broadcast();

  @override
  Stream<UnoRealtimeEvent> get onEvent => _events.stream;

  @override
  Stream<Set<String>> get onPresence => _presence.stream;

  @override
  Future<void> connect(String matchId, {String? currentUserId}) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> broadcastReaction({
    required String emoji,
    required String senderId,
  }) async {}

  @override
  Future<void> broadcastSurrender({required String playerId}) async {}

  @override
  void dispose() {
    _events.close();
    _presence.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UnoCard number(String id, UnoColor color, int value) => UnoCard(
        id: id,
        color: color,
        type: UnoCardType.number,
        number: value,
      );

  UnoCard drawOne(String id, UnoColor color) => UnoCard(
        id: id,
        color: color,
        type: UnoCardType.drawOne,
      );

  UnoCard skipCard(String id, UnoColor color) => UnoCard(
        id: id,
        color: color,
        type: UnoCardType.skip,
      );

  UnoCard wildCard(String id) => UnoCard(
        id: id,
        type: UnoCardType.wild,
      );

  UnoMatchModel match({
    int version = 3,
    UnoPhase phase = UnoPhase.playing,
    String? currentActorId = 'me',
    int hostCardCount = 3,
    int guestCardCount = 3,
    UnoCard? topCard,
    UnoColor? chosenColor,
    List<UnoCard> turnCards = const [],
    int pendingDraw = 0,
    String? pendingDrawTarget,
    bool drawResponseStarted = false,
  }) {
    return UnoMatchModel(
      id: 'match-1',
      hostId: 'me',
      guestId: 'opp',
      status: UnoMatchStatus.inProgress,
      phase: phase,
      currentActorId: currentActorId,
      hostCardCount: hostCardCount,
      guestCardCount: guestCardCount,
      topCard: topCard,
      chosenColor: chosenColor,
      discard: topCard == null ? const [] : [topCard],
      turnCards: turnCards,
      pendingDraw: pendingDraw,
      pendingDrawTarget: pendingDrawTarget,
      drawResponseStarted: drawResponseStarted,
      version: version,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  test('provider hydrates from the accepted snapshot and plays a card', () async {
    final top = number('red-4-top', UnoColor.red, 4);
    final red5 = number('red-5', UnoColor.red, 5);
    final blue7 = number('blue-7', UnoColor.blue, 7);
    final firstSnapshot = UnoStateSnapshot(
      match: match(topCard: top, chosenColor: UnoColor.red),
      myHand: [red5, blue7],
    );
    final repo = _FakeUnoRepository(firstSnapshot);

    final provider = UnoGameProvider(
      repository: repo,
      realtime: _FakeUnoRealtimeService(),
      sound: UnoSoundService.forTesting(),
    );

    await provider.startOnlineGame(
      matchId: 'match-1',
      currentUserId: 'me',
      partnerId: 'opp',
      snapshot: firstSnapshot,
    );

    expect(provider.state?.myHand.length, 2);
    expect(provider.state?.isMyTurn, isTrue);
    expect(provider.canDrawOne, isTrue);

    repo.playResult = UnoStateSnapshot(
      match: match(
        version: 4,
        hostCardCount: 1,
        topCard: red5,
        chosenColor: UnoColor.red,
        turnCards: [red5],
      ),
      myHand: [blue7],
    );

    await provider.playCard(red5);

    expect(provider.state?.myHand.length, 1);
    expect(provider.state?.topCard?.id, 'red-5');
    expect(provider.movesCount, 1);

    provider.dispose();
  });

  test('provider accepts a draw penalty and appends the drawn cards', () async {
    final blueOne = drawOne('blue-one', UnoColor.blue);
    final blue7 = number('blue-7', UnoColor.blue, 7);
    final drawn = [
      number('green-1', UnoColor.green, 1),
      number('green-2', UnoColor.green, 2),
      number('green-3', UnoColor.green, 3),
      number('green-4', UnoColor.green, 4),
    ];
    final snapshot = UnoStateSnapshot(
      match: match(
        phase: UnoPhase.drawResponse,
        currentActorId: 'me',
        pendingDraw: 4,
        pendingDrawTarget: 'me',
        topCard: blueOne,
        chosenColor: UnoColor.blue,
        turnCards: [blueOne],
      ),
      myHand: [blue7],
    );
    final repo = _FakeUnoRepository(snapshot);

    final provider = UnoGameProvider(
      repository: repo,
      realtime: _FakeUnoRealtimeService(),
      sound: UnoSoundService.forTesting(),
    );

    await provider.startOnlineGame(
      matchId: 'match-1',
      currentUserId: 'me',
      partnerId: 'opp',
      snapshot: snapshot,
    );

    repo.drawResult = UnoDrawResult(
      snapshot: UnoStateSnapshot(
        match: match(
          version: 4,
          currentActorId: 'opp',
          hostCardCount: 5,
          topCard: blueOne,
          chosenColor: UnoColor.blue,
        ),
        myHand: [blue7, ...drawn],
      ),
      drawnCards: drawn,
    );

    await provider.acceptDrawPenalty();

    expect(provider.state?.myHand.length, 5);
    expect(provider.state?.match.phase, UnoPhase.playing);
    expect(provider.state?.match.currentActorId, 'opp');
    expect(provider.state?.match.pendingDraw, 0);

    provider.dispose();
  });

  test('provider can draw voluntarily even with playable cards', () async {
    final top = number('red-4-vol', UnoColor.red, 4);
    final red5 = number('red-5-vol', UnoColor.red, 5);
    final blue7 = number('blue-7-vol', UnoColor.blue, 7);
    final drawn = number('green-1-vol', UnoColor.green, 1);
    final snapshot = UnoStateSnapshot(
      match: match(topCard: top, chosenColor: UnoColor.red),
      myHand: [red5, blue7],
    );
    final repo = _FakeUnoRepository(snapshot);

    final provider = UnoGameProvider(
      repository: repo,
      realtime: _FakeUnoRealtimeService(),
      sound: UnoSoundService.forTesting(),
    );

    await provider.startOnlineGame(
      matchId: 'match-1',
      currentUserId: 'me',
      partnerId: 'opp',
      snapshot: snapshot,
    );

    expect(provider.canDrawOne, isTrue);

    repo.drawResult = UnoDrawResult(
      snapshot: UnoStateSnapshot(
        match: match(
          version: 4,
          currentActorId: 'opp',
          hostCardCount: 3,
          topCard: top,
          chosenColor: UnoColor.red,
        ),
        myHand: [red5, blue7, drawn],
      ),
      drawnCards: [drawn],
    );

    await provider.drawOne();

    expect(provider.state?.myHand.length, 3);
    expect(provider.state?.match.currentActorId, 'opp');
    expect(provider.state?.match.phase, UnoPhase.playing);

    provider.dispose();
  });

  test('displayHand sorts by color and can cycle to type', () async {
    final red9 = number('red-9-sort', UnoColor.red, 9);
    final redSkip = skipCard('red-skip-sort', UnoColor.red);
    final blue7 = number('blue-7-sort', UnoColor.blue, 7);
    final wild = wildCard('wild-sort');
    final snapshot = UnoStateSnapshot(
      match: match(
        topCard: number('top-sort', UnoColor.red, 4),
        chosenColor: UnoColor.red,
      ),
      myHand: [blue7, wild, redSkip, red9],
    );
    final repo = _FakeUnoRepository(snapshot);

    final provider = UnoGameProvider(
      repository: repo,
      realtime: _FakeUnoRealtimeService(),
      sound: UnoSoundService.forTesting(),
    );

    await provider.startOnlineGame(
      matchId: 'match-1',
      currentUserId: 'me',
      partnerId: 'opp',
      snapshot: snapshot,
    );

    expect(provider.handSortMode, UnoHandSortMode.color);
    var sorted = provider.displayHand;
    expect(sorted[0].id, 'red-9-sort');
    expect(sorted[1].id, 'red-skip-sort');
    expect(sorted[2].id, 'blue-7-sort');
    expect(sorted[3].id, 'wild-sort');

    provider.cycleHandSort();
    expect(provider.handSortMode, UnoHandSortMode.type);
    sorted = provider.displayHand;
    expect(sorted[0].id, 'blue-7-sort');
    expect(sorted[1].id, 'red-9-sort');
    expect(sorted[2].id, 'red-skip-sort');
    expect(sorted[3].id, 'wild-sort');

    provider.dispose();
  });
}
