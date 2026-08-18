import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/patient_history/patient_history.dart';
import 'package:iris/screens/patient_history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHistory(
    WidgetTester tester, {
    required PatientHistoryDataSource dataSource,
    Size size = const Size(500, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PatientHistoryScreen(dataSource: dataSource),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('agrupa entradas por dia com Hoje, Ontem e data', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 19, 0);
    final yesterday = today.subtract(const Duration(days: 1));
    final older = today.subtract(const Duration(days: 5));

    await pumpHistory(
      tester,
      dataSource: _HistoryDataSource([
        PatientHistoryEntry(
          kind: PatientHistoryKind.emotional,
          moment: today,
          title: 'Diário emocional',
          description: 'Bem-estar: 4/5 · Dia tranquilo',
          icon: Icons.auto_stories_outlined,
        ),
        PatientHistoryEntry(
          kind: PatientHistoryKind.food,
          moment: yesterday,
          title: 'Almoço',
          description: 'Arroz, feijão e frango · Fome: 8/10',
          icon: Icons.restaurant_rounded,
        ),
        PatientHistoryEntry(
          kind: PatientHistoryKind.emotional,
          moment: older,
          title: 'Registro do dia',
          description: 'Bem-estar: 2/5',
          icon: Icons.favorite_outline_rounded,
        ),
      ]),
    );

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Ontem'), findsOneWidget);
    expect(find.text('Diário emocional'), findsOneWidget);
    expect(find.text('Almoço'), findsOneWidget);
    expect(find.text('Registro do dia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra estado vazio quando não há registros', (tester) async {
    await pumpHistory(tester, dataSource: _HistoryDataSource(const []));

    expect(find.byKey(const Key('patient-history-empty')), findsOneWidget);
    expect(find.text('Nenhum registro ainda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha ao carregar oferece nova tentativa', (tester) async {
    final dataSource = _HistoryDataSource(
      const [],
      loadError: Exception('falha'),
    );
    await pumpHistory(tester, dataSource: dataSource);

    expect(find.byKey(const Key('patient-history-error')), findsOneWidget);
    dataSource.loadError = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('patient-history-empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordenado pelo momento mais recente primeiro', (tester) async {
    final now = DateTime.now();
    final older = DateTime(now.year, now.month, now.day, 8, 0);
    final newer = DateTime(now.year, now.month, now.day, 21, 0);

    await pumpHistory(
      tester,
      dataSource: _HistoryDataSource([
        PatientHistoryEntry(
          kind: PatientHistoryKind.food,
          moment: older,
          title: 'Café da manhã',
          description: 'Pão e café',
          icon: Icons.restaurant_rounded,
        ),
        PatientHistoryEntry(
          kind: PatientHistoryKind.emotional,
          moment: newer,
          title: 'Diário emocional',
          description: 'Dia produtivo',
          icon: Icons.auto_stories_outlined,
        ),
      ]),
    );

    final diary = tester.getTopLeft(find.text('Diário emocional'));
    final breakfast = tester.getTopLeft(find.text('Café da manhã'));
    expect(diary.dy, lessThan(breakfast.dy));
    expect(tester.takeException(), isNull);
  });
}

class _HistoryDataSource implements PatientHistoryDataSource {
  _HistoryDataSource(this.entries, {this.loadError});

  final List<PatientHistoryEntry> entries;
  Object? loadError;

  @override
  Future<List<PatientHistoryEntry>> loadHistory() async {
    if (loadError != null) {
      throw loadError!;
    }
    return List.of(entries);
  }
}
