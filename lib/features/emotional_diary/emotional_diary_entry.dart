class EmotionalDiaryEntry {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  const EmotionalDiaryEntry({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory EmotionalDiaryEntry.fromMap(Map<String, dynamic> map) {
    final patient = map['pacientes'];
    final patientUserId = patient is Map<String, dynamic>
        ? patient['user_id']
        : null;

    final rawCreatedAt =
        map['data_registro'] ??
        map['created_at'] ??
        map['criado_em'] ??
        map['data_criacao'];
    final createdAt = DateTime.tryParse(rawCreatedAt?.toString() ?? '');
    if (createdAt == null) {
      throw const FormatException('Registro emocional sem data válida.');
    }

    return EmotionalDiaryEntry(
      id: map['id'] as String,
      userId:
          (map['user_id'] ??
                  patientUserId ??
                  map['usuario_id'] ??
                  map['id_usuario'] ??
                  map['auth_user_id'] ??
                  '')
              as String,
      content:
          (map['diario_emocional'] ??
                  map['conteudo'] ??
                  map['texto'] ??
                  map['descricao'] ??
                  map['observacao'] ??
                  map['content'] ??
                  '')
              as String,
      createdAt: createdAt,
    );
  }
}
