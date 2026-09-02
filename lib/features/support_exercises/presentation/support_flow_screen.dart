import 'package:flutter/material.dart';
import 'package:iris/features/support_exercises/data/mock_exercise_catalog.dart';
import 'package:iris/features/support_exercises/data/mock_exercise_recommender.dart';
import 'package:iris/features/support_exercises/data/mock_video_catalog.dart';
import 'package:iris/features/support_exercises/domain/exercise.dart';
import 'package:iris/features/support_exercises/domain/recommendation_context.dart';
import 'package:iris/features/support_exercises/domain/support_session.dart';
import 'package:iris/features/support_exercises/presentation/exercise_player_view.dart';
import 'package:iris/features/support_exercises/presentation/immediate_help_view.dart';
import 'package:iris/features/support_exercises/presentation/need_picker_view.dart';
import 'package:iris/features/support_exercises/presentation/recommendation_view.dart';
import 'package:iris/features/support_exercises/presentation/safety_check_view.dart';
import 'package:iris/features/support_exercises/presentation/support_checkout_view.dart';
import 'package:iris/features/support_exercises/presentation/support_phone_launcher.dart';
import 'package:iris/features/support_exercises/presentation/video_library_view.dart';
import 'package:iris/features/support_exercises/presentation/widgets/option_card.dart';
import 'package:iris/features/support_exercises/presentation/widgets/persistent_help_action.dart';

/// Ponto de entrada do fluxo de apoio.
enum SupportFlowStart {
  /// Entrada “Exercícios” da Home: abre direto o catálogo.
  catalog,

  /// Entrada “Não estou bem” da Home: abre o menu de apoio em tela cheia.
  supportMenu,

  /// Atalho explícito para a rede de apoio. Não seleciona nem aciona contatos.
  supportNetwork,

  /// Atalho explícito para a checagem de ajuda urgente.
  safetyCheck,
}

/// Shell em tela cheia do fluxo de apoio.
///
/// O cabeçalho mantém “Sair” e “Ajuda urgente” visíveis em todas as etapas;
/// a sessão existe somente em memória e é descartada ao sair. Nenhum CTA
/// afirma ter enviado ou salvo algo.
class SupportFlowScreen extends StatefulWidget {
  const SupportFlowScreen({
    super.key,
    this.start = SupportFlowStart.supportMenu,
    this.initialExerciseId,
    this.recommender,
    this.phoneLauncher = defaultPhoneLauncher,
  });

  final SupportFlowStart start;

  /// Quando informado por uma sugestão aprovada, abre diretamente a prática.
  /// A rota continua mostrando “Ajuda urgente”, mas não faz triagem automática.
  final String? initialExerciseId;
  final ExerciseRecommender? recommender;
  final PhoneLauncher phoneLauncher;

  @override
  State<SupportFlowScreen> createState() => _SupportFlowScreenState();
}

enum _FlowStep {
  supportMenu,
  safetyCheck,
  immediateHelp,
  needPicker,
  recommendation,
  player,
  videoLibrary,
  supportNetwork,
  checkout,
  summary,
}

class _SupportFlowScreenState extends State<SupportFlowScreen> {
  late final ExerciseRecommender _recommender =
      widget.recommender ?? MockExerciseRecommender();

  _FlowStep _step = _FlowStep.supportMenu;
  RecommendationContext? _recommendationContext;
  AccessibilityPreferences _preferences = const AccessibilityPreferences();
  SupportSession? _session;
  String? _checkoutLabel;
  SupportNeed? _pickerNeed;
  SupportTime? _pickerTime;

  _FlowStep _safetyReturnStep = _FlowStep.supportMenu;
  _FlowStep _helpReturnStep = _FlowStep.supportMenu;
  _FlowStep _networkReturnStep = _FlowStep.supportMenu;
  _FlowStep _libraryReturnStep = _FlowStep.supportMenu;
  SupportVideo? _initialVideo;

  @override
  void initState() {
    super.initState();
    final initialExerciseId = widget.initialExerciseId;
    final initialExercise = initialExerciseId == null
        ? null
        : MockExerciseCatalog.byId(initialExerciseId);
    if (initialExercise != null &&
        initialExercise.reviewStatus == ExerciseReviewStatus.clinicallyReviewed) {
      _session = SupportSession(
        exerciseId: initialExercise.id,
        exerciseTitle: initialExercise.title,
        durationMinutes: initialExercise.durationMinutes,
      );
      _step = _FlowStep.player;
      return;
    }

    _step = switch (widget.start) {
      SupportFlowStart.catalog => _FlowStep.recommendation,
      SupportFlowStart.supportMenu => _FlowStep.supportMenu,
      SupportFlowStart.supportNetwork => _FlowStep.supportNetwork,
      SupportFlowStart.safetyCheck => _FlowStep.safetyCheck,
    };
  }

  void _go(_FlowStep step) => setState(() => _step = step);

