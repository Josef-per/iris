import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/screens/demo_professional_link_screen.dart';
import 'package:iris/screens/patient_session_gate.dart';
import 'package:iris/screens/qr_code_screen.dart';

void main() {
  testWidgets('exige aprovação explícita, sem código, e aguarda o backend', (
    tester,
  ) async {
    final approval = Completer<void>();
    var requests = 0;
    var linked = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DemoProfessionalLinkScreen(
          onLinked: () => linked++,
          onSignOut: () async {},
          approveLink: () {
            requests++;
            return approval.future;
          },
        ),
      ),
    );

    expect(find.text('Psiquiatra Lucas (para teste)'), findsOneWidget);
    expect(find.text('lucas@gmail.com'), findsOneWidget);
    expect(find.textContaining('acompanhar os registros'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(requests, 0);
    expect(linked, 0);

    await tester.tap(find.text('Aprovar vínculo e testar'));
    await tester.pump();
    expect(requests, 1);
    expect(linked, 0);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    approval.complete();
    await tester.pumpAndSettle();
    expect(linked, 1);
  });

  testWidgets('falha não libera paciente e permite tentar novamente ou sair', (
    tester,
  ) async {
    var requests = 0;
    var linked = 0;
    var signOuts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DemoProfessionalLinkScreen(
          onLinked: () => linked++,
          onSignOut: () async => signOuts++,
          approveLink: () async {
            requests++;
            throw Exception('falha de rede');
          },
        ),
      ),
    );
    await tester.tap(find.text('Aprovar vínculo e testar'));
    await tester.pumpAndSettle();
    expect(find.text('Algo deu errado. Tente novamente.'), findsOneWidget);
    expect(linked, 0);
    await tester.ensureVisible(find.text('Aprovar vínculo e testar'));
    await tester.tap(find.text('Aprovar vínculo e testar'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    expect(signOuts, 1);
    expect(linked, 0);
  });

  testWidgets('paciente existente sem vínculo continua no fluxo QR', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: PatientSessionGate(linkChecker: () async => false)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(QrcodeScreen), findsOneWidget);
    expect(find.byType(DemoProfessionalLinkScreen), findsNothing);
  });

  testWidgets('novo paciente de demonstração recebe somente a aprovação', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatientSessionGate(
          demoProfessionalLink: true,
          linkChecker: () async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DemoProfessionalLinkScreen), findsOneWidget);
    expect(find.byType(QrcodeScreen), findsNothing);
  });
}
