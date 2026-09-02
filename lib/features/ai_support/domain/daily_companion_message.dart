enum DailyCompanionStatus {
  ready,
  waitingForContext,
  notEnabled,
  notAvailable,
  needsHumanSupport,
}

/// Uma reflexao curta mostrada somente dentro do aplicativo.
///
/// Ela nao e uma avaliacao clinica: a interface usa [needsHumanSupport] para
/// oferecer uma rota de apoio humano, sem transformar a mensagem em alerta ou
/// alegar monitoramento continuo.
class DailyCompanionMessage {
  const DailyCompanionMessage({
    required this.status,
    this.title,
    this.message,
    this.reflectionQuestion,
  });

  final DailyCompanionStatus status;
  final String? title;
  final String? message;
  final String? reflectionQuestion;

  bool get isPersonalized => status == DailyCompanionStatus.ready;
  bool get needsHumanSupport => status == DailyCompanionStatus.needsHumanSupport;
}
