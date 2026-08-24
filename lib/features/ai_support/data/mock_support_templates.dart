import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';

/// Texto genérico aprovado para a simulação de tela bloqueada.
class GenericNotificationTemplate {
  const GenericNotificationTemplate({required this.id, required this.text});

  final String id;
  final String text;
}

/// Contrato de leitura do catálogo fechado usado por validadores e políticas.
abstract interface class SupportCatalog {
  SupportSuggestionTemplate? templateById(String id);
  SupportExerciseReference? exerciseById(String id);
  GenericNotificationTemplate? genericNotificationById(String id);
}

/// Catálogo pequeno, local e fictício para a Fase 1.
///
/// Os textos são estáticos e revisados; dados da pessoa nunca são interpolados
/// em notificações nem em templates nesta camada.
class MockSupportCatalog implements SupportCatalog {
  const MockSupportCatalog({
    this.templates = MockSupportTemplateCatalog.templates,
    this.exercises = MockSupportTemplateCatalog.exercises,
    this.genericNotifications = MockSupportTemplateCatalog.genericNotifications,
  });

  final List<SupportSuggestionTemplate> templates;
  final List<SupportExerciseReference> exercises;
  final List<GenericNotificationTemplate> genericNotifications;

  @override
  SupportSuggestionTemplate? templateById(String id) {
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  @override
  SupportExerciseReference? exerciseById(String id) {
    for (final exercise in exercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  @override
  GenericNotificationTemplate? genericNotificationById(String id) {
    for (final template in genericNotifications) {
      if (template.id == id) return template;
    }
    return null;
  }
}

abstract final class MockSupportTemplateCatalog {
  static const List<GenericNotificationTemplate> genericNotifications =
      <GenericNotificationTemplate>[
        GenericNotificationTemplate(
          id: 'notification_pause_gentle_v1',
          text: 'Uma pausa gentil, se fizer sentido.',
        ),
        GenericNotificationTemplate(
          id: 'notification_support_suggestion_v1',
          text: 'A Íris separou uma sugestão de apoio.',
        ),
        GenericNotificationTemplate(
          id: 'notification_two_minutes_v1',
          text: 'Quer reservar dois minutos para você?',
        ),
      ];

  /// IDs compatíveis com o catálogo local de exercícios já existente.
  static const List<SupportExerciseReference> exercises =
      <SupportExerciseReference>[
        SupportExerciseReference(
          id: 'anchor-present',
          status: SupportContentStatus.approved,
          durationMinutes: 2,
        ),
        SupportExerciseReference(
          id: 'notice-and-name',
          status: SupportContentStatus.approved,
          durationMinutes: 3,
        ),
        SupportExerciseReference(
          id: 'retired-exercise',
          status: SupportContentStatus.retired,
          durationMinutes: 2,
        ),
      ];

  static const List<SupportSuggestionTemplate>
  templates = <SupportSuggestionTemplate>[
    SupportSuggestionTemplate(
      id: 'reflection_difficult_checkins_v1',
      category: SupportSuggestionCategory.reflection,
      version: '1.0-demo',
      status: SupportContentStatus.approved,
      inAppTitle: 'Uma pergunta breve, se fizer sentido',
      inAppBody: 'O que tornou este momento um pouco mais suportável?',
      genericNotificationTemplateId: 'notification_pause_gentle_v1',
      allowedReasonCodes: <SupportReasonCode>{
        SupportReasonCode.recentDifficultCheckIns,
      },
      approvedBy: 'Revisão clínica fictícia — Fase 1',
    ),
    SupportSuggestionTemplate(
      id: 'exercise_difficult_checkins_v1',
      category: SupportSuggestionCategory.exercise,
      version: '1.0-demo',
      status: SupportContentStatus.approved,
      inAppTitle: 'Uma prática curta pode estar disponível',
      inAppBody:
          'Você gostaria de experimentar “Ancorar no presente” por cerca de 2 minutos?',
      genericNotificationTemplateId: 'notification_pause_gentle_v1',
      allowedReasonCodes: <SupportReasonCode>{
        SupportReasonCode.recentDifficultCheckIns,
        SupportReasonCode.prefersShortPractice,
      },
      exerciseId: 'anchor-present',
      approvedBy: 'Revisão clínica fictícia — Fase 1',
    ),
    SupportSuggestionTemplate(
      id: 'reflection_overload_v1',
      category: SupportSuggestionCategory.reflection,
      version: '1.0-demo',
      status: SupportContentStatus.approved,
      inAppTitle: 'Um espaço para notar o que você precisa',
      inAppBody:
          'O que você percebe que precisa agora: pausa, companhia ou espaço?',
      genericNotificationTemplateId: 'notification_support_suggestion_v1',
      allowedReasonCodes: <SupportReasonCode>{
        SupportReasonCode.confirmedOverload,
      },
      approvedBy: 'Revisão clínica fictícia — Fase 1',
    ),
    SupportSuggestionTemplate(
      id: 'connection_loneliness_v1',
      category: SupportSuggestionCategory.humanConnection,
      version: '1.0-demo',
      status: SupportContentStatus.approved,
      inAppTitle: 'Conexão pode ser uma opção',
      inAppBody:
          'Se fizer sentido, você gostaria de procurar alguém seguro da sua rede de apoio?',
      genericNotificationTemplateId: 'notification_support_suggestion_v1',
      allowedReasonCodes: <SupportReasonCode>{
        SupportReasonCode.confirmedLoneliness,
      },
      approvedBy: 'Revisão clínica fictícia — Fase 1',
    ),
    SupportSuggestionTemplate(
      id: 'connection_after_exercise_feedback_v1',
      category: SupportSuggestionCategory.humanConnection,
      version: '1.0-demo',
      status: SupportContentStatus.approved,
      inAppTitle: 'Outra forma de apoio pode fazer sentido',
      inAppBody:
          'Se fizer sentido, considere conversar com alguém que seja seguro para você.',
      genericNotificationTemplateId: 'notification_two_minutes_v1',
      allowedReasonCodes: <SupportReasonCode>{
        SupportReasonCode.previousExerciseWasNotHelpful,
      },
      approvedBy: 'Revisão clínica fictícia — Fase 1',
    ),
    SupportSuggestionTemplate(
      id: 'reflection_retired_v1',
      category: SupportSuggestionCategory.reflection,
      version: '0.9-demo',
      status: SupportContentStatus.retired,
      inAppTitle: 'Conteúdo retirado',
      inAppBody: 'Este template não deve ser mostrado.',
      genericNotificationTemplateId: 'notification_pause_gentle_v1',
      allowedReasonCodes: <SupportReasonCode>{
        SupportReasonCode.confirmedOverload,
      },
      approvedBy: 'Revisão clínica fictícia — Fase 1',
    ),
  ];

  static const MockSupportCatalog catalog = MockSupportCatalog();
}
