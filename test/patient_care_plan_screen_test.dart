import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/care_plan/patient_care_plan.dart';
import 'package:iris/features/care_plan/patient_care_plan_repository.dart';
import 'package:iris/screens/patient_care_plan_screen.dart';

class _PlansDataSource implements PatientCarePlanDataSource {
  _PlansDataSource(this.plans);

  final List<PatientCarePlan> plans;

  @override
  Future<List<PatientCarePlan>> listSharedPlans() async => plans;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPlans(
    WidgetTester tester, {
    required PatientCarePlanDataSource dataSource,
  }) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PatientCarePlanScreen(dataSource: dataSource),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra apenas o plano mais recente quando há vários', (
    tester,
  ) async {
    await pumpPlans(
      tester,
      dataSource: _PlansDataSource([
        PatientCarePlan(
          id: 'old',
          guidance: 'Orientação antiga',
          crisisSteps: const [],
          goals: const [],
          medications: const [],
          updatedAt: DateTime(2026, 8, 1),
        ),
        PatientCarePlan(
          id: 'new',
          guidance: 'Orientação nova',
          crisisSteps: const ['Passo de crise'],
          goals: const [],
          medications: const [
            PatientCareMedication(
              id: 'medication-id',
              name: 'Medicação atual',
              dose: '10 mg',
              frequency: '1 vez ao dia',
              adherence: .75,
            ),
          ],
          updatedAt: DateTime(2026, 8, 10),
        ),
      ]),
    );

    expect(find.text('Orientações'), findsOneWidget);
    expect(find.text('Orientação nova'), findsOneWidget);
    expect(find.text('Orientação antiga'), findsNothing);
    expect(find.text('Passos em momento de crise'), findsOneWidget);
    expect(find.text('10 mg · 1 vez ao dia · Adesão: 75%'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exibe estado vazio quando nenhum plano foi compartilhado', (
    tester,
  ) async {
    await pumpPlans(tester, dataSource: _PlansDataSource(const []));

    expect(find.byKey(const Key('patient-care-plan-empty')), findsOneWidget);
    expect(find.text('Nenhum plano compartilhado'), findsOneWidget);
  });
}
