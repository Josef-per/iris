import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/emotional_diary/emotional_diary_entry.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/features/emotional_diary/emotional_diary_support_topics.dart';
import 'package:iris/widgets/bottom_sheets/diario_emocional_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Future<bool?>> openDiarySheet(
    WidgetTester tester, {
    required EmotionalDiaryDataSource dataSource,
    EmotionalDiarySupportTopicDataSource? supportTopics,
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
                    builder: (_) => DiarioEmocionalBottomSheet(
                      repository: dataSource,
                      supportTopics: supportTopics,
                    ),
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

  testWidgets('salva até dois tópicos escolhidos pelo paciente', (
    tester,
  ) async {
    final dataSource = _EmotionalDataSource(
      record: {
        'id': 'daily-record-id',
        'diario_emocional': 'Hoje foi um dia intenso.',
      },
    );
    final topics = _SupportTopicDataSource(
      initial: const <String>{EmotionalDiarySupportTopic.overload},
    );
    final resultFuture = await openDiarySheet(
      tester,
      dataSource: dataSource,
      supportTopics: topics,
    );

    expect(find.text('O que mais marcou hoje? (opcional)'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const Key('emotional-diary-topic-overload')),
          )
          .selected,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('emotional-diary-topic-loneliness')));
    await tester.pump();

    final thirdChoice = tester.widget<ChoiceChip>(
      find.byKey(const Key('emotional-diary-topic-self_kindness')),
    );
    expect(thirdChoice.onSelected, isNull);

    await tester.tap(find.byKey(const Key('emotional-diary-topic-overload')));
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('emotional-diary-topic-self_kindness')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('emotional-diary-submit')));
    await tester.pumpAndSettle();

    expect(dataSource.savedContent, 'Hoje foi um dia intenso.');
    expect(topics.savedRecordId, 'daily-record-id');
    expect(topics.savedCodes, <String>{
      EmotionalDiarySupportTopic.loneliness,
      EmotionalDiarySupportTopic.selfKindness,
    });
    expect(await resultFuture, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('não bloqueia o diário quando tópicos estão indisponíveis', (
    tester,
  ) async {
    final dataSource = _EmotionalDataSource(
      record: {
        'id': 'daily-record-id',
        'diario_emocional': 'Meu registro continua disponível.',
      },
    );
    final topics = _SupportTopicDataSource(loadError: Exception('offline'));
    final resultFuture = await openDiarySheet(
      tester,
      dataSource: dataSource,
      supportTopics: topics,
    );

    expect(find.text('O que mais marcou hoje? (opcional)'), findsNothing);
    expect(find.text('Meu registro continua disponível.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('emotional-diary-submit')));
    await tester.pumpAndSettle();

    expect(dataSource.savedContent, 'Meu registro continua disponível.');
    expect(await resultFuture, isTrue);
    expect(tester.takeException(), isNull);
  });
}

class _EmotionalDataSource implements EmotionalDiaryDataSource {
  _EmotionalDataSource({this.record, this.clearError});

  final Map<String, dynamic>? record;
  final Object? clearError;
  int clearCalls = 0;
  String? savedContent;

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
  Future<void> createDiaryEntry({required String content}) async {
    savedContent = content;
  }

  @override
  Future<Map<String, dynamic>?> getTodayRecord() async => record;

  @override
  Future<List<EmotionalDiaryEntry>> listCurrentUserEntries() async => [];
}

class _SupportTopicDataSource implements EmotionalDiarySupportTopicDataSource {
  _SupportTopicDataSource({this.initial = const <String>{}, this.loadError});

  final Set<String> initial;
  final Object? loadError;
  String? savedRecordId;
  Set<String>? savedCodes;

  @override
  Future<Set<String>> listConfirmedSupportTopics({
    required String emotionalRecordId,
  }) async {
    if (loadError != null) throw loadError!;
    return initial;
  }

  @override
  Future<void> replaceConfirmedSupportTopics({
    required String emotionalRecordId,
    required Set<String> topicCodes,
  }) async {
    savedRecordId = emotionalRecordId;
    savedCodes = Set<String>.of(topicCodes);
  }
}
