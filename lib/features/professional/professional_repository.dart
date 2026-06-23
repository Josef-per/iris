import 'package:iris/core/qr/professional_qr_payload.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfessionalRepository {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final _users = UserRepository();

  Future<String> getCurrentProfessionalQrPayload() async {
    final profissionalId = await _users.getOrCreateCurrentProfessionalId();
    return ProfessionalQrPayload.build(profissionalId);
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
        .eq('status', PatientProfessionalStatus.ativo);

    return links.length;
  }
}
