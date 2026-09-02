/// Recorte mínimo do registro diário usado nas sugestões de apoio.
///
/// Texto livre, alimentação, sintomas e o rótulo textual de humor não fazem
/// parte deste modelo. A personalização recebe somente o check-in numérico e
/// os tópicos de apoio escolhidos pela própria pessoa.
class DailyEmotionalRecord {
  DailyEmotionalRecord({
    required this.id,
    required this.localDay,
    required this.recordedAt,
    DateTime? updatedAt,
    this.moodScore,
    Set<String> confirmedSupportTopicCodes = const <String>{},
  }) : updatedAt = updatedAt ?? recordedAt,
       confirmedSupportTopicCodes = Set<String>.unmodifiable(
         confirmedSupportTopicCodes,
       ) {
    _validateScore(moodScore, 'moodScore');
  }

  final String id;
  final DateTime localDay;
  final DateTime recordedAt;
  final DateTime updatedAt;
  final int? moodScore;

  /// Códigos de uma taxonomia fechada escolhidos e confirmados pelo paciente.
  final Set<String> confirmedSupportTopicCodes;

  factory DailyEmotionalRecord.fromMap(Map<String, dynamic> map) {
    final recordedAt = _requiredDate(
      map['data_registro'],
      field: 'data_registro',
    );

    return DailyEmotionalRecord(
      id: _requiredString(map['id'], field: 'id'),
      localDay: _requiredDate(map['data_local'], field: 'data_local'),
      recordedAt: recordedAt,
      updatedAt: _optionalDate(map['atualizado_em']) ?? recordedAt,
      moodScore: _optionalScore(map['como_sentiu'], field: 'como_sentiu'),
      confirmedSupportTopicCodes: _stringSet(map['topicos_apoio']),
    );
  }

  static String _requiredString(Object? value, {required String field}) {
    final parsed = value?.toString().trim() ?? '';
    if (parsed.isEmpty) {
      throw FormatException('Registro emocional sem $field válido.');
    }
    return parsed;
  }

  static DateTime _requiredDate(Object? value, {required String field}) {
    final parsed = _optionalDate(value);
    if (parsed == null) {
      throw FormatException('Registro emocional sem $field válido.');
    }
    return parsed;
  }

  static DateTime? _optionalDate(Object? value) {
    return DateTime.tryParse(value?.toString() ?? '');
  }

  static int? _optionalScore(Object? value, {required String field}) {
    if (value == null) return null;
    final parsed = value is int ? value : int.tryParse(value.toString());
    if (parsed == null || parsed < 1 || parsed > 5) {
      throw FormatException('Registro emocional com $field inválido.');
    }
    return parsed;
  }

  static Set<String> _stringSet(Object? value) {
    if (value is! List) return const <String>{};
    return <String>{
      for (final item in value)
        if (item?.toString().trim() case final code? when code.isNotEmpty) code,
    };
  }

  static void _validateScore(int? value, String field) {
    if (value != null && (value < 1 || value > 5)) {
      throw ArgumentError.value(value, field, 'Informe um valor entre 1 e 5.');
    }
  }
}
