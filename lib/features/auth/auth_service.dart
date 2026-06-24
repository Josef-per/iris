import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final _users = UserRepository();

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
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
    }
  }

  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanDisplayName = displayName.trim();

    final response = await _client.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {'display_name': cleanDisplayName},
    );

    if (response.user != null && response.session != null) {
      try {
        await _users.ensureForPatientAuthUser(
          response.user!,
          email: cleanEmail,
          displayName: cleanDisplayName,
        );
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
