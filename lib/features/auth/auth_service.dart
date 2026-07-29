import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final _users = UserRepository();

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({
    required String email,
    required String password,
    required String expectedUserType,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final response = await _client.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );
    final user = response.user ?? _client.auth.currentUser;

    if (user != null) {
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
    final cleanEmail = email.trim().toLowerCase();
    final cleanDisplayName = displayName.trim();
    final resolvedUserType = userType == UserTypes.profissional
        ? UserTypes.profissional
        : UserTypes.paciente;

    final response = await _client.auth.signUp(
      email: cleanEmail,
      password: password,
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
      try {
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
      } catch (error) {
        await _client.auth.signOut();
        rethrow;
      }
    }

    return AuthSignUpResult(needsEmailConfirmation: response.session == null);
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
    return 'O tipo de conta nao corresponde ao perfil selecionado.';
  }
}
