import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/ai_support/data/ai_support_settings_repository.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';

void main() {
  test(
    'codifica consentimento, sem incluir o texto livre do diário',
    () {
      final encoded = encodeAiSupportSettings(
        patientId: 'patient-1',
        consent: const AiSupportConsent(
          personalizedSuggestionsGranted: true,
          grantedSources: <SupportSignalSource>{
            SupportSignalSource.moodHistory,
            SupportSignalSource.diaryTags,
            SupportSignalSource.diaryText,
          },
        ),
        preferences: const AiSupportPreferences(
          personalizedSuggestionsEnabled: true,
          allowedCategories: <SupportSuggestionCategory>{
            SupportSuggestionCategory.reflection,
          },
          notifications: NotificationPreferences(
            enabled: true,
            frequency: NotificationFrequency.twicePerWeek,
            soundEnabled: true,
            vibrationEnabled: true,
          ),
        ),
        now: DateTime.utc(2026, 8, 24, 12),
        timeZoneName: 'America/Sao_Paulo',
      );

      expect(encoded['fontes_consentidas'], <String>[
        'diary_text',
        'diary_topics',
        'mood_history',
      ]);
      expect(encoded['frequencia_semanal'], 2);
      expect(encoded['som_ativo'], isFalse);
      expect(encoded['vibracao_ativa'], isFalse);
      expect(encoded.keys, isNot(contains('diario_emocional')));
      expect(encoded.values, isNot(contains('conteúdo privado')));
    },
  );

  test('decodifica escolhas conhecidas e ignora valores desconhecidos', () {
    final decoded = decodeAiSupportSettings(<String, dynamic>{
      'personalizacao_ativa': true,
      'fontes_consentidas': <String>['mood_history', 'unknown'],
      'categorias_permitidas': <String>['reflection', 'unknown'],
      'duracao_maxima_minutos': 3,
      'conteudos_excluidos': <String>['breathing_focused', 'unknown'],
      'notificacoes_ativas': true,
      'frequencia_semanal': 1,
      'janela_inicio': '10:30:00',
      'janela_fim': '18:00:00',
      'dias_semana': <int>[1, 3, 8],
      'previa_bloqueio': 'nenhuma',
      'pausado_ate': '2026-08-30T12:00:00Z',
      'versao_consentimento': 'support-consent-v1',
    });

    expect(decoded.consent.grantedSources, <SupportSignalSource>{
      SupportSignalSource.moodHistory,
    });
    expect(decoded.preferences.allowedCategories, <SupportSuggestionCategory>{
      SupportSuggestionCategory.reflection,
    });
    expect(decoded.preferences.notifications.window.start.hour, 10);
    expect(decoded.preferences.notifications.window.start.minute, 30);
    expect(decoded.preferences.notifications.window.allowedWeekdays, <int>{
      1,
      3,
    });
    expect(
      decoded.preferences.notifications.lockScreenPreview,
      LockScreenPreview.none,
    );
  });

  test(
    'linha sem versão de consentimento volta para estado seguro desligado',
    () {
      final decoded = decodeAiSupportSettings(<String, dynamic>{
        'personalizacao_ativa': true,
        'fontes_consentidas': <String>['mood_history'],
        'categorias_permitidas': <String>['reflection'],
        'notificacoes_ativas': false,
        'frequencia_semanal': 0,
      });

      expect(decoded.consent.personalizedSuggestionsGranted, isFalse);
      expect(decoded.consent.grantedSources, <SupportSignalSource>{
        SupportSignalSource.moodHistory,
      });
      expect(
        decoded.consent.allowsSource(SupportSignalSource.moodHistory),
        isFalse,
      );
      expect(decoded.preferences.personalizedSuggestionsEnabled, isFalse);
    },
  );
}
