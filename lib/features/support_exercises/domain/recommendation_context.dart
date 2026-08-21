/// Necessidades que a pessoa pode escolher no momento de apoio.
enum SupportNeed {
  present,
  difficultThought,
  nameFeelings,
  selfKindness,
  nextSafeStep,
  notSure;

  String get label => switch (this) {
    SupportNeed.present => 'Voltar para o presente',
    SupportNeed.difficultThought => 'Lidar com um pensamento difícil',
    SupportNeed.nameFeelings => 'Dar nome ao que sinto',
    SupportNeed.selfKindness => 'Ser mais gentil comigo',
    SupportNeed.nextSafeStep => 'Dar um próximo passo seguro',
    SupportNeed.notSure => 'Não sei — escolha algo simples',
  };

  String get description => switch (this) {
    SupportNeed.present =>
      'Acalmar e aterrar com o que está ao seu redor agora.',
    SupportNeed.difficultThought =>
      'Criar um pouco de distância de um pensamento difícil.',
    SupportNeed.nameFeelings =>
      'Reconhecer e dar nome ao que está presente.',
    SupportNeed.selfKindness =>
      'Falar com você com a gentileza que ofereceria a alguém querido.',
    SupportNeed.nextSafeStep =>
      'Escolher uma ação pequena e segura para o momento.',
    SupportNeed.notSure =>
      'Sem problema — deixe que escolhamos algo simples.',
  };
}

/// Tempo disponível declarado pela pessoa.
enum SupportTime {
  minutes1_2,
  minutes3,
  minutes5;

  String get label => switch (this) {
    SupportTime.minutes1_2 => '1–2 min',
    SupportTime.minutes3 => '3 min',
    SupportTime.minutes5 => '5 min',
  };

  int get maxMinutes => switch (this) {
    SupportTime.minutes1_2 => 2,
    SupportTime.minutes3 => 3,
    SupportTime.minutes5 => 5,
  };

  String get spokenLabel => switch (this) {
    SupportTime.minutes1_2 => '1 a 2 minutos',
    SupportTime.minutes3 => '3 minutos',
    SupportTime.minutes5 => '5 minutos',
  };
}

/// Formato preferido para a prática.
enum SupportFormat {
  interactive,
  audio,
  video;

  String get label => switch (this) {
    SupportFormat.interactive => 'Interativo',
    SupportFormat.audio => 'Ouvir',
    SupportFormat.video => 'Assistir',
  };

  String get spokenLabel => switch (this) {
    SupportFormat.interactive => 'interativo',
    SupportFormat.audio => 'para ouvir',
    SupportFormat.video => 'para assistir',
  };
}

/// Preferências sensoriais declaradas em “Ajustar”.
///
/// O app nunca deve obrigar a fechar os olhos, controlar a respiração ou
/// tocar o próprio corpo; as preferências apenas reduzem o que é oferecido.
class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.noAnimation = false,
    this.noSound = false,
    this.avoidBreathing = false,
    this.largerText = false,
  });

  final bool noAnimation;
  final bool noSound;
  final bool avoidBreathing;
  final bool largerText;

  AccessibilityPreferences copyWith({
    bool? noAnimation,
    bool? noSound,
    bool? avoidBreathing,
    bool? largerText,
  }) {
    return AccessibilityPreferences(
      noAnimation: noAnimation ?? this.noAnimation,
      noSound: noSound ?? this.noSound,
      avoidBreathing: avoidBreathing ?? this.avoidBreathing,
      largerText: largerText ?? this.largerText,
    );
  }

  /// Frases usadas na explicação da sugestão.
  List<String> get explanationNotes {
    final notes = <String>[];
    if (avoidBreathing) notes.add('sem foco na respiração');
    if (noSound) notes.add('sem som');
    if (noAnimation) notes.add('sem animação');
    if (largerText) notes.add('com texto maior');
    return notes;
  }
}

/// Contexto estruturado usado pelo recomendador. Nunca contém texto livre ou
/// diagnóstico; as respostas da sessão ficam apenas em memória.
class RecommendationContext {
  const RecommendationContext({
    required this.need,
    required this.time,
    required this.format,
    this.preferences = const AccessibilityPreferences(),
  });

  final SupportNeed need;
  final SupportTime time;
  final SupportFormat format;
  final AccessibilityPreferences preferences;
}

/// Saída do recomendador simulado: identificador de conteúdo e motivo.
///
/// A rota de urgência nunca passa por este objeto.
class ExerciseRecommendation {
  const ExerciseRecommendation({
    required this.contentId,
    required this.explanation,
  });

  final String contentId;
  final String explanation;
}