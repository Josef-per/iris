import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final _users = UserRepository();

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user ?? _client.auth.currentUser;

    if (user != null) {
      await _users.ensureForAuthUser(user, email: email);
    }
  }

  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );

    // If a user object was returned, ensure app records exist for them
    // even when `response.session` is null (email confirmation required).
    // This allows the app to proceed without waiting for the confirmation
    // email flow (useful when you don't want to require email validation).
    if (response.user != null) {
      try {
        await _users.ensureForAuthUser(
          response.user!,
          email: email,
          displayName: displayName,
        );
      } catch (_) {
        // Swallow errors from user creation to preserve original signUp behavior
        // (e.g., in case email is missing). The caller still gets the signup result.
      }
    }

    return AuthSignUpResult(needsEmailConfirmation: response.session == null);
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}

class AuthSignUpResult {
  final bool needsEmailConfirmation;

  const AuthSignUpResult({required this.needsEmailConfirmation});
}
