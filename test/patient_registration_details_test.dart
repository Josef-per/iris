import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/profile/patient_birth_date.dart';
import 'package:iris/screens/cadastro_screen.dart';

void main() {
  test('data de nascimento rejeita datas impossíveis e futuras', () {
    final today = DateTime(2026, 9, 29);
    expect(
      parsePatientBirthDate('29/02/2024', today: today),
      DateTime(2024, 2, 29),
    );
    expect(parsePatientBirthDate('31/02/2000', today: today), isNull);
    expect(parsePatientBirthDate('30/09/2026', today: today), isNull);
    expect(parsePatientBirthDate('01/01/1899', today: today), isNull);
    expect(
      parseStoredPatientBirthDate('2024-02-29', today: today),
      DateTime(2024, 2, 29),
    );
    expect(patientBirthDateIso(DateTime(1996, 1, 2)), '1996-01-02');
  });

  testWidgets(
    'cadastro de paciente exige nascimento e envia data normalizada',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = _RecordingAuthService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CadastroScreen(authService: auth),
                  ),
                ),
                child: const Text('Abrir cadastro'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir cadastro'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('patient-signup-birth-date')),
        findsOneWidget,
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Paciente Teste');
      await tester.enterText(fields.at(2), 'paciente@iris.app');
      await tester.enterText(fields.at(3), 'senha-segura');
      await tester.enterText(fields.at(4), 'senha-segura');
      await tester.ensureVisible(find.text('Criar minha conta'));
      await tester.tap(find.text('Criar minha conta'));
      await tester.pump();
      expect(find.text('Informe sua data de nascimento.'), findsOneWidget);
      expect(auth.calls, 0);

      await tester.enterText(
        find.byKey(const Key('patient-signup-birth-date')),
        '31/02/2000',
      );
      await tester.ensureVisible(find.text('Criar minha conta'));
      await tester.tap(find.text('Criar minha conta'));
      await tester.pump();
      expect(find.textContaining('data válida'), findsOneWidget);
      expect(auth.calls, 0);

      await tester.enterText(
        find.byKey(const Key('patient-signup-birth-date')),
        '02011996',
      );
      expect(find.text('02/01/1996'), findsOneWidget);
      await tester.ensureVisible(find.text('Criar minha conta'));
      await tester.tap(find.text('Criar minha conta'));
      await tester.pumpAndSettle();
      expect(auth.calls, 1);
      expect(auth.birthDate, '1996-01-02');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cadastro profissional não preenche especialidade por padrão', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: CadastroScreen(
          initialProfessional: true,
          authService: _RecordingAuthService(),
        ),
      ),
    );
    expect(find.byKey(const Key('patient-signup-birth-date')), findsNothing);
    final specialty = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Especialidade'),
    );
    expect(specialty.controller?.text, isEmpty);
  });
}

class _RecordingAuthService extends AuthService {
  int calls = 0;
  String? birthDate;

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
    required String displayName,
    required String userType,
    String? specialty,
    String? professionalRegistration,
    String? birthDate,
  }) async {
    calls++;
    this.birthDate = birthDate;
    return const AuthSignUpResult(needsEmailConfirmation: true);
  }
}
