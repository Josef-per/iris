import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Preserva o evento efemero de recuperacao enquanto a aplicacao inicializa.
///
/// O Supabase pode processar o deep link antes de o gate ser montado,
/// especialmente no cold start web e durante a splash nativa. Guardamos apenas
/// `passwordRecovery`; sessoes comuns continuam sendo lidas do cliente Auth.
abstract final class AuthRecoveryReplay {
  static AuthState? _pending;
  static StreamSubscription<AuthState>? _startupSubscription;

  static void start(Stream<AuthState> authStates) {
    final previous = _startupSubscription;
    if (previous != null) unawaited(previous.cancel());
    _startupSubscription = authStates.listen(
      capture,
      onError: (_, _) {
        // O AuthGate assume o tratamento de erros assim que for montado.
      },
    );
  }

  static void capture(AuthState state) {
    if (state.event == AuthChangeEvent.passwordRecovery) {
      _pending = state;
    } else if (state.event == AuthChangeEvent.signedOut) {
      _pending = null;
    }
  }

  static AuthState? take() {
    final state = _pending;
    _pending = null;
    return state;
  }

  static Future<void> stop() async {
    final subscription = _startupSubscription;
    _startupSubscription = null;
    await subscription?.cancel();
  }

  static Future<void> clear() async {
    _pending = null;
    await stop();
  }
}
