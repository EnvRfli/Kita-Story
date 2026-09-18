import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kita_story/features/games/sudoku/ui/sudoku_start_screen.dart';
import 'package:kita_story/features/games/sudoku/utils/sudoku_formatters.dart';

void main() {
  test('formats completed time without dropping remaining seconds', () {
    expect(formatSudokuDuration(201), '3 menit 21 detik');
    expect(formatSudokuDuration(3725), '1 jam 2 menit 5 detik');
  });

  testWidgets('uses the Sudoku artwork for the blurred hero and game icon',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/sudoku',
      routes: [
        GoRoute(
          path: '/sudoku',
          builder: (_, __) => const SudokuStartScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    final artworkFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'lib/assets/game screen/image 83.png',
    );

    expect(artworkFinder, findsNWidgets(2));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ImageFiltered,
      ),
      findsOneWidget,
    );
    expect(find.text('9'), findsNothing);
  });

  testWidgets('keeps the primary Sudoku actions visible on a phone viewport',
      (tester) async {
    tester.view.physicalSize = const Size(343, 775);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/sudoku',
      routes: [
        GoRoute(
          path: '/sudoku',
          builder: (_, __) => const SudokuStartScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('10–100 poin'), findsOneWidget);
    expect(find.text('Mudah'), findsOneWidget);
    expect(find.text('Sangat Susah'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Mulai'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
