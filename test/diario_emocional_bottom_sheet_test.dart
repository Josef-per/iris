import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/emotional_diary/emotional_diary_entry.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/widgets/bottom_sheets/diario_emocional_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Future<bool?>> openDiarySheet(
    WidgetTester tester, {
    required EmotionalDiaryDataSource dataSource,
    Size size = const Size(500, 1000),
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
                        DiarioEmocionalBottomSheet(repository: dataSource),
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

  testWidgets('não oferece limpar quando o diário de hoje está vazio', (
    tester,
  ) async {
    final dataSource = _EmotionalDataSource(
      record: {
        'como_sentiu': 3,
        'avaliacao_alimentacao': 3,
        'diario_emocional': '   ',
      },
    );
    await openDiarySheet(tester, dataSource: dataSource);

    expect(find.byKey(const Key('emotional-diary-field')), findsOneWidget);
    expect(find.byKey(const Key('emotional-diary-clear')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('limpa o diário de hoje após confirmação e fecha com sucesso', (
    tester,
  ) async {
    final dataSource = _EmotionalDataSource(
      record: {'diario_emocional': 'Dia difícil, mas resisti aos impulsos.'},
    );
    final resultFuture = await openDiarySheet(tester, dataSource: dataSource);

    expect(find.byKey(const Key('emotional-diary-clear')), findsOneWidget);
    expect(find.text('Dia difícil, mas resisti aos impulsos.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('emotional-diary-clear')));
    await tester.pumpAndSettle();

    expect(find.text('Limpar diário de hoje?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Limpar'));
    await tester.pumpAndSettle();

    expect(dataSource.clearCalls, 1);
    expect(find.text('Diário emocional limpo.'), findsOneWidget);
    expect(await resultFuture, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar a confirmação não limpa nada', (tester) async {
    final dataSource = _EmotionalDataSource(
      record: {'diario_emocional': 'Texto que deve permanecer.'},
    );
    await openDiarySheet(tester, dataSource: dataSource);

    await tester.tap(find.byKey(const Key('emotional-diary-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(dataSource.clearCalls, 0);
    expect(find.text('Texto que deve permanecer.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha ao limpar informa o erro e mantém o texto', (
    tester,
  ) async {
    final dataSource = _EmotionalDataSource(
      record: {'diario_emocional': 'Texto salvo.'},
      clearError: Exception('falha'),
    );
    await openDiarySheet(tester, dataSource: dataSource);

    await tester.tap(find.byKey(const Key('emotional-diary-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Limpar'));
    await tester.pumpAndSettle();

    expect(find.text('Algo deu errado. Tente novamente.'), findsOneWidget);
    expect(find.text('Texto salvo.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _EmotionalDataSource implements EmotionalDiaryDataSource {
  _EmotionalDataSource({this.record, this.clearError});

  final Map<String, dynamic>? record;
  final Object? clearError;
  int clearCalls = 0;

  @override
  Future<void> clearDiaryEntry() async {
    clearCalls += 1;
    if (clearError != null) {
      throw clearError!;
    }
  }

  @override
  Future<void> createCheckIn({
    required int comoSentiu,
    required int avaliacaoAlimentacao,
    required List<String> sintomasEmocionaisHoje,
    required List<String> sintomasFisicosHoje,
    String? humor,
  }) async {}

  @override
  Future<void> createDiaryEntry({required String content}) async {}

  @override
  Future<Map<String, dynamic>?> getTodayRecord() async => record;

  @override
  Future<List<EmotionalDiaryEntry>> listCurrentUserEntries() async => [];
}
