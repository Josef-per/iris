/// Tipos de interação suportados pelo player genérico.
///
/// O player renderiza cada tipo de forma distinta e sempre oferece
/// “Pular esta etapa”. Nenhum tipo exige fechar os olhos, controlar a
/// respiração ou tocar o próprio corpo.
enum ExerciseStepType {
  /// Uma única escolha entre cartões.
  singleChoice,

  /// Marcar mais de um cartão.
  multiChoice,

  /// Completar uma frase com texto livre (reflexão em tela).
  textReflection,

  /// Encerramento informativo da prática.
  closing,
}

/// Uma instrução por tela, com no máximo uma decisão principal.
class ExerciseStep {
  const ExerciseStep({
    required this.type,
    required this.prompt,
    this.options = const <String>[],
    this.allowSkip = true,
    this.feedback,
    this.semanticsHint,
  });

  final ExerciseStepType type;

  /// Instrução curta exibida como título da etapa.
  final String prompt;

  /// Opções para [ExerciseStepType.singleChoice] e
  /// [ExerciseStepType.multiChoice].
  final List<String> options;

  /// Pular está sempre disponível para preservar o controle da pessoa; o
  /// campo existe para registrar etapas que não fazem sentido pular.
  final bool allowSkip;

  /// Feedback neutro e acolhedor, como “Etapa concluída” ou
  /// “Você percebeu isso agora”. Nunca julga a resposta.
  final String? feedback;

  /// Texto adicional para leitores de tela, quando o prompt não basta.
  final String? semanticsHint;
}