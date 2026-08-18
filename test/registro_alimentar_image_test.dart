import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/food/food_record_repository.dart';
import 'package:iris/features/food/meal_image_picker.dart';
import 'package:iris/features/food/meal_type.dart';
import 'package:iris/widgets/bottom_sheets/registro_alimentar_bottom_sheet.dart';

void main() {
  testWidgets('permite tirar, visualizar, trocar e remover a foto', (
    tester,
  ) async {
    final picker = _FakeMealImagePicker([
      _testImage('primeira.png'),
      _testImage('segunda.png'),
    ]);

    await _pumpForm(tester, imagePicker: picker);
    await tester.tap(find.byKey(const Key('food-record-add')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('food-record-take-photo')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('food-record-photo-preview')), findsOneWidget);
    expect(find.text('Trocar foto'), findsOneWidget);
    expect(picker.takePhotoCalls, 1);

    await tester.tap(find.byKey(const Key('food-record-replace-photo')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('food-record-photo-preview')), findsOneWidget);
    expect(picker.takePhotoCalls, 2);

    await tester.tap(find.byKey(const Key('food-record-remove-photo')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('food-record-photo-preview')), findsNothing);
    expect(find.text('Tirar foto'), findsOneWidget);
  });

  testWidgets('mantem o cadastro disponivel sem foto', (tester) async {
    final repository = _FakeFoodRecordDataSource();
    await _pumpForm(
      tester,
      repository: repository,
      imagePicker: _FakeMealImagePicker(const []),
    );
    await tester.tap(find.byKey(const Key('food-record-add')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('food-record-description-field')),
      'Almoço',
    );
    final submit = find.byKey(const Key('food-record-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(repository.createRecordCalls, 1);
  });

  testWidgets('permite escolher e substituir a foto pela galeria', (
    tester,
  ) async {
    final picker = _FakeMealImagePicker(
      const [],
      galleryImages: [
        _testImage('galeria-inicial.png'),
        _testImage('galeria-substituida.png'),
      ],
    );

    await _pumpForm(tester, imagePicker: picker);
    await tester.tap(find.byKey(const Key('food-record-add')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('food-record-choose-photo')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('food-record-photo-preview')), findsOneWidget);
    expect(picker.chooseFromGalleryCalls, 1);

    await tester.tap(
      find.byKey(const Key('food-record-replace-photo-from-gallery')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('food-record-photo-preview')), findsOneWidget);
    expect(picker.chooseFromGalleryCalls, 2);
  });
}

Future<void> _pumpForm(
  WidgetTester tester, {
  FoodRecordDataSource? repository,
  required MealImagePicker imagePicker,
}) async {
  tester.view.physicalSize = const Size(500, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: RegistroAlimentarBottomSheet(
        repository: repository ?? _FakeFoodRecordDataSource(),
        imagePicker: imagePicker,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MealImage _testImage(String fileName) {
  return MealImage(
    bytes: base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
    fileName: fileName,
    mimeType: 'image/png',
  );
}

class _FakeMealImagePicker implements MealImagePicker {
  _FakeMealImagePicker(this.images, {this.galleryImages = const []});

  final List<MealImage> images;
  final List<MealImage> galleryImages;
  int takePhotoCalls = 0;
  int chooseFromGalleryCalls = 0;

  @override
  bool get isSupported => true;

  @override
  Future<MealImage?> retrieveLostPhoto() async => null;

  @override
  Future<MealImage?> takePhoto() async {
    final index = takePhotoCalls;
    takePhotoCalls += 1;
    return index < images.length ? images[index] : null;
  }

  @override
  Future<MealImage?> chooseFromGallery() async {
    final index = chooseFromGalleryCalls;
    chooseFromGalleryCalls += 1;
    return index < galleryImages.length ? galleryImages[index] : null;
  }
}

class _FakeFoodRecordDataSource implements FoodRecordDataSource {
  int createRecordCalls = 0;

  @override
  Future<int> countRecordsForLocalDay(DateTime day) async => 0;

  @override
  Future<void> createRecord({
    required String description,
    required int hungerLevel,
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
  }) async {
    createRecordCalls += 1;
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
  }) async {}

  @override
  Future<void> deleteRecord(String id) async {}

  @override
  Future<List<FoodRecord>> listRecordsForLocalDay(DateTime day) async => [];
}
