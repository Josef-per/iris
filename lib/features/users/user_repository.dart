import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  SupabaseClient get _client => SupabaseClientProvider.client;

  Future<String?> getCurrentUserType() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final existing = await _client
        .from(DatabaseTables.usuarios)
        .select('tipo_usuario')
        .eq('id', user.id)
        .limit(1)
        .maybeSingle();

    return existing?['tipo_usuario'] as String?;
  }

  Future<void> ensureSessionForAuthUser(
    User user, {
    String? email,
    String? displayName,
  }) async {
    final existingType = await getCurrentUserType();
    final userType = existingType ?? UserTypes.paciente;

    await _upsertUsuario(
      user,
      email: email,
      userType: userType,
    );
    await _ensureProfile(user.id, displayName);

    if (userType == UserTypes.profissional) {
      await _ensureProfessional(user.id);
      return;
    }

    await _ensurePatient(user.id);
  }

  Future<void> ensureForPatientAuthUser(
    User user, {
    String? email,
    String? displayName,
  }) async {
    await _upsertUsuario(
      user,
      email: email,
      userType: UserTypes.paciente,
    );
    await _ensureProfile(user.id, displayName);
    await _ensurePatient(user.id);
  }

  Future<String> getOrCreateCurrentPatientId() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Usuario nao autenticado.');
    }

    await ensureSessionForAuthUser(user);
    return _ensurePatient(user.id);
  }

  Future<String?> findCurrentPatientId() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return _findPatientId(user.id);
  }

  Future<String> getOrCreateCurrentProfessionalId() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Usuario nao autenticado.');
    }

    await ensureSessionForAuthUser(user);
    return _ensureProfessional(user.id);
  }

  Future<String?> findCurrentProfessionalId() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return _findProfessionalId(user.id);
  }

  Future<void> _upsertUsuario(
    User user, {
    String? email,
    required String userType,
  }) async {
    final resolvedEmail = email ?? user.email;

    if (resolvedEmail == null || resolvedEmail.trim().isEmpty) {
      throw Exception('Usuario autenticado sem email.');
    }

    await _client.from(DatabaseTables.usuarios).upsert({
      'id': user.id,
      'email': resolvedEmail.trim(),
      'senha_hash': 'managed_by_supabase_auth',
      'tipo_usuario': userType,
      'ativo': true,
      'atualizado_em': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  Future<void> _ensureProfile(String userId, String? displayName) async {
    final existing = await _client
        .from(DatabaseTables.perfis)
        .select('id')
        .eq('user_id', userId)
        .limit(1)
        .maybeSingle();

    final cleanDisplayName = displayName?.trim();

    if (existing == null) {
      await _client.from(DatabaseTables.perfis).insert({
        'user_id': userId,
        if (cleanDisplayName != null && cleanDisplayName.isNotEmpty)
          'nome_social': cleanDisplayName,
        if (cleanDisplayName != null && cleanDisplayName.isNotEmpty)
          'nome_completo': cleanDisplayName,
      });
      return;
    }

    if (cleanDisplayName != null && cleanDisplayName.isNotEmpty) {
      await _client
          .from(DatabaseTables.perfis)
          .update({
            'nome_social': cleanDisplayName,
            'nome_completo': cleanDisplayName,
          })
          .eq('id', existing['id'] as String);
    }
  }

  Future<String> _ensurePatient(String userId) async {
    final existing = await _findPatientId(userId);

    if (existing != null) {
      return existing;
    }

    final created = await _client
        .from(DatabaseTables.pacientes)
        .insert({'user_id': userId})
        .select('id')
        .single();

    return created['id'] as String;
  }

  Future<String?> _findPatientId(String userId) async {
    final existing = await _client
        .from(DatabaseTables.pacientes)
        .select('id')
        .eq('user_id', userId)
        .limit(1)
        .maybeSingle();

    return existing?['id'] as String?;
  }

  Future<String> _ensureProfessional(String userId) async {
    final existing = await _findProfessionalId(userId);

    if (existing != null) {
      return existing;
    }

    final created = await _client
        .from(DatabaseTables.profissionais)
        .insert({'user_id': userId})
        .select('id')
        .single();

    return created['id'] as String;
  }

  Future<String?> _findProfessionalId(String userId) async {
    final existing = await _client
        .from(DatabaseTables.profissionais)
        .select('id')
        .eq('user_id', userId)
        .limit(1)
        .maybeSingle();

    return existing?['id'] as String?;
  }
}
