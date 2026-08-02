import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientProfessionalRepository {
  PatientProfessionalRepository({SupabaseClient? client, UserRepository? users})
    : _clientOverride = client,
      _users = users ?? UserRepository(client: client);

  final SupabaseClient? _clientOverride;
  final UserRepository _users;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  Future<bool> hasActiveProfessionalLink() async {
    final pacienteId = await _users.findCurrentPatientId();

    if (pacienteId == null) {
      return false;
    }

    final link = await _client
        .from(DatabaseTables.pacienteProfissional)
        .select('id')
        .eq('paciente_id', pacienteId)
        .eq('autorizacao_status', PatientProfessionalStatus.ativo)
        .limit(1)
        .maybeSingle();

    return link != null;
  }

  Future<ProfessionalInvitePreview> previewInvite(String inviteToken) async {
    await _users.getOrCreateCurrentPatientId();
    final response = await _client.rpc(
      'iris_preview_professional_invite',
      params: {'p_token': inviteToken.trim().toLowerCase()},
    );
    final row = _firstRow(response);
    return ProfessionalInvitePreview(
      professionalId: row['professional_id'] as String,
      name: row['professional_name'] as String,
      specialty: row['specialty'] as String?,
      expiresAt: DateTime.parse(row['expires_at'] as String).toLocal(),
    );
  }

  Future<ProfessionalLinkResult> linkCurrentPatientToProfessional(
    String inviteToken,
  ) async {
    await _users.getOrCreateCurrentPatientId();
    final response = await _client.rpc(
      'iris_redeem_professional_invite',
      params: {'p_token': inviteToken.trim().toLowerCase()},
    );
    final row = _firstRow(response);
    return ProfessionalLinkResult(
      linkId: row['link_id'] as String,
      professionalId: row['professional_id'] as String,
      name: row['professional_name'] as String,
      specialty: row['specialty'] as String?,
    );
  }

  Map<String, dynamic> _firstRow(dynamic response) {
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw const ProfessionalInviteException('Convite indisponível.');
  }
}

class ProfessionalInvitePreview {
  const ProfessionalInvitePreview({
    required this.professionalId,
    required this.name,
    required this.specialty,
    required this.expiresAt,
  });

  final String professionalId;
  final String name;
  final String? specialty;
  final DateTime expiresAt;
}

class ProfessionalLinkResult {
  const ProfessionalLinkResult({
    required this.linkId,
    required this.professionalId,
    required this.name,
    required this.specialty,
  });

  final String linkId;
  final String professionalId;
  final String name;
  final String? specialty;
}

class ProfessionalInviteException implements Exception {
  const ProfessionalInviteException(this.message);

  final String message;

  @override
  String toString() => message;
}