  void _openSafetyCheck(_FlowStep from) {
    _safetyReturnStep = from;
    _go(_FlowStep.safetyCheck);
  }

  void _openImmediateHelp() {
    _helpReturnStep = _safetyReturnStep;
    _go(_FlowStep.immediateHelp);
  }

  void _openSupportNetwork(_FlowStep from) {
    _networkReturnStep = from;
    _go(_FlowStep.supportNetwork);
  }

  void _openVideoLibrary(_FlowStep from) {
    _initialVideo = null;
    _libraryReturnStep = from;
    _go(_FlowStep.videoLibrary);
  }

  void _completePicker(RecommendationContext context) {
    _recommendationContext = context;
    _go(_FlowStep.recommendation);
  }

  void _startExercise(Exercise exercise) {
    _session = SupportSession(
      exerciseId: exercise.id,
      exerciseTitle: exercise.title,
      durationMinutes: exercise.durationMinutes,
    );
    _checkoutLabel = null;
    _go(_FlowStep.player);
  }

  void _startVideo(SupportVideo video) {
    _initialVideo = video;
    _libraryReturnStep = _FlowStep.recommendation;
    _go(_FlowStep.videoLibrary);
  }

  void _openCatalog() {
    _recommendationContext = null;
    _go(_FlowStep.recommendation);
  }

  void _finishCheckout(String label) {
    _checkoutLabel = label;
    _go(_FlowStep.summary);
  }

  void _exitFlow() => Navigator.of(context).maybePop();

  Exercise get _currentExercise =>
      MockExerciseCatalog.byId(_session!.exerciseId)!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _FlowHeader(
              title: _title,
              onExit: _exitFlow,
              onUrgentHelp: () => _openSafetyCheck(_step),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: ListView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 48),
                  children: [_buildStep()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _title => switch (_step) {
    _FlowStep.supportMenu || _FlowStep.safetyCheck => 'Apoio',
    _FlowStep.immediateHelp => 'Ajuda urgente',
    _FlowStep.needPicker => 'Prática curta',
    _FlowStep.recommendation =>
      _recommendationContext == null ? 'Exercícios' : 'Sugestão',
    _FlowStep.player => _session?.exerciseTitle ?? 'Exercício',
    _FlowStep.videoLibrary => 'Vídeos',
    _FlowStep.supportNetwork => 'Falar com alguém',
    _FlowStep.checkout => 'Como você está',
    _FlowStep.summary => 'Concluído',
  };

  Widget _buildStep() => switch (_step) {
    _FlowStep.supportMenu => _SupportMenuView(
      onStartPractice: () => _go(_FlowStep.needPicker),
      onWatchVideo: () => _openVideoLibrary(_FlowStep.supportMenu),
      onTalkToSomeone: () => _openSupportNetwork(_FlowStep.supportMenu),
      onUrgentHelp: () => _openSafetyCheck(_FlowStep.supportMenu),
    ),
    _FlowStep.safetyCheck => SafetyCheckView(
      onYes: _openImmediateHelp,
      onNo: () => _go(_safetyReturnStep),
    ),
    _FlowStep.immediateHelp => ImmediateHelpView(
      phoneLauncher: widget.phoneLauncher,
      onBack: () => _go(_helpReturnStep),
    ),
    _FlowStep.needPicker => NeedPickerView(
      preferences: _preferences,
      onPreferencesChanged: (preferences) {
        setState(() => _preferences = preferences);
      },
      initialNeed: _pickerNeed,
      initialTime: _pickerTime,
      onNeedChanged: (need) => _pickerNeed = need,
      onTimeChanged: (time) => _pickerTime = time,
      onComplete: _completePicker,
      onBack: () => _go(_FlowStep.supportMenu),
    ),
    _FlowStep.recommendation => RecommendationView(
      context: _recommendationContext,
      recommender: _recommender,
      onStartExercise: _startExercise,
      onStartVideo: _startVideo,
      onOpenVideoLibrary: () =>
          _openVideoLibrary(_FlowStep.recommendation),
    ),
    _FlowStep.player => ExercisePlayerView(
      exercise: _currentExercise,
      session: _session!,
      onComplete: () => _go(_FlowStep.checkout),
    ),
    _FlowStep.videoLibrary => VideoLibraryView(
      onExit: () => _go(_libraryReturnStep),
      initialVideo: _initialVideo,
    ),
    _FlowStep.supportNetwork => _SupportNetworkView(
      phoneLauncher: widget.phoneLauncher,
      onBack: () => _go(_networkReturnStep),
    ),
    _FlowStep.checkout => SupportCheckoutView(
      initialLabel: _checkoutLabel,
      onAnswer: (label) => _checkoutLabel = label,
      onTalkToSomeone: () => _openSupportNetwork(_FlowStep.checkout),
      onUrgentHelp: () => _openSafetyCheck(_FlowStep.checkout),
      onChooseAnother: _openCatalog,
      onWatchVideo: () => _openVideoLibrary(_FlowStep.checkout),
      onFinish: _finishCheckout,
    ),
    _FlowStep.summary => SupportSummaryView(
      session: _session!,
      checkoutLabel: _checkoutLabel ?? '',
      onExit: _exitFlow,
    ),
  };
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    required this.onExit,
    required this.onUrgentHelp,
  });

  final String title;
  final VoidCallback onExit;
  final VoidCallback onUrgentHelp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Em larguras muito estreitas (ex.: 320 px com texto a 200%), o
          // cabeçalho quebra em duas linhas para nunca esconder a ajuda
          // urgente nem cortar o título.
          final compact = constraints.maxWidth < 420;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      key: const Key('support-exit'),
                      onPressed: onExit,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Sair'),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.center,
                  child: PersistentHelpAction(onTap: onUrgentHelp),
                ),
              ],
            );
          }
          return Row(
            children: [
              TextButton.icon(
                key: const Key('support-exit'),
                onPressed: onExit,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Sair'),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PersistentHelpAction(onTap: onUrgentHelp),
            ],
          );
        },
      ),
    );
  }
}

