import 'dart:convert';
import 'dart:math';

/// Estado de autorização observado no sistema operacional.
///
/// [notGranted] reúne os casos "ainda não solicitado" e "negado", porque as
/// APIs públicas de Android e iOS não permitem distingui-los de forma
/// consistente em todas as versões suportadas.
enum SupportNotificationPermissionStatus {
  unavailable,
  notGranted,
  provisional,
  granted;

  bool get allowsScheduling =>
      this == SupportNotificationPermissionStatus.granted ||
      this == SupportNotificationPermissionStatus.provisional;
}

/// Mensagens genéricas aprovadas para notificações do sistema.
///
/// O gateway não recebe texto arbitrário. A personalização detalhada fica
/// somente dentro do aplicativo autenticado.
enum SupportNotificationTemplate {
  gentlePause(
    id: 'notification_pause_gentle_v1',
    body: 'Uma pausa gentil, se fizer sentido.',
  ),
  supportSuggestion(
    id: 'notification_support_suggestion_v1',
    body: 'A Íris separou uma sugestão de apoio.',
  ),
  twoMinutes(
    id: 'notification_two_minutes_v1',
    body: 'Quer reservar dois minutos para você?',
  );

  const SupportNotificationTemplate({required this.id, required this.body});

  final String id;
  final String body;

  static SupportNotificationTemplate? tryFromId(String id) {
    for (final template in values) {
      if (template.id == id) return template;
    }
    return null;
  }
}

enum SupportNotificationPrivacy {
  /// Exibe somente o texto genérico aprovado.
  generic,

  /// Solicita ao sistema que esconda a notificação na tela bloqueada.
  hidden,
}

/// Pedido já aprovado pelas regras determinísticas da funcionalidade.
class SupportNotificationRequest {
  SupportNotificationRequest({
    required this.candidateId,
    required this.template,
    required this.scheduledAt,
    this.privacy = SupportNotificationPrivacy.generic,
  }) {
    if (!isValidSupportNotificationCandidateId(candidateId)) {
      throw ArgumentError.value(
        candidateId,
        'candidateId',
        'Use apenas um identificador opaco, sem URL, JSON ou conteúdo.',
      );
    }
  }

  /// Único valor colocado no payload da notificação.
  final String candidateId;
  final SupportNotificationTemplate template;
  final DateTime scheduledAt;
  final SupportNotificationPrivacy privacy;
}

typedef SupportNotificationOpenHandler = void Function(String candidateId);

/// Porta de infraestrutura para notificações locais de apoio.
///
/// A inicialização nunca pede permissão. [requestPermission] deve ser chamada
/// somente após uma ação explícita da pessoa, depois da explicação contextual.
abstract interface class SupportNotificationGateway {
  bool get isSupported;

  /// Inicializa callbacks e retorna o ID que abriu o app, quando houver.
  Future<String?> initialize({required SupportNotificationOpenHandler onOpen});

  Future<SupportNotificationPermissionStatus> permissionStatus();

  Future<SupportNotificationPermissionStatus> requestPermission();

  Future<bool> openSystemSettings();

  Future<void> schedule(SupportNotificationRequest request);

  Future<void> cancel(String candidateId);

  /// Remove somente notificações reconhecidas como pertencentes a esta
  /// funcionalidade, preservando lembretes de refeições e medicamentos.
  Future<void> cancelAllSupportNotifications();
}

final RegExp _candidateIdPattern = RegExp(r'^[A-Za-z0-9_-]{16,128}$');

bool isValidSupportNotificationCandidateId(String value) {
  return _candidateIdPattern.hasMatch(value);
}

/// Gera 128 bits aleatórios sem incluir horário, usuário ou sequência.
String generateOpaqueSupportNotificationCandidateId({Random? random}) {
  final secureRandom = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => secureRandom.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Faz parsing defensivo do payload sem aceitar envelopes ou texto adicional.
String? candidateIdFromSupportNotificationPayload(String? payload) {
  if (payload == null || !isValidSupportNotificationCandidateId(payload)) {
    return null;
  }
  return payload;
}
