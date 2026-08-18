import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/food/food_record_repository.dart';
import 'package:iris/features/food/meal_type.dart';
import 'package:iris/widgets/bottom_sheets/registro_alimentar_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Future<bool?>> openFoodSheet(
    WidgetTester tester, {
    FoodRecordDataSource? dataSource,
    Size size = const Size(500, 1100),
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
                    builder: (_) => RegistroAlimentarBottomSheet(
                      repository: dataSource ?? _FoodDataSource(),
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

  testWidgets('mostra estado vazio quando não há refeições hoje', (
    tester,
  ) async {
    await openFoodSheet(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('food-sheet-empty')), findsOneWidget);
    expect(find.text('Nenhuma refeição registrada hoje.'), findsOneWidget);
    expect(find.byKey(const Key('food-record-add')), findsOneWidget);
  });

  testWidgets('adiciona refeição com tipo, horário e descrição validada', (
    tester,
  ) async {
    final dataSource = _FoodDataSource();
    await openFoodSheet(tester, dataSource: dataSource);

    await tester.tap(find.byKey(const Key('food-record-add')));
    await tester.pumpAndSettle();

    expect(find.text('Nova refeição'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('food-record-submit')));
    await tester.pump();
    expect(find.text('Descreva a refeição.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('food-meal-type-almoco')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('food-record-description-field')),
      'Arroz, feijão e frango',
    );
    await _tapVisible(tester, find.byKey(const Key('food-record-submit')));
    await tester.pumpAndSettle();

    expect(dataSource.records, hasLength(1));
    expect(dataSource.records.first.description, 'Arroz, feijão e frango');
    expect(dataSource.records.first.mealType, MealType.almoco);
    expect(dataSource.records.first.mealTime, isNotNull);

    expect(find.text('Registro alimentar salvo.'), findsOneWidget);
    expect(find.text('Almoço'), findsOneWidget);
    expect(find.text('Arroz, feijão e frango'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abre o seletor de horário sem quebrar o fluxo', (tester) async {
    final dataSource = _FoodDataSource();
    await openFoodSheet(tester, dataSource: dataSource);

    await tester.tap(find.byKey(const Key('food-record-add')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('food-record-time-field')));
    await tester.pumpAndSettle();
    expect(find.text('Selecione o horário da refeição'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Confirmar').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('food-record-description-field')),
      'Lanche da tarde',
    );
    await _tapVisible(tester, find.byKey(const Key('food-record-submit')));
    await tester.pumpAndSettle();

    expect(dataSource.records, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('edita uma refeição existente com campos pré-preenchidos', (
    tester,
  ) async {
    final dataSource = _FoodDataSource()
      ..records.add(
        _foodRecord('r1', 'Iogurte com granola', MealType.cafeDaManha),
      );
    await openFoodSheet(tester, dataSource: dataSource);

    final card = find.byKey(const ValueKey('food-record-r1'));
    await tester.ensureVisible(card);
    await tester.tap(find.byTooltip('Mais ações para Café da manhã'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar').last);
    await tester.pumpAndSettle();

    expect(find.text('Editar refeição'), findsOneWidget);
    expect(find.text('Iogurte com granola'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('food-record-description-field')),
      'Iogurte com granola e banana',
    );
    await _tapVisible(tester, find.byKey(const Key('food-record-submit')));
    await tester.pumpAndSettle();

    expect(dataSource.records, hasLength(1));
    expect(
      dataSource.records.first.description,
      'Iogurte com granola e banana',
    );
    expect(dataSource.records.first.mealType, MealType.cafeDaManha);
    expect(find.text('Registro alimentar atualizado.'), findsOneWidget);
    expect(find.text('Iogurte com granola e banana'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exclui refeição após confirmação', (tester) async {
    final dataSource = _FoodDataSource()
      ..records.add(_foodRecord('r1', 'Sopa de legumes', null));
    await openFoodSheet(tester, dataSource: dataSource);

    final card = find.byKey(const ValueKey('food-record-r1'));
    await tester.ensureVisible(card);
    await tester.tap(find.byTooltip('Mais ações para Refeição'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();

    expect(find.text('Excluir registro?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(dataSource.records, isEmpty);
    expect(find.text('Registro alimentar excluído.'), findsOneWidget);
    expect(find.byKey(const Key('food-sheet-empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fechar após mudanças devolve sucesso para atualizar o resumo', (
    tester,
  ) async {
    final dataSource = _FoodDataSource();
    final resultFuture = await openFoodSheet(tester, dataSource: dataSource);

    await tester.tap(find.byKey(const Key('food-record-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('food-record-description-field')),
      'Café da manhã reforçado',
    );
    await _tapVisible(tester, find.byKey(const Key('food-record-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    expect(await resultFuture, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha ao carregar oferece nova tentativa', (tester) async {
    final dataSource = _FoodDataSource(loadError: Exception('falha'));
    await openFoodSheet(tester, dataSource: dataSource);

    expect(find.byKey(const Key('food-record-load-retry')), findsOneWidget);
    dataSource.loadError = null;
    await tester.tap(find.byKey(const Key('food-record-load-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('food-sheet-empty')), findsOneWidget);
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

FoodRecord _foodRecord(String id, String description, MealType? mealType) {
  return FoodRecord(
    id: id,
    mealType: mealType,
    description: description,
    hungerLevel: 5,
    feelingAfter: 'Satisfeita',
    observations: null,
    mealTime: DateTime(2026, 8, 14, 12, 30),
  );
}

class _FoodDataSource implements FoodRecordDataSource {
  _FoodDataSource({this.loadError});

  final List<FoodRecord> records = [];
  Object? loadError;

  @override
  Future<List<FoodRecord>> listRecordsForLocalDay(DateTime day) async {
    if (loadError != null) {
      throw loadError!;
    }
    return List.of(records);
  }

  @override
  Future<int> countRecordsForLocalDay(DateTime day) async => records.length;

  @override
  Future<void> createRecord({
    required String description,
    required int hungerLevel,
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
  }) async {
    records.add(
      FoodRecord(
        id: 'generated-${records.length}',
        mealType: mealType,
        description: description,
        hungerLevel: hungerLevel,
        feelingAfter: feelingAfter,
        observations: observations,
        mealTime: mealTime ?? DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateRecord({
    required String id,
    required String description,
    required int hungerLevel,
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
  }) async {
    final index = records.indexWhere((record) => record.id == id);
    records[index] = FoodRecord(
      id: id,
      mealType: mealType,
      description: description,
      hungerLevel: hungerLevel,
      feelingAfter: feelingAfter,
      observations: observations,
      mealTime: mealTime ?? records[index].mealTime,
    );
  }

  @override
  Future<void> deleteRecord(String id) async {
    records.removeWhere((record) => record.id == id);
  }
}
