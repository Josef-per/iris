import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mantem perfil profissional ao abrir criar conta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen(initialProfessional: true)),
    );

    expect(find.text('Sou profissional'), findsOneWidget);
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Criar conta profissional'), findsOneWidget);
    expect(find.text('Especialidade'), findsOneWidget);
    expect(find.text('Registro profissional'), findsOneWidget);
    expect(find.text('Conecte-se ao seu profissional'), findsNothing);
  });

  testWidgets('mantem perfil profissional ao voltar para o login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen(initialProfessional: true)),
    );
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Já tenho uma conta'));
    await tester.tap(find.text('Já tenho uma conta'));
    await tester.pumpAndSettle();

    expect(
      find.text('Acesse o painel de acompanhamento profissional.'),
      findsOneWidget,
    );
  });
}
