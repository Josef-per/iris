import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/supabase/supabase_config.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/auth/auth_recovery_replay.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/screens/login_screen.dart';
import 'package:iris/screens/password_recovery_screen.dart';
import 'package:iris/screens/session_gate.dart';
import 'package:iris/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    final initialization = Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    // Supabase configura o client antes de aguardar storage/deep links. A
    // assinatura temporaria evita perder passwordRecovery antes da splash.
    AuthRecoveryReplay.start(Supabase.instance.client.auth.onAuthStateChange);
    await initialization;
  }

  runApp(const IrisApp());
}

class IrisApp extends StatelessWidget {
  const IrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.mode,
      builder: (context, themeMode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Íris',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: IrisSplashScreen(
          next: SupabaseConfig.isConfigured
              ? const AuthGate()
              : const LoginScreen(),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.authService,
    this.signedOutBuilder,
    this.signedInBuilder,
  });

  final AuthService? authService;
  final WidgetBuilder? signedOutBuilder;
  final WidgetBuilder? signedInBuilder;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService;
  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;
  bool _isPasswordRecovery = false;
  String? _loginMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _session = _authService.currentSession;
    _authService.profileValidationInProgress.addListener(
      _handleProfileValidation,
    );
    _authSubscription = _authService.authStateChanges.listen(
      _handleAuthState,
      onError: _handleAuthError,
    );
    final replayedState = AuthRecoveryReplay.take();
    unawaited(AuthRecoveryReplay.stop());
    if (replayedState?.event == AuthChangeEvent.passwordRecovery) {
      _session = replayedState!.session ?? _session;
      _isPasswordRecovery = _session != null;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authService.profileValidationInProgress.removeListener(
      _handleProfileValidation,
    );
    super.dispose();
  }

  void _handleAuthState(AuthState state) {
    if (!mounted) return;
    if (state.event != AuthChangeEvent.passwordRecovery &&
        state.event != AuthChangeEvent.signedOut &&
        _authService.profileValidationInProgress.value) {
      return;
    }
    setState(() {
      _session = state.session;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
      } else if (state.event == AuthChangeEvent.signedOut) {
        _isPasswordRecovery = false;
      }
    });
  }

  void _handleProfileValidation() {
    if (!mounted || _authService.profileValidationInProgress.value) return;
    setState(() => _session = _authService.currentSession);
  }

  void _handleAuthError(Object error, StackTrace stackTrace) {
    if (!mounted) return;
    final session = _authService.currentSession;
    setState(() {
      _session = session;
      if (session == null) _loginMessage = AppErrorMessages.from(error);
    });
  }

  void _passwordUpdated() {
    if (!mounted) return;
    setState(() {
      _loginMessage = 'Senha atualizada. Entre novamente com sua nova senha.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isPasswordRecovery && _session != null) {
      return _modeNavigator(
        key: ValueKey('password-recovery-${_session!.user.id}'),
        builder: (_) => PasswordRecoveryScreen(
          authService: _authService,
          onPasswordUpdated: _passwordUpdated,
        ),
      );
    }

    if (_session == null) {
      final builder = widget.signedOutBuilder;
      return _modeNavigator(
        key: ValueKey('signed-out-${_loginMessage ?? ''}'),
        builder:
            builder ??
            (_) => LoginScreen(
              authService: _authService,
              initialMessage: _loginMessage,
            ),
      );
    }

    final builder = widget.signedInBuilder;
    return _modeNavigator(
      key: ValueKey('signed-in-${_session!.user.id}'),
      builder: builder ?? (_) => SessionGate(authService: _authService),
    );
  }

  Widget _modeNavigator({required Key key, required WidgetBuilder builder}) {
    return Navigator(
      key: key,
      onGenerateRoute: (settings) =>
          MaterialPageRoute<void>(settings: settings, builder: builder),
    );
  }
}
