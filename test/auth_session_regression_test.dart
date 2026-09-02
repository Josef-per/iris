import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/auth/auth_recovery_replay.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/main.dart';
import 'package:iris/screens/login_screen.dart';
import 'package:iris/screens/patient_session_gate.dart';
import 'package:iris/screens/session_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cadastro e volta preservam a rota que contem o login', (
    tester,
  ) async {
    _setLargeViewport(tester);
    final auth = _FakeAuthService();
    final observer = _RecordingNavigatorObserver();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: LoginScreen(initialProfessional: true, authService: auth),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'pro@iris.app');
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(observer.replacements, 0);
    expect(find.text('Criar conta profissional'), findsOneWidget);

    await tester.ensureVisible(find.text('Já tenho uma conta'));
    await tester.tap(find.text('Já tenho uma conta'));
    await tester.pumpAndSettle();

    final emailField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(emailField.controller?.text, 'pro@iris.app');
    expect(
      find.text('Acesse o painel de acompanhamento profissional.'),
      findsOneWidget,
    );
  });

  testWidgets('AuthGate reage imediatamente a login e logout', (tester) async {
    final auth = _FakeAuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authService: auth,
          signedOutBuilder: (_) => const Text('sessao encerrada'),
          signedInBuilder: (_) => const Text('sessao autenticada'),
        ),
      ),
    );
    expect(find.text('sessao encerrada'), findsOneWidget);

    auth.emit(AuthChangeEvent.signedIn, _session);
    await tester.pump();
    expect(find.text('sessao autenticada'), findsOneWidget);

    await auth.signOut();
    await tester.pump();
    expect(find.text('sessao encerrada'), findsOneWidget);
  });

  testWidgets('AuthGate aguarda a validacao autoritativa do perfil', (
    tester,
  ) async {
    final auth = _FakeAuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authService: auth,
          signedOutBuilder: (_) => const Text('login preservado'),
          signedInBuilder: (_) => const Text('workspace liberado'),
        ),
      ),
    );

    auth.validation.value = true;
    auth.emit(AuthChangeEvent.signedIn, _session);
    await tester.pump();
    expect(find.text('login preservado'), findsOneWidget);
    expect(find.text('workspace liberado'), findsNothing);

    auth.validation.value = false;
    await tester.pump();
    expect(find.text('workspace liberado'), findsOneWidget);
  });

  testWidgets('logout descarta rotas abertas dentro da sessao', (tester) async {
    final auth = _FakeAuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authService: auth,
          signedOutBuilder: (_) => const Text('sessao encerrada'),
          signedInBuilder: (context) => FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Text('conteudo clinico sensivel'),
              ),
            ),
            child: const Text('abrir prontuario'),
          ),
        ),
      ),
    );
    auth.emit(AuthChangeEvent.signedIn, _session);
    await tester.pump();
    await tester.tap(find.text('abrir prontuario'));
    await tester.pumpAndSettle();
    expect(find.text('conteudo clinico sensivel'), findsOneWidget);

    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('conteudo clinico sensivel'), findsNothing);
    expect(find.text('sessao encerrada'), findsOneWidget);
  });

  testWidgets('logout descarta dialogo ligado ao Navigator da sessao', (
    tester,
  ) async {
    final auth = _FakeAuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authService: auth,
          signedOutBuilder: (_) => const Text('sessao encerrada'),
          signedInBuilder: (context) => FilledButton(
            onPressed: () => showDialog<void>(
              context: context,
              useRootNavigator: false,
              builder: (_) => const AlertDialog(
                content: Text('dados sensiveis no dialogo'),
              ),
            ),
            child: const Text('abrir dialogo'),
          ),
        ),
      ),
    );
    auth.emit(AuthChangeEvent.signedIn, _session);
    await tester.pump();
    await tester.tap(find.text('abrir dialogo'));
    await tester.pumpAndSettle();
    expect(find.text('dados sensiveis no dialogo'), findsOneWidget);

    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('dados sensiveis no dialogo'), findsNothing);
    expect(find.text('sessao encerrada'), findsOneWidget);
  });

  testWidgets('recuperacao troca a senha e encerra a sessao temporaria', (
    tester,
  ) async {
    _setLargeViewport(tester);
    final auth = _FakeAuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(MaterialApp(home: AuthGate(authService: auth)));
    auth.emit(AuthChangeEvent.passwordRecovery, _session);
    await tester.pump();

    expect(find.text('Criar nova senha'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'nova-senha-segura');
    await tester.enterText(fields.at(1), 'nova-senha-segura');
    await tester.ensureVisible(find.text('Atualizar senha'));
    await tester.tap(find.text('Atualizar senha'));
    await tester.pumpAndSettle();

    expect(auth.updatedPassword, 'nova-senha-segura');
    expect(auth.signOutCalls, 1);
    expect(
      find.text('Senha atualizada. Entre novamente com sua nova senha.'),
      findsOneWidget,
    );
  });

  testWidgets('AuthGate consome passwordRecovery recebido no cold start', (
    tester,
  ) async {
    _setLargeViewport(tester);
    final auth = _FakeAuthService();
    addTearDown(auth.dispose);
    addTearDown(AuthRecoveryReplay.clear);

    // Simula o Supabase emitindo o evento antes da splash concluir e antes de
    // o AuthGate assinar o stream ao vivo.
    auth.emit(AuthChangeEvent.passwordRecovery, _session);
    AuthRecoveryReplay.capture(
      AuthState(AuthChangeEvent.passwordRecovery, _session),
    );

    await tester.pumpWidget(MaterialApp(home: AuthGate(authService: auth)));

    expect(find.text('Criar nova senha'), findsOneWidget);
    expect(find.byType(SessionGate), findsNothing);
  });

  testWidgets('login oferece recuperacao e reenvio sem backend remoto', (
    tester,
  ) async {
    _setLargeViewport(tester);
    final auth = _FakeAuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(MaterialApp(home: LoginScreen(authService: auth)));

    await tester.ensureVisible(find.text('Esqueci minha senha'));
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ),
      'paciente@iris.app',
    );
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();
    expect(auth.passwordResetEmail, 'paciente@iris.app');

    await tester.ensureVisible(find.text('Reenviar confirmação'));
    await tester.tap(find.text('Reenviar confirmação'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ),
      'pendente@iris.app',
    );
    await tester.tap(find.text('Reenviar e-mail'));
    await tester.pumpAndSettle();
    expect(auth.confirmationEmail, 'pendente@iris.app');
  });

  testWidgets('falha de bootstrap permite sair e trocar de conta', (
    tester,
  ) async {
    final auth = _FakeAuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SessionGate(
          authService: auth,
          userTypeResolver: () async => throw Exception('falha temporaria'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Não foi possível carregar sua sessão'), findsOneWidget);
    await tester.tap(find.text('Sair e trocar de conta'));
    await tester.pump();
    expect(auth.signOutCalls, 1);
  });

  testWidgets('falha ao verificar vinculo nao prende a conta do paciente', (
    tester,
  ) async {
    final auth = _FakeAuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: PatientSessionGate(
          authService: auth,
          linkChecker: () async => throw Exception('falha temporaria'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sair e trocar de conta'), findsOneWidget);
    await tester.tap(find.text('Sair e trocar de conta'));
    await tester.pump();
    expect(auth.signOutCalls, 1);
  });

  testWidgets('verificacao de vinculo nao estoura em uma area minima', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1, 1);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = _FakeAuthService();
    final linkCheck = Completer<bool>();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: PatientSessionGate(
          authService: auth,
          linkChecker: () => linkCheck.future,
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil invalido encerra automaticamente a sessao', (
    tester,
  ) async {
    final auth = _FakeAuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SessionGate(
          authService: auth,
          userTypeResolver: () async => 'administrador',
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(auth.signOutCalls, 1);
  });
}

void _setLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  int replacements = 0;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacements += 1;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class _FakeAuthService extends AuthService {
  final _states = StreamController<AuthState>.broadcast();
  final validation = ValueNotifier(false);
  Session? _currentSession;
  int signOutCalls = 0;
  String? passwordResetEmail;
  String? confirmationEmail;
  String? updatedPassword;

  @override
  Session? get currentSession => _currentSession;

  @override
  Stream<AuthState> get authStateChanges => _states.stream;

  @override
  ValueListenable<bool> get profileValidationInProgress => validation;

  void emit(AuthChangeEvent event, Session? session) {
    _currentSession = session;
    _states.add(AuthState(event, session));
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    passwordResetEmail = email;
  }

  @override
  Future<void> resendSignUpConfirmation({required String email}) async {
    confirmationEmail = email;
  }

  @override
  Future<void> updatePassword({required String password}) async {
    updatedPassword = password;
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    emit(AuthChangeEvent.signedOut, null);
  }

  Future<void> dispose() async {
    validation.dispose();
    await _states.close();
  }
}

final _session = Session(
  accessToken: 'test-token',
  tokenType: 'bearer',
  refreshToken: 'test-refresh-token',
  user: const User(
    id: 'test-user',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-08-02T00:00:00Z',
  ),
);
