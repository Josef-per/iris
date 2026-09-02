import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/core/time/local_day.dart';
import 'package:iris/features/ai_support/data/daily_companion_repository.dart';
import 'package:iris/features/ai_support/domain/daily_companion_message.dart';
import 'package:iris/features/care_plan/patient_care_plan.dart';
import 'package:iris/features/care_plan/patient_care_plan_repository.dart';
import 'package:iris/features/emotional_diary/emotional_diary_entry.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/features/emotional_diary/patient_symptoms.dart';
import 'package:iris/features/food/food_record_repository.dart';
import 'package:iris/features/food/meal_image_picker.dart';
import 'package:iris/features/food/meal_type.dart';
import 'package:iris/features/patient_dashboard/patient_today_summary.dart';
import 'package:iris/screens/home_screen.dart';
import 'package:iris/screens/patient_care_plan_screen.dart';
import 'package:iris/widgets/app_mood_selector.dart';
import 'package:iris/widgets/bottom_sheets/check_in_diario_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resume os registros reais do dia sem metas ficticias', () async {
    final repository = PatientTodayRepository(
      foodRecords: _FoodDataSource(count: 3),
      emotionalDiary: _EmotionalDataSource(
        record: {
          'como_sentiu': 4,
          'avaliacao_alimentacao': 3,
          'diario_emocional': 'Dia tranquilo',
        },
      ),
      clock: () => DateTime(2026, 8, 2, 12),
    );

    final summary = await repository.loadToday();

    expect(summary.mealCount, 3);
    expect(summary.moodLabel, 'Bem');
    expect(summary.checkInLabel, 'Concluído');
    expect(summary.hasDiaryEntry, isTrue);
  });

  test('representa honestamente um dia sem registros', () async {
    final repository = PatientTodayRepository(
      foodRecords: _FoodDataSource(count: 0),
      emotionalDiary: _EmotionalDataSource(record: null),
    );

    final summary = await repository.loadToday();

    expect(summary.mealCount, 0);
    expect(summary.moodLabel, 'Sem registro');
    expect(summary.checkInLabel, 'Aguardando você');
    expect(summary.hasDiaryEntry, isFalse);
  });

  test('converte indices legados de sintomas para codigos estaveis', () {
    expect(
      PatientSymptoms.decode([0, '2', 'compulsao'], PatientSymptoms.emotional),
      {'inseguranca', 'vomito_autoinduzido', 'compulsao'},
    );
    expect(PatientSymptoms.decode([5, 8], PatientSymptoms.physical), {
      'desmaio',
      'nausea',
    });
  });

  test('gera uma chave de dia local independente do horario', () {
    expect(LocalDay.key(DateTime(2026, 8, 2, 23, 59)), '2026-08-02');
    expect(LocalDay.start(DateTime(2026, 8, 2, 23, 59)).hour, 0);
  });

  test('rejeita registro emocional sem timestamp em vez de inventar data', () {
    expect(
      () => EmotionalDiaryEntry.fromMap({
        'id': 'entry-id',
        'diario_emocional': 'Conteúdo',
      }),
      throwsFormatException,
    );
  });

  testWidgets('Home exibe indicadores vindos da fonte de dados', (
    tester,
  ) async {
    await _pumpPatientWidget(
      tester,
      HomeScreen(
        todayDataSource: _TodayDataSource(
          const PatientTodaySummary(
            mealCount: 2,
            moodScore: 5,
            hasCheckIn: true,
            hasDiaryEntry: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('patient-today-meals')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(find.text('Muito feliz'), findsOneWidget);
    expect(find.text('Concluído'), findsOneWidget);
    expect(find.text('3/4'), findsNothing);
    expect(find.text('1/2'), findsNothing);
  });

  testWidgets('Home oferece nova tentativa depois de erro de leitura', (
    tester,
  ) async {
    final dataSource = _RetryTodayDataSource();
    await _pumpPatientWidget(tester, HomeScreen(todayDataSource: dataSource));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('patient-today-retry')), findsOneWidget);
    await tester.tap(find.byKey(const Key('patient-today-retry')));
    await tester.pumpAndSettle();

    expect(dataSource.calls, 2);
    expect(find.text('Regular'), findsOneWidget);
  });

  testWidgets('Home permanece legível na largura de 320 pixels', (
    tester,
  ) async {
    await _pumpPatientWidget(
      tester,
      HomeScreen(
        todayDataSource: _TodayDataSource(
          const PatientTodaySummary(
            mealCount: 2,
            moodScore: 4,
            hasCheckIn: true,
            hasDiaryEntry: true,
          ),
        ),
      ),
      size: const Size(320, 700),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Registre seu dia'), findsOneWidget);
  });

  testWidgets('Home limita a largura do card de apoio em telas grandes', (
    tester,
  ) async {
    await _pumpPatientWidget(
      tester,
      HomeScreen(
        todayDataSource: _TodayDataSource(
          const PatientTodaySummary(
            mealCount: 1,
            moodScore: 4,
            hasCheckIn: true,
            hasDiaryEntry: false,
          ),
        ),
      ),
      size: const Size(1400, 1000),
    );
    await tester.pumpAndSettle();

    final companion = find.byKey(const Key('home-daily-companion-card'));
    expect(companion, findsOneWidget);
    expect(tester.getSize(companion).width, lessThanOrEqualTo(680));
    expect(
      tester.getTopLeft(companion).dy,
      lessThan(tester.getTopLeft(find.text('Registre seu dia')).dy),
    );
  });

  testWidgets('Home abre a reflexão completa em um diálogo', (tester) async {
    const fullMessage =
        'Talvez ajude separar o que precisa de atenção agora do que pode esperar:\n\n'
        '- **Agora:** uma prioridade possível.\n'
        '- **Depois:** decisões que não são urgentes.';
    await _pumpPatientWidget(
      tester,
      HomeScreen(
        todayDataSource: _TodayDataSource(
          const PatientTodaySummary(
            mealCount: 1,
            moodScore: 4,
            hasCheckIn: true,
            hasDiaryEntry: false,
          ),
        ),
        dailyCompanionDataSource: const _DailyCompanionSource(
          DailyCompanionMessage(
            status: DailyCompanionStatus.ready,
            title: 'Um momento para si',
            message: fullMessage,
            reflectionQuestion: null,
          ),
        ),
      ),
      size: const Size(500, 1000),
    );
    await tester.pumpAndSettle();

    expect(find.text('Um momento para si'), findsOneWidget);
    expect(
      find.byKey(const Key('home-daily-companion-markdown')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('home-daily-companion-open')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('home-daily-companion-dialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home-daily-companion-markdown')),
      findsOneWidget,
    );
    expect(find.textContaining('Agora:', findRichText: true), findsOneWidget);
    expect(find.text('Concluir'), findsOneWidget);
    expect(find.text('Gerenciar meus dados'), findsOneWidget);
    expect(find.text('Ajustar personalização'), findsNothing);

    await tester.tap(find.byKey(const Key('home-daily-companion-complete')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-daily-companion-dialog')), findsNothing);
  });

  testWidgets('check-in nao salva respostas neutras implicitas', (
    tester,
  ) async {
    final repository = _EmotionalDataSource(record: null);
    await _pumpPatientWidget(
      tester,
      CheckInDiarioBottomSheet(repository: repository),
      size: const Size(500, 1400),
    );
    await tester.pumpAndSettle();

    final confirm = find.byKey(const Key('check-in-submit'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pump();

    expect(repository.createCheckInCalls, 0);
    expect(
      find.text('Selecione como você se sentiu e como foi sua alimentação.'),
      findsOneWidget,
    );
  });

  testWidgets('check-in bloqueia edicao quando a leitura inicial falha', (
    tester,
  ) async {
    final repository = _EmotionalDataSource(loadError: Exception('falha'));
    await _pumpPatientWidget(
      tester,
      CheckInDiarioBottomSheet(repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('check-in-load-retry')), findsOneWidget);
    expect(find.byKey(const Key('check-in-submit')), findsNothing);
    expect(repository.createCheckInCalls, 0);
  });

  testWidgets('check-in adapta os seletores à largura de 320 pixels', (
    tester,
  ) async {
    await _pumpPatientWidget(
      tester,
      CheckInDiarioBottomSheet(repository: _EmotionalDataSource(record: null)),
      size: const Size(320, 700),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('check-in-submit')), findsOneWidget);
    final surface = find.byKey(const Key('app-bottom-sheet-surface'));
    expect(tester.getTopLeft(surface).dy, 0);
    expect(tester.getSize(surface).height, 700);
    expect(
      find.byKey(const Key('app-bottom-sheet-drag-handle')),
      findsOneWidget,
    );
    expect(tester.getCenter(find.byTooltip('Fechar')).dx, greaterThan(270));

    for (final gridKey in const [
      Key('check-in-mood-options'),
      Key('check-in-food-options'),
    ]) {
      final selectors = find.descendant(
        of: find.byKey(gridKey),
        matching: find.byType(AppMoodSelector),
      );
      expect(selectors, findsNWidgets(5));
      final topPositions = [
        for (var index = 0; index < 5; index++)
          tester.getTopLeft(selectors.at(index)).dy,
      ];
      expect(topPositions.toSet(), hasLength(1));
    }
  });

  testWidgets('plano compartilhado exibe metas e medicacoes reais', (
    tester,
  ) async {
    final plan = PatientCarePlan(
      id: 'plan-id',
      guidance: 'Manter refeições regulares.',
      crisisSteps: const ['Entrar em contato com a equipe'],
      goals: const [
        PatientCareGoal(
          id: 'goal-id',
          description: 'Registrar o almoço',
          isCompleted: false,
        ),
      ],
      medications: const [
        PatientCareMedication(
          id: 'medication-id',
          name: 'Medicação prescrita',
          dose: '10 mg',
          frequency: '1 vez ao dia',
        ),
      ],
      updatedAt: DateTime(2026, 8, 2),
    );
    await _pumpPatientWidget(
      tester,
      PatientCarePlanScreen(dataSource: _CarePlanDataSource([plan])),
      size: const Size(500, 1200),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manter refeições regulares.'), findsOneWidget);
    expect(find.text('Registrar o almoço'), findsOneWidget);
    expect(find.text('Medicação prescrita'), findsOneWidget);
    expect(find.text('Entrar em contato com a equipe'), findsOneWidget);
  });

  testWidgets('plano compartilhado possui estado vazio explicito', (
    tester,
  ) async {
    await _pumpPatientWidget(
      tester,
      PatientCarePlanScreen(dataSource: _CarePlanDataSource(const [])),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('patient-care-plan-empty')), findsOneWidget);
    expect(find.text('Nenhum plano compartilhado'), findsOneWidget);
  });
}

Future<void> _pumpPatientWidget(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(500, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: child));
}

class _TodayDataSource implements PatientTodayDataSource {
  _TodayDataSource(this.summary);

  final PatientTodaySummary summary;

  @override
  Future<PatientTodaySummary> loadToday() async => summary;
}

class _DailyCompanionSource implements DailyCompanionDataSource {
  const _DailyCompanionSource(this.message);

  final DailyCompanionMessage message;

  @override
  Future<DailyCompanionMessage> loadToday() async => message;
}

class _RetryTodayDataSource implements PatientTodayDataSource {
  int calls = 0;

  @override
  Future<PatientTodaySummary> loadToday() async {
    calls += 1;
    if (calls == 1) {
      throw Exception('falha');
    }
    return const PatientTodaySummary(
      mealCount: 1,
      moodScore: 3,
      hasCheckIn: true,
      hasDiaryEntry: false,
    );
  }
}

class _FoodDataSource implements FoodRecordDataSource {
  _FoodDataSource({required this.count});

  final int count;

  @override
  Future<int> countRecordsForLocalDay(DateTime day) async => count;

  @override
  Future<FoodRecordSaveResult> createRecord({
    required String description,
    required int hungerLevel,
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
    MealImage? photo,
  }) async => const FoodRecordSaveResult();

  @override
  Future<FoodRecordSaveResult> updateRecord({
    required String id,
    required String description,
    required int hungerLevel,
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
    MealImage? photo,
  }) async => const FoodRecordSaveResult();

  @override
  Future<FoodRecordDeleteResult> deleteRecord(String id) async =>
      const FoodRecordDeleteResult();

  @override
  Future<List<FoodRecord>> listRecordsForLocalDay(DateTime day) async => [];
}

class _EmotionalDataSource implements EmotionalDiaryDataSource {
  _EmotionalDataSource({this.record, this.loadError});

  final Map<String, dynamic>? record;
  final Object? loadError;
  int createCheckInCalls = 0;

  @override
  Future<void> createCheckIn({
    required int comoSentiu,
    required int avaliacaoAlimentacao,
    required List<String> sintomasEmocionaisHoje,
    required List<String> sintomasFisicosHoje,
    String? humor,
  }) async {
    createCheckInCalls += 1;
  }

  @override
  Future<void> createDiaryEntry({required String content}) async {}

  @override
  Future<void> clearDiaryEntry() async {}

  @override
  Future<Map<String, dynamic>?> getTodayRecord() async {
    if (loadError != null) {
      throw loadError!;
    }
    return record;
  }

  @override
  Future<List<EmotionalDiaryEntry>> listCurrentUserEntries() async => [];
}

class _CarePlanDataSource implements PatientCarePlanDataSource {
  _CarePlanDataSource(this.plans);

  final List<PatientCarePlan> plans;

  @override
  Future<List<PatientCarePlan>> listSharedPlans() async => plans;
}
