import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/emotional_diary/emotional_diary_entry.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/widgets/bottom_sheets/check_in_diario_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Future<bool?>> openCheckInSheet(
    WidgetTester tester, {
    required EmotionalDiaryDataSource dataSource,
    Size size = const Size(500, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final completer = Completer<bool?>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  final result = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) =>
                        CheckInDiarioBottomSheet(repository: dataSource),
                  );
                  completer.complete(result);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return completer.future;
  }

  Future<void> submitCheckIn(WidgetTester tester) async {
    final confirm = find.byKey(const Key('check-in-submit'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
  }

  Finder inMoodGrid(String label) => find.descendant(
    of: find.byKey(const Key('check-in-mood-options')),
    matching: find.text(label),
  );

  Finder inFoodGrid(String label) => find.descendant(
    of: find.byKey(const Key('check-in-food-options')),
    matching: find.text(label),
  );

  testWidgets(
    'humor difícil não infere apoio ou abre checagem automaticamente',
    (tester) async {
      final dataSource = _EmotionalDataSource(record: null);
      final resultFuture = await openCheckInSheet(
        tester,
        dataSource: dataSource,
      );

      await tester.tap(inMoodGrid('Muito\ndifícil'));
      await tester.pumpAndSettle();
      await tester.tap(inFoodGrid('Muito\ndifícil'));
      await tester.pumpAndSettle();
      await submitCheckIn(tester);

      expect(dataSource.createCheckInCalls, 1);
      expect(find.byKey(const Key('check-in-support-dialog')), findsNothing);
      expect(find.text('Registro do dia salvo.'), findsOneWidget);
      expect(await resultFuture, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sintoma marcado não dispara uma sugestão automática', (
    tester,
  ) async {
    final dataSource = _EmotionalDataSource(record: null);
    await openCheckInSheet(tester, dataSource: dataSource);

    await tester.tap(inMoodGrid('Bem'));
    await tester.pumpAndSettle();
    await tester.tap(inFoodGrid('Tranquila'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('check-in-optional-details')));
    await tester.pumpAndSettle();
    final desmaio = find.text('Desmaio');
    await tester.ensureVisible(desmaio);
    await tester.tap(desmaio);
    await tester.pumpAndSettle();
    await submitCheckIn(tester);

    expect(find.byKey(const Key('check-in-support-dialog')), findsNothing);
    expect(dataSource.lastPhysicalSymptoms, contains('desmaio'));
  });

  testWidgets('check-in equilibrado não abre o diálogo de apoio', (
    tester,
  ) async {
    final dataSource = _EmotionalDataSource(record: null);
    final resultFuture = await openCheckInSheet(tester, dataSource: dataSource);

    await tester.tap(inMoodGrid('Bem'));
    await tester.pumpAndSettle();
    await tester.tap(inFoodGrid('Tranquila'));
    await tester.pumpAndSettle();
    await submitCheckIn(tester);

    expect(find.byKey(const Key('check-in-support-dialog')), findsNothing);
    expect(find.text('Registro do dia salvo.'), findsOneWidget);
    expect(await resultFuture, isTrue);
    expect(tester.takeException(), isNull);
  });
}

class _EmotionalDataSource implements EmotionalDiaryDataSource {
  _EmotionalDataSource({this.record});

  final Map<String, dynamic>? record;
  int createCheckInCalls = 0;
  List<String> lastPhysicalSymptoms = const [];

  @override
  Future<void> createCheckIn({
    required int comoSentiu,
    required int avaliacaoAlimentacao,
    required List<String> sintomasEmocionaisHoje,
    required List<String> sintomasFisicosHoje,
    String? humor,
  }) async {
    createCheckInCalls += 1;
    lastPhysicalSymptoms = sintomasFisicosHoje;
  }

  @override
  Future<void> createDiaryEntry({required String content}) async {}

  @override
  Future<void> clearDiaryEntry() async {}

  @override
  Future<Map<String, dynamic>?> getTodayRecord() async => record;

  @override
  Future<List<EmotionalDiaryEntry>> listCurrentUserEntries() async => [];
}
