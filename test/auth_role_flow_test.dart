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

  testWidgets('login sem backend nao simula uma sessao persistida', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'paciente@iris.app');
    await tester.enterText(fields.at(1), 'senha-segura');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.textContaining('Supabase não carregado'), findsOneWidget);
    expect(find.text('Entrar'), findsWidgets);
  });

  testWidgets('cadastro sem backend nao informa sucesso ficticio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Paciente Teste');
    await tester.enterText(fields.at(1), 'paciente@iris.app');
    await tester.enterText(fields.at(2), 'senha-segura');
    await tester.enterText(fields.at(3), 'senha-segura');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Criar minha conta'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Criar minha conta'));
    await tester.pump();

    expect(find.textContaining('Supabase não carregado'), findsOneWidget);
    expect(find.text('Criar conta'), findsWidgets);
  });
}
