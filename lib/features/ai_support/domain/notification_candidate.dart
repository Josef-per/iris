import 'support_suggestion.dart';

/// Candidato para o simulador de notificação.
///
/// Ele armazena somente IDs opacos e o ID de um template genérico aprovado.
/// Não representa push, deep link real ou permissão do sistema.
class NotificationCandidate {
  const NotificationCandidate({
    required this.id,
    required this.suggestionId,
    required this.templateId,
    required this.genericNotificationTemplateId,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String suggestionId;
  final String templateId;
  final String genericNotificationTemplateId;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}

/// Registro exclusivamente local da entrega no simulador.
class NotificationDeliveryRecord {
  const NotificationDeliveryRecord({
    required this.candidateId,
    required this.suggestionId,
    required this.templateId,
    required this.deliveredAt,
  });

  final String candidateId;
  final String suggestionId;
  final String templateId;
  final DateTime deliveredAt;
}

/// Cria um candidato a partir de uma sugestão sem copiar conteúdo sensível.
NotificationCandidate notificationCandidateForSuggestion(
  SupportSuggestion suggestion, {
  required String candidateId,
  required String genericNotificationTemplateId,
}) {
  return NotificationCandidate(
    id: candidateId,
    suggestionId: suggestion.id,
    templateId: suggestion.templateId,
    genericNotificationTemplateId: genericNotificationTemplateId,
    createdAt: suggestion.createdAt,
    expiresAt: suggestion.expiresAt,
  );
}
