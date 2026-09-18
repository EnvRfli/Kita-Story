import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kita_story/features/history/models/activity_log_model.dart';
import 'package:kita_story/features/history/widgets/history_card.dart';

void main() {
  test('ActivityLogModel reads gender from the joined app_users profile', () {
    final log = ActivityLogModel.fromJson({
      'id': 'log-1',
      'user_id': 'user-1',
      'activity_type': 'add_note',
      'title': 'Membuat Catatan',
      'description': 'Catatan baru',
      'points_earned': 5,
      'created_at': '2026-09-16T10:00:00Z',
      'app_users': {
        'name': 'Nadia',
        'photo_url': null,
        'gender': 'female',
      },
    });

    expect(log.userGender, 'female');
  });

  testWidgets('HistoryCard uses the pink palette for a female user',
      (tester) async {
    final log = ActivityLogModel(
      id: 'log-1',
      userId: 'user-1',
      userName: 'Nadia',
      userGender: 'female',
      activityType: 'add_note',
      title: 'Membuat Catatan',
      description: 'Catatan baru',
      pointsEarned: 5,
      createdAt: DateTime(2026, 9, 16, 10),
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: HistoryCard(log: log))),
    );

    final nameText = tester.widget<Text>(find.text('Nadia'));
    final pill = tester.widget<Container>(
      find
          .ancestor(of: find.text('Nadia'), matching: find.byType(Container))
          .first,
    );
    final decoration = pill.decoration! as BoxDecoration;

    expect(nameText.style?.color, const Color(0xFFD81B60));
    expect(decoration.color, const Color(0xFFFFD6EC));
  });

  testWidgets('HistoryCard keeps the blue palette when gender is null',
      (tester) async {
    final log = ActivityLogModel(
      id: 'log-2',
      userId: 'user-2',
      userName: 'Alex',
      activityType: 'add_note',
      title: 'Membuat Catatan',
      description: 'Catatan baru',
      pointsEarned: 5,
      createdAt: DateTime(2026, 9, 16, 10),
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: HistoryCard(log: log))),
    );

    final nameText = tester.widget<Text>(find.text('Alex'));
    final pill = tester.widget<Container>(
      find
          .ancestor(of: find.text('Alex'), matching: find.byType(Container))
          .first,
    );
    final decoration = pill.decoration! as BoxDecoration;

    expect(nameText.style?.color, const Color(0xFF0288D1));
    expect(decoration.color, const Color(0xFFD0EBFF));
  });
}