class _SupportMenuView extends StatelessWidget {
  const _SupportMenuView({
    required this.onStartPractice,
    required this.onWatchVideo,
    required this.onTalkToSomeone,
    required this.onUrgentHelp,
  });

  final VoidCallback onStartPractice;
  final VoidCallback onWatchVideo;
  final VoidCallback onTalkToSomeone;
  final VoidCallback onUrgentHelp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sinto muito que este momento esteja difícil.',
          key: const Key('support-menu-greeting'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Como podemos apoiar você agora? Escolha sem pressa — não há '
          'pergunta obrigatória sobre como você está.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        OptionCard(
          key: const Key('menu-short-practice'),
          label: 'Fazer uma prática curta',
          subtitle: 'Interativa, para ouvir ou assistir.',
          selected: false,
          icon: Icons.self_improvement_rounded,
          onTap: onStartPractice,
        ),
        const SizedBox(height: 12),
        OptionCard(
          key: const Key('menu-watch-video'),
          label: 'Prefiro assistir',
          subtitle: 'Vídeos curtos com transcrição.',
          selected: false,
          icon: Icons.play_circle_outline_rounded,
          onTap: onWatchVideo,
        ),
        const SizedBox(height: 12),
        OptionCard(
          key: const Key('menu-talk-to-someone'),
          label: 'Falar com alguém seguro',
          subtitle: 'Rede de apoio e profissional (simulado).',
          selected: false,
          icon: Icons.favorite_rounded,
          onTap: onTalkToSomeone,
        ),
        const SizedBox(height: 12),
        OptionCard(
          key: const Key('menu-urgent-help'),
          label: 'Ajuda urgente',
          subtitle: 'SAMU 192, CVV 188 e contatos de confiança.',
          selected: false,
          highlight: true,
          icon: Icons.emergency_share_rounded,
          onTap: onUrgentHelp,
        ),
      ],
    );
  }
}

class _SupportNetworkView extends StatelessWidget {
  const _SupportNetworkView({
    required this.phoneLauncher,
    required this.onBack,
  });

  final PhoneLauncher phoneLauncher;
  final VoidCallback onBack;

  Future<void> _showSimulatedContact(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Você escolhe com quem falar. Nada é enviado sem a sua decisão.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        OptionCard(
          key: const Key('network-cvv'),
          label: 'Ligar para o CVV — 188',
          subtitle: 'Apoio emocional 24 horas. Ligação real.',
          selected: false,
          icon: Icons.headset_mic_rounded,
          onTap: () => phoneLauncher('188'),
        ),
        const SizedBox(height: 12),
        OptionCard(
          key: const Key('network-trusted'),
          label: 'Chamar uma pessoa de confiança',
          subtitle: 'Simulado — nenhuma mensagem será enviada',
          selected: false,
          icon: Icons.favorite_rounded,
          onTap: () => _showSimulatedContact(
            context,
            'Chamar uma pessoa de confiança',
            'Este é um protótipo: nenhuma mensagem será enviada e nenhum '
            'contato será feito. No app final, você escolheria quem '
            'chamar e como.',
          ),
        ),
        const SizedBox(height: 12),
        OptionCard(
          key: const Key('network-professional'),
          label: 'Falar com meu profissional',
          subtitle: 'Simulado e claramente marcado',
          selected: false,
          icon: Icons.support_agent_rounded,
          onTap: () => _showSimulatedContact(
            context,
            'Falar com meu profissional',
            'Este é um protótipo: nenhuma mensagem será enviada ao seu '
            'profissional. No app final, este contato seguiria o canal '
            'combinado com a sua equipe.',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Demonstração — nenhuma mensagem será enviada.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Contatos verificados em agosto de 2026.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const Key('network-back'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Voltar'),
        ),
      ],
    );
  }
}
