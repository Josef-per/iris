/// Fontes estruturadas que podem participar das sugestões de apoio.
///
/// Texto livre do diário não faz parte desta enumeração e, portanto, não pode
/// ser habilitado por esta camada do protótipo.
enum SupportSignalSource {
  moodHistory,
  diaryTags,
  exerciseFeedback,
  notificationInteractions,
}

/// Consentimento granular para a personalização local.
///
/// A permissão do sistema operacional não é representada aqui: ela é
/// independente do consentimento para usar sinais de saúde.
class AiSupportConsent {
  const AiSupportConsent({
    this.personalizedSuggestionsGranted = false,
    this.grantedSources = const <SupportSignalSource>{},
  });

  static const AiSupportConsent none = AiSupportConsent();

  /// Autoriza sugestões personalizadas em geral.
  final bool personalizedSuggestionsGranted;

  /// Fontes autorizadas individualmente. Todas começam desligadas.
  final Set<SupportSignalSource> grantedSources;

  bool allowsSource(SupportSignalSource source) {
    return personalizedSuggestionsGranted && grantedSources.contains(source);
  }

  AiSupportConsent copyWith({
    bool? personalizedSuggestionsGranted,
    Set<SupportSignalSource>? grantedSources,
  }) {
    return AiSupportConsent(
      personalizedSuggestionsGranted:
          personalizedSuggestionsGranted ?? this.personalizedSuggestionsGranted,
      grantedSources: grantedSources ?? this.grantedSources,
    );
  }

  AiSupportConsent grantSource(SupportSignalSource source) {
    return copyWith(
      grantedSources: <SupportSignalSource>{...grantedSources, source},
    );
  }

  AiSupportConsent revokeSource(SupportSignalSource source) {
    return copyWith(
      grantedSources: <SupportSignalSource>{...grantedSources}..remove(source),
    );
  }

  AiSupportConsent revokeAll() => const AiSupportConsent();
}
