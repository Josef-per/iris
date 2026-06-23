import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/features/profile/profile_model.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final _users = UserRepository();

  Future<Profile?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    await _users.ensureSessionForAuthUser(user);

    final data = await _client
        .from(DatabaseTables.perfis)
        .select('id, user_id, nome_completo, nome_social')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return Profile.fromMap(data);
  }

  Future<void> upsertProfile(Profile profile) async {
    await _client
        .from(DatabaseTables.perfis)
        .update({
          'nome_social': profile.displayName,
          'nome_completo': profile.displayName,
        })
        .eq('id', profile.id);
  }
}
