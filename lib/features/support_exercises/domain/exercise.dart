import 'exercise_step.dart';
import 'recommendation_context.dart';

/// Situação de revisão clínica do conteúdo. Somente itens
/// [ExerciseReviewStatus.clinicallyReviewed] podem sair do modo demonstração.
enum ExerciseReviewStatus { draft, clinicallyReviewed, retired }

/// Marcadores de segurança usados por regras determinísticas do recomendador
/// e por validações de conteúdo.
enum ExerciseSafetyTag {
  /// A prática conduz o foco para o controle da respiração.
  breathingFocus,

  /// A prática pede que a pessoa feche os olhos.
  closingEyes,

  /// A prática pede contato com o próprio corpo.
  bodyTouch,

  /// A prática exige áudio para ser concluída.
  audioRequired,
}

/// Exercício fictício do catálogo demonstração.
///
/// Todo conteúdo carrega autoria, fonte conceitual, revisão clínica, versão,
/// data da próxima revisão e contraindicações, mesmo que o paciente não veja
/// todos esses campos.
class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    required this.goal,
    required this.durationMinutes,
    required this.supportedFormats,
    required this.needs,
    required this.steps,
    this.safetyTags = const <ExerciseSafetyTag>{},
    required this.author,
    required this.conceptualSource,
    required this.clinicalReviewer,
    required this.version,
    required this.nextReviewDate,
    this.contraindications = const <String>[],
    this.reviewStatus = ExerciseReviewStatus.clinicallyReviewed,
    this.isPreview = false,
  });

  final String id;
  final String title;
  final String goal;

  /// Duração aproximada da prática completa, em minutos.
  final int durationMinutes;

  /// Formatos em que a prática pode ser feita (interativo e/ou áudio).
  final Set<SupportFormat> supportedFormats;

  /// Necessidades atendidas pela prática.
  final List<SupportNeed> needs;

  /// Etapas do player, uma instrução por tela.
  final List<ExerciseStep> steps;

  final Set<ExerciseSafetyTag> safetyTags;

  /// Autoria fictícia do protótipo.
  final String author;

  /// Fonte conceitual (não licenciada; roteiro próprio).
  final String conceptualSource;

  /// Revisão clínica fictícia do protótipo.
  final String clinicalReviewer;

  final String version;

  /// Data da próxima revisão (formato ISO, demonstração).
  final String nextReviewDate;

  final List<String> contraindications;

  final ExerciseReviewStatus reviewStatus;

  /// Prévia não recomendada fora do protótipo; visível no catálogo.
  final bool isPreview;

  bool get focusesOnBreathing =>
      safetyTags.contains(ExerciseSafetyTag.breathingFocus);

  bool supportsFormat(SupportFormat format) => supportedFormats.contains(format);
}