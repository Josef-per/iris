/// Fontes estruturadas que podem participar das sugestões de apoio.
///
/// `diaryText` exige um consentimento separado: ele pode ser enviado somente
/// para a reflexão diária no servidor e nunca vira um sinal local ou uma tag
/// inferida. As outras fontes continuam estruturadas.
enum SupportSignalSource {
  moodHistory,
  diaryTags,
  diaryText,
  exerciseFeedback,
  notificationInteractions,
}

/// Fontes realmente conectadas na experiência do paciente.
///
/// Feedback de exercício permanece disponível somente no modo de demonstração
/// até o fluxo de práticas persistir essa resposta de ponta a ponta.
const connectedAiSupportSources = <SupportSignalSource>{
  SupportSignalSource.moodHistory,
  SupportSignalSource.diaryTags,
  SupportSignalSource.diaryText,
  SupportSignalSource.notificationInteractions,
};

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
