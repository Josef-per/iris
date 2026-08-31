/// Tópicos estruturados que o próprio paciente pode confirmar.
///
/// O texto livre do diário nunca é analisado para preencher estes códigos.
abstract final class EmotionalDiarySupportTopic {
  static const overload = 'overload';
  static const loneliness = 'loneliness';
  static const selfKindness = 'self_kindness';

  static const values = <String>{overload, loneliness, selfKindness};

  static bool isKnown(String code) => values.contains(code);

  /// Filtra defensivamente respostas da tabela `topicos_apoio`.
  ///
  /// Mesmo quando a consulta já aplica estes filtros no servidor, esta etapa
  /// impede que um registro recusado, invalidado ou expirado se torne sinal de
  /// personalização por engano.
  static Set<String> confirmedCodesFromRows(
    Iterable<Map<String, dynamic>> rows, {
    required DateTime now,
  }) {
    final result = <String>{};

    for (final row in rows) {
      final code = row['topico']?.toString().trim() ?? '';
      final expiresAt = DateTime.tryParse(row['expira_em']?.toString() ?? '');
      final isConfirmed = row['estado'] == 'confirmado';
      final isInvalidated = row['invalidado_em'] != null;

      if (isKnown(code) &&
          isConfirmed &&
          !isInvalidated &&
          expiresAt != null &&
          expiresAt.isAfter(now)) {
        result.add(code);
      }
    }

    return Set<String>.unmodifiable(result);
  }
}

/// Fronteira opcional para tópicos confirmados, separada do diário existente.
///
/// Fakes e consumidores de [EmotionalDiaryDataSource] não precisam implementar
/// esta capacidade até que queiram oferecer a seleção estruturada.
abstract interface class EmotionalDiarySupportTopicDataSource {
  Future<Set<String>> listConfirmedSupportTopics({
    required String emotionalRecordId,
  });

  Future<void> replaceConfirmedSupportTopics({
    required String emotionalRecordId,
    required Set<String> topicCodes,
  });
}
