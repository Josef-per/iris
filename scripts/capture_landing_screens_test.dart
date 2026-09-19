// Run with flutter test scripts/capture_landing_screens_test.dart.
// Renders production widgets with isolated demonstration data; no backend calls.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/data/daily_companion_repository.dart';
import 'package:iris/features/ai_support/domain/daily_companion_message.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/features/patient_dashboard/patient_today_summary.dart';
import 'package:iris/screens/home_screen.dart';
import 'package:iris/widgets/bottom_sheets/check_in_diario_bottom_sheet.dart';
import 'package:iris/widgets/bottom_sheets/diario_emocional_bottom_sheet.dart';

class _DemoDay implements PatientTodayDataSource {
  @override
  Future<PatientTodaySummary> loadToday() async => const PatientTodaySummary(
    mealCount: 2,
    moodScore: 4,
    hasCheckIn: true,
    hasDiaryEntry: true,
  );
}

class _DemoDiary implements EmotionalDiaryDataSource {
  @override
  Future<Map<String, dynamic>?> getTodayRecord() async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Read-only capture');
}

class _DemoCompanion implements DailyCompanionDataSource {
  @override
  Future<DailyCompanionMessage>
  loadToday() async => const DailyCompanionMessage(
    status: DailyCompanionStatus.ready,
    title: 'Um momento para você',
    message:
        'Pequenos passos também fazem parte do caminho. Respeite o seu ritmo hoje.',
    reflectionQuestion: 'O que pode tornar seu dia mais acolhedor?',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('exporta telas reais para a landing page', (tester) async {
    final sdk = Platform.environment['FLUTTER_ROOT'];
    if (sdk == null)
      throw StateError('Defina FLUTTER_ROOT para carregar a fonte do app.');
    await tester.runAsync(() async {
      final fonts = FontLoader('Roboto');
      for (final weight in ['regular', 'medium', 'bold', 'black']) {
        fonts.addFont(
          Future.value(
            ByteData.sublistView(
              File(
                '$sdk/bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
              ).readAsBytesSync(),
            ),
          ),
        );
      }
      await fonts.load();
      // Some explicit button styles retain the test binding's default family.
      final fallback = FontLoader('Ahem')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                '$sdk/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
              ).readAsBytesSync(),
            ),
          ),
        );
      await fallback.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                '$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
              ).readAsBytesSync(),
            ),
          ),
        );
      await icons.load();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = Directory('web/landing/images')
      ..createSync(recursive: true);
    Future<void> capture(String name, Widget screen) async {
      print('Capturando $name');
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light.copyWith(
              platform: TargetPlatform.android,
              textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Roboto'),
              primaryTextTheme: AppTheme.light.primaryTextTheme.apply(
                fontFamily: 'Roboto',
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: AppTheme.light.filledButtonTheme.style?.copyWith(
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: AppTheme.light.outlinedButtonTheme.style?.copyWith(
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: AppTheme.light.textButtonTheme.style?.copyWith(
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            home: screen,
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold).first);
        for (final file in Directory(
          'assets/icons',
        ).listSync().whereType<File>()) {
          if (file.path.endsWith('.png')) {
            await precacheImage(
              AssetImage(file.path.replaceAll('\\', '/')),
              context,
            );
          }
        }
      });
      await tester.pumpAndSettle();
      print('Tela $name pronta');
      expect(tester.takeException(), isNull);
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${directory.path}/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      print('Imagem $name salva');
    }

    await capture(
      'hoje',
      HomeScreen(
        todayDataSource: _DemoDay(),
        dailyCompanionDataSource: _DemoCompanion(),
      ),
    );
    await capture(
      'check-in',
      Scaffold(body: CheckInDiarioBottomSheet(repository: _DemoDiary())),
    );
    await capture(
      'diario',
      Scaffold(body: DiarioEmocionalBottomSheet(repository: _DemoDiary())),
    );
  });
}
