/// Sessão de uma prática, mantida somente em memória.
///
/// Este objeto NÃO é prontuário: ao fechar o fluxo, tudo aqui é descartado e
/// nada é persistido ou enviado. As respostas existem apenas para o player
/// navegar pelas etapas durante a sessão.
class SupportSession {
  SupportSession({
    required this.exerciseId,
    required this.exerciseTitle,
    required this.durationMinutes,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  final String exerciseId;
  final String exerciseTitle;
  final int durationMinutes;
  final DateTime startedAt;

  /// Respostas por índice de etapa (ex.: respostas de cartões, frases).
  final Map<int, List<String>> answers = <int, List<String>>{};

  /// Etapa atual; a retomada acontece somente dentro desta sessão.
  int currentStepIndex = 0;
}