import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/patient_dashboard/patient_today_summary.dart';
import 'package:iris/features/support_exercises/presentation/support_flow_screen.dart';
import 'package:iris/screens/home_screen.dart';

class _FakePhoneLauncher {
  final List<String> calls = <String>[];

  Future<bool> call(String number) async {
    calls.add(number);
    return true;
  }
}

class _TodaySource implements PatientTodayDataSource {
  @override
  Future<PatientTodaySummary> loadToday() async => const PatientTodaySummary(
    mealCount: 0,
    moodScore: null,
    hasCheckIn: false,
    hasDiaryEntry: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<SupportFlowScreen> pumpFlow(
    WidgetTester tester, {
    SupportFlowStart start = SupportFlowStart.supportMenu,
    _FakePhoneLauncher? phone,
  }) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final launcher = phone ?? _FakePhoneLauncher();
    final flow = SupportFlowScreen(start: start, phoneLauncher: launcher.call);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => flow)),
                child: const Text('abrir fluxo'),
              ),
            ),
          ),
        ),
      ),
    );
    await tapText(tester, 'abrir fluxo');
    return flow;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> completeAncorar(WidgetTester tester) async {
    await tapKey(tester, 'exercise-option-Uma cor');
    await tapKey(tester, 'exercise-continue');
    await tapKey(tester, 'exercise-option-Um som mais distante');
    await tapKey(tester, 'exercise-continue');
    await tapKey(tester, 'exercise-option-Meus pés no chão');
    await tapKey(tester, 'exercise-continue');
    await tapKey(tester, 'exercise-option-A cor ou forma que vi');
    await tapKey(tester, 'exercise-continue');
    await tapKey(tester, 'exercise-continue');
  }

  group('Home', () {
    Future<void> pumpHome(WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: HomeScreen(todayDataSource: _TodaySource()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('“Exercícios” abre o catálogo sem checagem de segurança', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(find.byKey(const Key('home-exercises-card')), findsOneWidget);
      expect(find.byKey(const Key('home-not-ok-card')), findsOneWidget);

      await tapKey(tester, 'home-exercises-card');

      expect(find.text('Catálogo de exercícios'), findsOneWidget);
      expect(find.text('Ancorar no presente'), findsWidgets);
      expect(find.byKey(const Key('safety-yes')), findsNothing);
      expect(find.byKey(const Key('support-urgent-help')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('“Não estou bem” abre o menu de apoio sem pergunta de '
        'segurança', (tester) async {
      await pumpHome(tester);

      await tapKey(tester, 'home-not-ok-card');

      expect(find.byKey(const Key('support-menu-greeting')), findsOneWidget);
      expect(find.byKey(const Key('menu-short-practice')), findsOneWidget);
      expect(find.textContaining('Você corre risco'), findsNothing);
    });

    testWidgets('Home permanece legível a 320 px com os novos cartões', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: HomeScreen(todayDataSource: _TodaySource()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Cuidar de você hoje'), findsOneWidget);
    });
  });

  group('Menu de apoio', () {
    testWidgets('somente “Ajuda urgente” abre a checagem de segurança', (
      tester,
    ) async {
      await pumpFlow(tester);

      expect(find.byKey(const Key('support-menu-greeting')), findsOneWidget);
      expect(find.textContaining('Você corre risco'), findsNothing);

      await tapKey(tester, 'menu-short-practice');
      expect(find.textContaining('Você corre risco'), findsNothing);
      expect(find.byKey(const Key('need-present')), findsOneWidget);

      await tapKey(tester, 'need-picker-back');
      await tapKey(tester, 'menu-watch-video');
      expect(find.textContaining('Você corre risco'), findsNothing);
      expect(find.text('Biblioteca de vídeos'), findsOneWidget);

      await tapKey(tester, 'video-back');
      expect(find.text('Biblioteca de vídeos'), findsNothing);

      await tapKey(tester, 'menu-urgent-help');
      expect(find.textContaining('Você corre risco'), findsOneWidget);
      expect(find.byKey(const Key('safety-maybe')), findsOneWidget);
    });

    testWidgets('“Sim” e “Talvez” chegam à ajuda imediata sem recomendador', (
      tester,
    ) async {
      await pumpFlow(tester);
      await tapKey(tester, 'menu-urgent-help');
      await tapKey(tester, 'safety-maybe');

      expect(find.byKey(const Key('help-samu-192')), findsOneWidget);
      expect(find.byKey(const Key('help-cvv-188')), findsOneWidget);
      expect(
        find.text('Demonstração — nenhuma mensagem será enviada.'),
        findsOneWidget,
      );
      expect(find.text('Sugestão para você'), findsNothing);

      await tapKey(tester, 'help-back');
      await tapKey(tester, 'menu-urgent-help');
      await tapKey(tester, 'safety-yes');
      expect(find.byKey(const Key('help-samu-192')), findsOneWidget);
    });

    testWidgets('“Não” na checagem volta às opções de apoio sem bloquear', (
      tester,
    ) async {
      await pumpFlow(tester);
      await tapKey(tester, 'menu-urgent-help');
      await tapKey(tester, 'safety-no');

      expect(find.byKey(const Key('support-menu-greeting')), findsOneWidget);
      expect(find.byKey(const Key('menu-short-practice')), findsOneWidget);
    });

    testWidgets('tela de ajuda mostra 192/188 acionáveis e avisos de '
        'demonstração', (tester) async {
      final phone = _FakePhoneLauncher();
      await pumpFlow(tester, phone: phone);
      await tapKey(tester, 'menu-urgent-help');
      await tapKey(tester, 'safety-maybe');

      await tapKey(tester, 'help-samu-192');
      await tapKey(tester, 'help-cvv-188');

      expect(phone.calls, ['192', '188']);
      expect(find.textContaining('Se puder, fique com alguém'), findsOneWidget);
      expect(
        find.textContaining('nenhuma mensagem será enviada'),
        findsWidgets,
      );
    });

    testWidgets('“Falar com alguém seguro” mostra rede de apoio simulada', (
      tester,
    ) async {
      await pumpFlow(tester);
      await tapKey(tester, 'menu-talk-to-someone');

      expect(find.byKey(const Key('network-cvv')), findsOneWidget);
      expect(find.byKey(const Key('network-trusted')), findsOneWidget);
      expect(find.byKey(const Key('network-professional')), findsOneWidget);
      expect(
        find.textContaining('Demonstração — nenhuma mensagem'),
        findsOneWidget,
      );

      await tapKey(tester, 'network-trusted');
      expect(
        find.textContaining('nenhuma mensagem será enviada'),
        findsWidgets,
      );
      await tapText(tester, 'Entendi');
      await tapKey(tester, 'network-back');
      expect(find.byKey(const Key('support-menu-greeting')), findsOneWidget);
    });
  });

  group('Fluxo completo', () {
    testWidgets('prática curta percorre necessidade, tempo, formato, '
        'recomendação, player e check-out', (tester) async {
      await pumpFlow(tester);

      await tapKey(tester, 'menu-short-practice');
      expect(find.text('O que ajudaria mais neste momento?'), findsOneWidget);

      await tapKey(tester, 'need-present');
      expect(find.text('Quanto tempo você tem agora?'), findsOneWidget);

      await tapKey(tester, 'time-minutes1_2');
      expect(find.text('Como prefere?'), findsOneWidget);

      await tapKey(tester, 'format-interactive');

      expect(
        find.byKey(const Key('recommendation-suggestion')),
        findsOneWidget,
      );
      expect(find.text('Ancorar no presente'), findsWidgets);
      expect(find.textContaining('interativo'), findsOneWidget);
      expect(find.textContaining('1 a 2 minutos'), findsOneWidget);

      await tapKey(tester, 'recommendation-start');

      expect(find.text('Etapa 1 de 5'), findsOneWidget);

      await completeAncorar(tester);

      expect(find.byKey(const Key('checkout-question')), findsOneWidget);
      expect(find.text('Como este momento está agora?'), findsOneWidget);
    });

    testWidgets('“Um pouco melhor” conclui com resumo em memória', (
      tester,
    ) async {
      await pumpFlow(tester);
      await tapKey(tester, 'menu-short-practice');
      await tapKey(tester, 'need-present');
      await tapKey(tester, 'time-minutes1_2');
      await tapKey(tester, 'format-interactive');
      await tapKey(tester, 'recommendation-start');
      await completeAncorar(tester);

      await tapKey(tester, 'checkout-aLittleBetter');
      expect(find.byKey(const Key('checkout-finish')), findsOneWidget);

      await tapKey(tester, 'checkout-finish');

      expect(find.byKey(const Key('summary-text')), findsOneWidget);
      expect(find.textContaining('Ancorar no presente'), findsOneWidget);
      expect(find.textContaining('Um pouco melhor'), findsOneWidget);
      expect(find.textContaining('Nada foi enviado'), findsOneWidget);
      expect(find.textContaining('Nada será salvo ou enviado'), findsOneWidget);
    });

    testWidgets('“Pior” prioriza ajuda humana sem bloquear e sem presumir '
        'risco', (tester) async {
      await pumpFlow(tester);
      await tapKey(tester, 'menu-short-practice');
      await tapKey(tester, 'need-present');
      await tapKey(tester, 'time-minutes1_2');
      await tapKey(tester, 'format-interactive');
      await tapKey(tester, 'recommendation-start');
      await completeAncorar(tester);

      await tapKey(tester, 'checkout-worse');

      expect(find.byKey(const Key('checkout-talk')), findsOneWidget);
      expect(find.byKey(const Key('checkout-urgent')), findsOneWidget);
      expect(find.byKey(const Key('checkout-another')), findsNothing);

      await tapKey(tester, 'checkout-talk');
      expect(find.byKey(const Key('network-cvv')), findsOneWidget);

      await tapKey(tester, 'network-back');
      await tapKey(tester, 'checkout-urgent');
      expect(find.textContaining('Você corre risco'), findsOneWidget);
    });

    testWidgets('“Igual” permite escolher outra ferramenta, vídeo ou '
        'encerrar', (tester) async {
      await pumpFlow(tester);
      await tapKey(tester, 'menu-short-practice');
      await tapKey(tester, 'need-present');
      await tapKey(tester, 'time-minutes1_2');
      await tapKey(tester, 'format-interactive');
      await tapKey(tester, 'recommendation-start');
      await completeAncorar(tester);

      await tapKey(tester, 'checkout-same');

      expect(find.byKey(const Key('checkout-another')), findsOneWidget);
      expect(find.byKey(const Key('checkout-video')), findsOneWidget);
      expect(find.byKey(const Key('checkout-finish')), findsOneWidget);

      await tapKey(tester, 'checkout-another');
      expect(find.text('Catálogo de exercícios'), findsOneWidget);

      await tapKey(tester, 'exercise-card-anchor-present');
      await completeAncorar(tester);

      expect(find.byKey(const Key('checkout-question')), findsOneWidget);
      expect(find.text('Como este momento está agora?'), findsOneWidget);
    });
    testWidgets('voltar da checagem de segurança preserva as escolhas do '
        'seletor', (tester) async {
      await pumpFlow(tester);
      await tapKey(tester, 'menu-short-practice');
      await tapKey(tester, 'need-present');
      await tapKey(tester, 'time-minutes1_2');

      await tapKey(tester, 'support-urgent-help');
      expect(find.text('Checagem de segurança'), findsOneWidget);
      await tapKey(tester, 'safety-no');
      expect(find.text('O que ajudaria mais neste momento?'), findsOneWidget);

      await tapKey(tester, 'need-present');
      expect(find.text('Quanto tempo você tem agora?'), findsOneWidget);
      await tapKey(tester, 'time-minutes1_2');
      expect(find.text('Como prefere?'), findsOneWidget);
    });
  });

  group('Player', () {
    Future<void> startAncorar(WidgetTester tester) async {
      await pumpFlow(tester);
      await tapKey(tester, 'menu-short-practice');
      await tapKey(tester, 'need-present');
      await tapKey(tester, 'time-minutes1_2');
      await tapKey(tester, 'format-interactive');
      await tapKey(tester, 'recommendation-start');
    }

    testWidgets('pular e voltar preservam o controle da pessoa', (
      tester,
    ) async {
      await startAncorar(tester);

      expect(find.text('Etapa 1 de 5'), findsOneWidget);

      await tapKey(tester, 'exercise-skip');
      expect(find.text('Etapa 2 de 5'), findsOneWidget);

      await tapKey(tester, 'exercise-back');
      expect(find.text('Etapa 1 de 5'), findsOneWidget);

      await tapKey(tester, 'exercise-option-Uma cor');
      expect(find.byKey(const Key('exercise-feedback')), findsOneWidget);

      await tapKey(tester, 'exercise-continue');
      expect(find.text('Etapa 2 de 5'), findsOneWidget);
    });

    testWidgets('texto livre é obrigatório só no momento de continuar e pode '
        'ser pulado', (tester) async {
      await pumpFlow(tester);
      await tapKey(tester, 'menu-short-practice');
      await tapKey(tester, 'need-difficultThought');
      await tapKey(tester, 'time-minutes3');
      await tapKey(tester, 'format-interactive');

      expect(find.text('Dar espaço ao pensamento'), findsWidgets);
      await tapKey(tester, 'recommendation-start');

      expect(find.text('Etapa 1 de 4'), findsOneWidget);
      final continueButton = find.byKey(const Key('exercise-continue'));
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('exercise-text')), '  ');
      await tester.pump();
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('exercise-text')),
        'que nada vai dar certo',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);

      await tapKey(tester, 'exercise-continue');
      await tapKey(tester, 'exercise-skip');
      expect(find.text('Etapa 3 de 4'), findsOneWidget);
    });

    testWidgets('“Ajuda urgente” permanece acessível no player', (
      tester,
    ) async {
      await startAncorar(tester);

      await tapKey(tester, 'support-urgent-help');
      expect(find.textContaining('Você corre risco'), findsOneWidget);

      await tapKey(tester, 'safety-no');
      expect(find.text('Etapa 1 de 5'), findsOneWidget);
    });

    testWidgets('“Sair” fecha o fluxo sem confirmação culpabilizante', (
      tester,
    ) async {
      await startAncorar(tester);

      await tapKey(tester, 'support-exit');

      expect(find.byType(SupportFlowScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Vídeos', () {
    testWidgets('biblioteca não reproduz sozinho e expõe legenda, '
        'transcrição e modo texto', (tester) async {
      await pumpFlow(tester);
      await tapKey(tester, 'menu-watch-video');

      expect(find.text('Biblioteca de vídeos'), findsOneWidget);
      await tapKey(tester, 'video-card-video-return-present');

      expect(find.textContaining('Pronto para reproduzir'), findsOneWidget);

      await tapKey(tester, 'video-play-toggle');
      expect(
        find.textContaining('Reproduzindo (demonstração)'),
        findsOneWidget,
      );

      await tapKey(tester, 'video-transcript');
      expect(find.byKey(const Key('video-transcript-content')), findsOneWidget);

      await tapKey(tester, 'video-text-mode');
      expect(find.textContaining('Modo texto'), findsOneWidget);

      await tapKey(tester, 'video-back-to-library');
      expect(find.text('Biblioteca de vídeos'), findsOneWidget);
    });

    testWidgets('recomendação de vídeo respeita o formato escolhido', (
      tester,
    ) async {
      await pumpFlow(tester);
      await tapKey(tester, 'menu-short-practice');
      await tapKey(tester, 'need-present');
      await tapKey(tester, 'time-minutes5');
      await tapKey(tester, 'format-video');

      expect(find.byKey(const Key('recommendation-start')), findsOneWidget);
      expect(find.text('Começar vídeo'), findsOneWidget);
      expect(find.text('Como voltar ao presente'), findsWidgets);

      await tapKey(tester, 'recommendation-start');
      expect(find.textContaining('Pronto para reproduzir'), findsOneWidget);
    });
  });

  group('Acessibilidade', () {
    testWidgets('progresso tem Semantics e opção selecionada é anunciada', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpFlow(tester);
      await tapKey(tester, 'menu-short-practice');
      await tapKey(tester, 'need-present');
      await tapKey(tester, 'time-minutes1_2');
      await tapKey(tester, 'format-interactive');
      await tapKey(tester, 'recommendation-start');

      expect(find.bySemanticsLabel('Etapa 1 de 5'), findsOneWidget);

      await tapKey(tester, 'exercise-option-Uma cor');
      final semanticsNode = tester.getSemantics(
        find.byKey(const Key('exercise-option-Uma cor')),
      );
      expect(
        semanticsNode.flagsCollection.isSelected == Tristate.isTrue,
        isTrue,
      );
      semantics.dispose();
    });

    testWidgets('fluxo completo funciona no tema escuro a 320 px', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SupportFlowScreen(),
                    ),
                  ),
                  child: const Text('abrir fluxo'),
                ),
              ),
            ),
          ),
        ),
      );
      await tapText(tester, 'abrir fluxo');

      await tapKey(tester, 'support-urgent-help');
      expect(find.text('Checagem de segurança'), findsOneWidget);
      await tapKey(tester, 'safety-no');

      await tapKey(tester, 'menu-short-practice');
      await tapKey(tester, 'need-present');
      await tapKey(tester, 'time-minutes1_2');
      await tapKey(tester, 'format-interactive');
      await tapKey(tester, 'recommendation-start');
      await completeAncorar(tester);
      await tapKey(tester, 'checkout-same');
      await tapKey(tester, 'checkout-finish');

      expect(find.byKey(const Key('summary-text')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fluxo sem overflow a 320 px com texto a 200%', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const SupportFlowScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('support-menu-greeting')), findsOneWidget);
    });
  });
}
