import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  UserRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

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
    await _bootstrapCurrentUser(
      requestedType:
          existingType ?? _userTypeFromMetadata(user) ?? UserTypes.paciente,
      displayName: displayName ?? _displayNameFromMetadata(user),
      specialty: _metadataValue(user, 'especialidade'),
      professionalRegistration: _metadataValue(user, 'registro_profissional'),
    );
  }

  Future<void> ensureForProfessionalAuthUser(
    User user, {
    String? email,
    String? displayName,
  }) async {
    final userType = await _bootstrapCurrentUser(
      requestedType: UserTypes.profissional,
      displayName: displayName ?? _displayNameFromMetadata(user),
      specialty: _metadataValue(user, 'especialidade'),
      professionalRegistration: _metadataValue(user, 'registro_profissional'),
    );
    if (userType != UserTypes.profissional) {
      throw const UserRoleConflictException();
    }
  }

  Future<void> ensureForPatientAuthUser(
    User user, {
    String? email,
    String? displayName,
  }) async {
    final userType = await _bootstrapCurrentUser(
      requestedType: UserTypes.paciente,
      displayName: displayName ?? _displayNameFromMetadata(user),
    );
    if (userType != UserTypes.paciente) {
      throw const UserRoleConflictException();
    }
  }

  Future<String> getOrCreateCurrentPatientId() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Usuario nao autenticado.');
    }

    await ensureSessionForAuthUser(user);
    final pacienteId = await _findPatientId(user.id);
    if (pacienteId == null) {
      throw const UserRoleConflictException();
    }
    return pacienteId;
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
    final profissionalId = await _findProfessionalId(user.id);
    if (profissionalId == null) {
      throw const UserRoleConflictException();
    }
    return profissionalId;
  }

  Future<String?> findCurrentProfessionalId() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return _findProfessionalId(user.id);
  }

  Future<String> _bootstrapCurrentUser({
    required String requestedType,
    String? displayName,
    String? specialty,
    String? professionalRegistration,
  }) async {
    final result = await _client.rpc(
      'iris_bootstrap_current_user',
      params: {
        'p_display_name': _emptyToNull(displayName),
        'p_requested_type': requestedType,
        'p_specialty': _emptyToNull(specialty),
        'p_registration': _emptyToNull(professionalRegistration),
      },
    );
    return result.toString();
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

  Future<String?> _findProfessionalId(String userId) async {
    final existing = await _client
        .from(DatabaseTables.profissionais)
        .select('id')
        .eq('user_id', userId)
        .limit(1)
        .maybeSingle();

    return existing?['id'] as String?;
  }

  String? _userTypeFromMetadata(User user) {
    final metadata = user.userMetadata;
    final rawType = metadata?['tipo_usuario'] ?? metadata?['user_type'];
    final userType = rawType?.toString().trim().toLowerCase();

    if (userType == UserTypes.profissional) {
      return UserTypes.profissional;
    }
    if (userType == UserTypes.paciente) {
      return UserTypes.paciente;
    }
    return null;
  }

  String? _displayNameFromMetadata(User user) {
    return _metadataValue(user, 'display_name');
  }

  String? _metadataValue(User user, String key) {
    return _emptyToNull(user.userMetadata?[key]?.toString());
  }

  String? _emptyToNull(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

class UserRoleConflictException implements Exception {
  const UserRoleConflictException();

  @override
  String toString() => 'O perfil solicitado não corresponde à conta.';
}
