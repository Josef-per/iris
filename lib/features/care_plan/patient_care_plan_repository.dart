import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/care_plan/patient_care_plan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class PatientCarePlanDataSource {
  Future<List<PatientCarePlan>> listSharedPlans();
}

class PatientCarePlanRepository implements PatientCarePlanDataSource {
  PatientCarePlanRepository({SupabaseClient? client})
    : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  @override
  Future<List<PatientCarePlan>> listSharedPlans() async {
    // O plano de cuidado é único por paciente: um único vínculo autorizado
    // está ativo por vez. Bancos legados podem manter vínculos duplicados,
    // cada um com o próprio plano; retorna apenas o mais recente para não
    // duplicar as orientações exibidas ao paciente.
    final planRows = await _client
        .from(DatabaseTables.planosCuidado)
        .select(
          'id, orientacoes, passos_crise, compartilhar_paciente, atualizado_em',
        )
        .eq('compartilhar_paciente', true)
        .order('atualizado_em', ascending: false)
        .order('id', ascending: false)
        .limit(1);

    if (planRows.isEmpty) {
      return [];
    }

    final planIds = planRows
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .toList(growable: false);
    final childRows = await Future.wait([
      _client
          .from(DatabaseTables.metasCuidado)
          .select('id, plano_id, descricao, concluida, ordem')
          .inFilter('plano_id', planIds)
          .order('ordem'),
      _client
          .from(DatabaseTables.medicacoesPlano)
          .select('id, plano_id, nome, dose, frequencia, ordem')
          .inFilter('plano_id', planIds)
          .order('ordem'),
    ]);
    final goalRows = childRows[0];
    final medicationRows = childRows[1];

    return planRows
        .map((row) {
          final id = row['id']?.toString();
          final updatedAt = DateTime.tryParse(
            row['atualizado_em']?.toString() ?? '',
          );
          if (id == null || id.isEmpty || updatedAt == null) {
            throw const FormatException(
              'Plano de cuidado com dados inválidos.',
            );
          }

          return PatientCarePlan(
            id: id,
            guidance: _optionalText(row['orientacoes']),
            crisisSteps: _textList(row['passos_crise']),
            goals:
                [
                      for (final goal in goalRows)
                        if (goal['plano_id']?.toString() == id)
                          PatientCareGoal(
                            id: goal['id'].toString(),
                            description:
                                goal['descricao']?.toString().trim() ?? '',
                            isCompleted: goal['concluida'] == true,
                          ),
                    ]
                    .where((goal) => goal.description.isNotEmpty)
                    .toList(growable: false),
            medications:
                [
                      for (final medication in medicationRows)
                        if (medication['plano_id']?.toString() == id)
                          PatientCareMedication(
                            id: medication['id'].toString(),
                            name: medication['nome']?.toString().trim() ?? '',
                            dose: medication['dose']?.toString().trim() ?? '',
                            frequency:
                                medication['frequencia']?.toString().trim() ??
                                '',
                          ),
                    ]
                    .where((medication) => medication.name.isNotEmpty)
                    .toList(growable: false),
            updatedAt: updatedAt.toLocal(),
          );
        })
        .toList(growable: false);
  }

  String? _optionalText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  List<String> _textList(Object? value) {
    if (value is! List) {
      return [];
    }
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
