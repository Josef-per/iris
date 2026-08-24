import 'package:iris/features/ai_support/data/mock_mood_history.dart';
import 'package:iris/features/ai_support/domain/support_signal.dart';

/// Cenário local de demonstração, composto apenas por sinais estruturados.
class MockAiSupportScenario {
  const MockAiSupportScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.signals,
  });

  final String id;
  final String title;
  final String description;
  final List<SupportSignal> signals;
}

abstract final class MockDiarySignals {
  static List<MockAiSupportScenario> scenarios(DateTime now) {
    final difficultMood = MockMoodHistory.trendFrom(
      MockMoodHistory.difficultPattern(now),
      now: now,
    );
    return <MockAiSupportScenario>[
      MockAiSupportScenario(
        id: 'difficult_mood_short_interactive',
        title: 'Humor mais difícil e prática curta',
        description:
            'Três check-ins estruturados difíceis em quatro, sem usar diário livre.',
        signals: <SupportSignal>[difficultMood],
      ),
      MockAiSupportScenario(
        id: 'confirmed_loneliness',
        title: 'Tag de solidão confirmada',
        description: 'Uma tag escolhida e confirmada pela própria pessoa.',
        signals: <SupportSignal>[
          ConfirmedTopicSignal(
            id: 'topic-loneliness-demo-1',
            createdAt: now,
            expiresAt: now.add(const Duration(days: 7)),
            topic: SupportTopicKey.loneliness,
          ),
        ],
      ),
      MockAiSupportScenario(
        id: 'exercise_was_not_helpful',
        title: 'Exercício anterior não ajudou',
        description:
            'O recomendador evita repetir o exercício e pode priorizar conexão humana.',
        signals: <SupportSignal>[
          ExerciseFeedbackSignal(
            id: 'exercise-feedback-demo-1',
            createdAt: now.subtract(const Duration(hours: 2)),
            expiresAt: now.add(const Duration(days: 7)),
            exerciseId: 'anchor-present',
            helpfulness: ExerciseHelpfulness.notHelpful,
          ),
        ],
      ),
      MockAiSupportScenario(
        id: 'topic_needs_confirmation',
        title: 'Interpretação que pode ser corrigida',
        description:
            'Um tópico não confirmado não influencia sugestões até a pessoa concordar.',
        signals: <SupportSignal>[
          ConfirmedTopicSignal(
            id: 'topic-overload-unconfirmed-demo-1',
            createdAt: now,
            expiresAt: now.add(const Duration(days: 7)),
            topic: SupportTopicKey.overload,
            isConfirmed: false,
          ),
        ],
      ),
    ];
  }
}

/// Nome alternativo mais descritivo para a UI.
typedef MockAiSupportScenarios = MockDiarySignals;
