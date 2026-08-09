import 'package:flutter/foundation.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/core/supabase/supabase_config.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final _users = UserRepository();
  final ValueNotifier<bool> _profileValidationInProgress = ValueNotifier(false);

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Permite que o gate aguarde a validacao do perfil autoritativo no banco
  /// antes de substituir a tela de login pelo workspace autenticado.
  ValueListenable<bool> get profileValidationInProgress =>
      _profileValidationInProgress;

  Future<void> signIn({
    required String email,
    required String password,
    required String expectedUserType,
  }) async {
    _profileValidationInProgress.value = true;
    try {
      final cleanEmail = email.trim().toLowerCase();
      final response = await _client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
      final user = response.user ?? _client.auth.currentUser;
      if (user == null) throw AuthSessionMissingException();

      await _users.ensureSessionForAuthUser(
        user,
        email: cleanEmail,
        displayName: _displayNameFromMetadata(user),
      );

      final actualUserType = await _users.getCurrentUserType();
      if (actualUserType != expectedUserType) {
        await _client.auth.signOut();
        throw AccountTypeMismatchException(
          expectedUserType: expectedUserType,
          actualUserType: actualUserType,
        );
      }
    } catch (_) {
      if (_client.auth.currentSession != null) {
        try {
          await _client.auth.signOut();
        } catch (_) {
          // A falha original e mais util. O AuthGate tambem observa a sessao
          // local e oferece uma saida explicita se o encerramento remoto falhar.
        }
      }
      rethrow;
    } finally {
      _profileValidationInProgress.value = false;
    }
  }

  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
    required String displayName,
    required String userType,
    String? specialty,
    String? professionalRegistration,
  }) async {
    _profileValidationInProgress.value = true;
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanDisplayName = displayName.trim();
      final resolvedUserType = userType == UserTypes.profissional
          ? UserTypes.profissional
          : UserTypes.paciente;

      final response = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        emailRedirectTo: SupabaseConfig.authRedirectUrl,
        data: {
          'display_name': cleanDisplayName,
          'tipo_usuario': resolvedUserType,
          if (specialty != null && specialty.trim().isNotEmpty)
            'especialidade': specialty.trim(),
          if (professionalRegistration != null &&
              professionalRegistration.trim().isNotEmpty)
            'registro_profissional': professionalRegistration.trim(),
        },
      );

      if (response.user != null && response.session != null) {
        if (resolvedUserType == UserTypes.profissional) {
          await _users.ensureForProfessionalAuthUser(
            response.user!,
            email: cleanEmail,
            displayName: cleanDisplayName,
          );
        } else {
          await _users.ensureForPatientAuthUser(
            response.user!,
            email: cleanEmail,
            displayName: cleanDisplayName,
          );
        }
      }

      return AuthSignUpResult(needsEmailConfirmation: response.session == null);
    } catch (_) {
      if (_client.auth.currentSession != null) {
        try {
          await _client.auth.signOut();
        } catch (_) {
          // Preserva a falha original de cadastro. O AuthGate continua
          // observando a sessao local e impede liberar o workspace antes da
          // validacao autoritativa terminar.
        }
      }
      rethrow;
    } finally {
      _profileValidationInProgress.value = false;
    }
  }

  Future<void> requestPasswordReset({required String email}) {
    return _client.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  Future<void> resendSignUpConfirmation({required String email}) {
    return _client.auth.resend(
      email: email.trim().toLowerCase(),
      type: OtpType.signup,
      emailRedirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  Future<void> updatePassword({required String password}) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  String? _displayNameFromMetadata(User user) {
    final value = user.userMetadata?['display_name'];

    if (value == null) {
      return null;
    }

    return value.toString();
  }
}

class AuthSignUpResult {
  final bool needsEmailConfirmation;

  const AuthSignUpResult({required this.needsEmailConfirmation});
}

class AccountTypeMismatchException implements Exception {
  const AccountTypeMismatchException({
    required this.expectedUserType,
    required this.actualUserType,
  });

  final String expectedUserType;
  final String? actualUserType;

  @override
  String toString() {
    return 'O tipo de conta não corresponde ao perfil selecionado.';
  }
}
