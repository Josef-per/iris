import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/emergency_contact/emergency_contact.dart';
import 'package:iris/features/emergency_contact/emergency_contact_repository.dart';
import 'package:iris/features/profile/profile_model.dart';
import 'package:iris/features/profile/profile_repository.dart';
import 'package:iris/screens/patient_profile_screen.dart';

void main() {
  test('perfil lê nascimento e telefone salvos para exibição', () {
    final profile = Profile.fromMap({
      'id': 'profile-1',
      'user_id': 'user-1',
      'nome_completo': 'Paciente Teste',
      'data_nascimento': '1996-01-02',
      'telefone': '(11) 99999-9999',
    });

    expect(profile.birthDate, DateTime(1996, 1, 2));
    expect(profile.phone, '(11) 99999-9999');
  });

  testWidgets('conta antiga completa nascimento no perfil em dois campos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _ProfileRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: PatientProfileScreen(
          onSignOut: () async {},
          profileRepository: repository,
          emergencyContactDataSource: _EmptyEmergencyContactDataSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Data de nascimento: não informada'), findsOneWidget);
    await tester.tap(find.text('Completar dados'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pump();
    expect(find.text('Informe sua data de nascimento.'), findsOneWidget);
    expect(repository.saves, 0);

    await tester.enterText(
      find.byKey(const Key('patient-profile-birth-date')),
      '02/01/1996',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(repository.saves, 1);
    expect(repository.profile.birthDate, DateTime(1996, 1, 2));
    expect(repository.profile.phone, isEmpty);
    expect(find.text('Data de nascimento: 02/01/1996'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ProfileRepository extends ProfileRepository {
  Profile profile = const Profile(
    id: 'profile-1',
    userId: 'user-1',
    displayName: 'Paciente Teste',
  );
  int saves = 0;

  @override
  Future<Profile?> getCurrentUserProfile() async => profile;

  @override
  Future<void> updateCurrentPatientDetails({
    required DateTime birthDate,
    String? phone,
  }) async {
    saves++;
    profile = Profile(
      id: profile.id,
      userId: profile.userId,
      displayName: profile.displayName,
      birthDate: birthDate,
      phone: phone ?? '',
    );
  }
}

class _EmptyEmergencyContactDataSource implements EmergencyContactDataSource {
  @override
  Future<EmergencyContact?> load() async => null;

  @override
  Future<void> save(EmergencyContact contact) async {}

  @override
  Future<void> delete() async {}
}
