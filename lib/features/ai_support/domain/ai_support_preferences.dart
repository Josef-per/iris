import 'notification_preferences.dart';

/// Categorias fechadas que o recomendador pode selecionar.
enum SupportSuggestionCategory {
  reflection,
  exercise,
  video,
  humanConnection,
  professionalConversation,
}

/// Características de conteúdo que uma pessoa pode optar por evitar.
enum SupportContentTag { breathingFocused, audioRequired, animation, bodyTouch }

extension SupportContentTagLabel on SupportContentTag {
  String get label => switch (this) {
    SupportContentTag.breathingFocused => 'Foco na respiração',
    SupportContentTag.audioRequired => 'Áudio necessário',
    SupportContentTag.animation => 'Animação',
    SupportContentTag.bodyTouch => 'Contato com o corpo',
  };
}

/// Preferências de conteúdo e de entrega para as sugestões de apoio.
class AiSupportPreferences {
  const AiSupportPreferences({
    this.personalizedSuggestionsEnabled = false,
    this.allowedCategories = const <SupportSuggestionCategory>{},
    this.maximumExerciseMinutes = 2,
    this.excludedContentTags = const <SupportContentTag>{},
    this.notifications = const NotificationPreferences(),
  }) : assert(maximumExerciseMinutes > 0);

  static const AiSupportPreferences defaults = AiSupportPreferences();

  final bool personalizedSuggestionsEnabled;
  final Set<SupportSuggestionCategory> allowedCategories;
  final int maximumExerciseMinutes;
  final Set<SupportContentTag> excludedContentTags;
  final NotificationPreferences notifications;

  bool allowsCategory(SupportSuggestionCategory category) {
    return allowedCategories.contains(category);
  }

  bool allowsContentTags(Set<SupportContentTag> contentTags) {
    return contentTags.intersection(excludedContentTags).isEmpty;
  }

  AiSupportPreferences copyWith({
    bool? personalizedSuggestionsEnabled,
    Set<SupportSuggestionCategory>? allowedCategories,
    int? maximumExerciseMinutes,
    Set<SupportContentTag>? excludedContentTags,
    NotificationPreferences? notifications,
  }) {
    return AiSupportPreferences(
      personalizedSuggestionsEnabled:
          personalizedSuggestionsEnabled ?? this.personalizedSuggestionsEnabled,
      allowedCategories: allowedCategories ?? this.allowedCategories,
      maximumExerciseMinutes:
          maximumExerciseMinutes ?? this.maximumExerciseMinutes,
      excludedContentTags: excludedContentTags ?? this.excludedContentTags,
      notifications: notifications ?? this.notifications,
    );
  }
}

/// Nome curto útil para telas que não precisam mencionar a implementação.
typedef SupportPreferences = AiSupportPreferences;
