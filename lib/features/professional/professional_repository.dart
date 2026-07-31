import 'package:iris/core/qr/professional_qr_payload.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfessionalRepository {
  ProfessionalRepository({SupabaseClient? client, UserRepository? users})
    : _clientOverride = client,
      _users = users ?? UserRepository(client: client);

  final SupabaseClient? _clientOverride;
  final UserRepository _users;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  Future<String> getCurrentProfessionalQrPayload() async {
    final invite = await createLinkInvite();
    return invite.payload;
  }

  Future<ProfessionalLinkInvite> createLinkInvite({
    int ttlMinutes = 30,
    int maxUses = 1,
  }) async {
    await _users.getOrCreateCurrentProfessionalId();
    final response = await _client.rpc(
      'iris_create_professional_invite',
      params: {'p_ttl_minutes': ttlMinutes, 'p_max_uses': maxUses},
    );
    final row = _firstRow(response);
    final token = row['token'] as String;
    return ProfessionalLinkInvite(
      id: row['invite_id'] as String,
      token: token,
      payload: ProfessionalQrPayload.build(token),
      expiresAt: DateTime.parse(row['expires_at'] as String).toLocal(),
    );
  }

  Future<void> revokeLinkInvite(String inviteId) async {
    await _client.rpc(
      'iris_revoke_professional_invite',
      params: {'p_invite_id': inviteId},
    );
  }

  Future<int> countLinkedPatients() async {
    final profissionalId = await _users.findCurrentProfessionalId();

    if (profissionalId == null) {
      return 0;
    }

    final links = await _client
        .from(DatabaseTables.pacienteProfissional)
        .select('id')
        .eq('profissional_id', profissionalId)
        .eq('autorizacao_status', PatientProfessionalStatus.ativo);

    return links.length;
  }

  Map<String, dynamic> _firstRow(dynamic response) {
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw const ProfessionalBackendException('Resposta inválida do servidor.');
  }
}

class ProfessionalLinkInvite {
  const ProfessionalLinkInvite({
    required this.id,
    required this.token,
    required this.payload,
    required this.expiresAt,
  });

  final String id;
  final String token;
  final String payload;
  final DateTime expiresAt;
}

class ProfessionalBackendException implements Exception {
  const ProfessionalBackendException(this.message);

  final String message;

  @override
  String toString() => message;
}
