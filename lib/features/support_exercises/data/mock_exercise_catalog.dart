import 'package:iris/features/support_exercises/domain/exercise.dart';
import 'package:iris/features/support_exercises/domain/exercise_step.dart';
import 'package:iris/features/support_exercises/domain/recommendation_context.dart';

/// Catálogo fictício do protótipo.
///
/// Os roteiros são escritos pela equipe do protótipo e não copiam material
/// licenciado; a fonte conceitual está registrada em cada item. Nada aqui é
/// prontuário e nada é persistido.
abstract final class MockExerciseCatalog {
  static const List<Exercise> exercises = <Exercise>[
    Exercise(
      id: 'anchor-present',
      title: 'Ancorar no presente',
      goal:
          'Redirecionar a atenção para o ambiente, sem precisar resolver o que sente.',
      durationMinutes: 2,
      supportedFormats: {SupportFormat.interactive, SupportFormat.audio},
      needs: [SupportNeed.present, SupportNeed.notSure],
      steps: <ExerciseStep>[
        ExerciseStep(
          type: ExerciseStepType.multiChoice,
          prompt:
              'Sem pressa, procure três detalhes no ambiente: uma cor, uma linha e algo que não se move. Marque os que encontrou.',
          options: <String>[
            'Uma cor',
            'Uma linha, borda ou forma',
            'Algo parado',
            'Outro detalhe',
          ],
          feedback: 'Você acabou de trazer a atenção para o que está aqui.',
        ),
        ExerciseStep(
          type: ExerciseStepType.multiChoice,
          prompt:
              'Agora, apenas escute por alguns segundos. Que tipo de som você percebe?',
          options: <String>[
            'Um som perto de mim',
            'Um som mais distante',
            'Quase nenhum som',
            'Prefiro não prestar atenção aos sons',
          ],
          feedback: 'Notar um som já é suficiente; não existe resposta certa.',
        ),
        ExerciseStep(
          type: ExerciseStepType.multiChoice,
          prompt:
              'Sem mudar nada no corpo, note um ponto de apoio que está disponível agora.',
          options: <String>[
            'Meus pés no chão',
            'Minhas costas na cadeira ou parede',
            'Minhas mãos apoiadas',
            'Prefiro ficar só com o ambiente',
          ],
          feedback: 'Você escolheu um ponto de apoio para este momento.',
        ),
        ExerciseStep(
          type: ExerciseStepType.singleChoice,
          prompt:
              'Qual detalhe você pode manter por mais alguns segundos, se quiser?',
          options: <String>[
            'A cor ou forma que vi',
            'O som que ouvi',
            'O ponto de apoio que notei',
            'Nenhum; quero encerrar por aqui',
          ],
          feedback: 'Você decidiu onde colocar sua atenção — isso basta.',
        ),
        ExerciseStep(
          type: ExerciseStepType.closing,
          prompt:
              'Antes de sair, escolha um atalho para a próxima vez: olhar para um detalhe, escutar um som ou sentir um ponto de apoio.',
          feedback:
              'Você acabou de praticar uma sequência simples: notar o ambiente, escutar e encontrar apoio. Quando o momento apertar, não precisa repetir tudo: escolha só um desses três passos e fique nele por alguns segundos.',
        ),
      ],
      author: 'Equipe de conteúdo Íris (demonstração)',
      conceptualSource: 'OMS — Doing What Matters in Times of Stress',
      clinicalReviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      version: '1.2-demo',
      nextReviewDate: '2027-03-10',
      contraindications: <String>[
        'Em crise aguda, procure ajuda urgente antes de praticar.',
      ],
    ),
    Exercise(
      id: 'notice-and-name',
      title: 'Perceber e nomear',
      goal:
          'Observar uma experiência com palavras simples, sem tentar consertá-la.',
      durationMinutes: 3,
      supportedFormats: {SupportFormat.interactive, SupportFormat.audio},
      needs: [SupportNeed.nameFeelings],
      steps: <ExerciseStep>[
        ExerciseStep(
          type: ExerciseStepType.multiChoice,
          prompt:
              'Antes de explicar ou resolver, escolha a palavra mais próxima do que está presente agora.',
          options: <String>[
            'Ansiedade ou preocupação',
            'Tristeza ou desânimo',
            'Irritação ou raiva',
            'Confusão ou vazio',
            'Outra coisa',
            'Ainda não sei',
          ],
          feedback: 'Uma palavra aproximada já é suficiente.',
        ),
        ExerciseStep(
          type: ExerciseStepType.textReflection,
          prompt:
              'Se quiser, complete: “Agora há ___ em mim.” Use poucas palavras ou apenas copie uma opção anterior.',
          feedback:
              'Você observou uma experiência sem precisar defini-la por completo.',
          semanticsHint: 'Campo de texto livre. Nada será salvo ou enviado.',
        ),
        ExerciseStep(
          type: ExerciseStepType.closing,
          prompt:
              'Agora transforme o nome que escolheu em uma frase de continuidade: “Agora há ___ em mim; ainda posso fazer ___ por um minuto.”',
          feedback:
              'Nomear não faz a sensação desaparecer, mas evita que ela ocupe todo o espaço. Da próxima vez, tente este percurso: dê um nome aproximado, reconheça que ele está aqui e retome uma tarefa pequena ou peça companhia.',
        ),
      ],
      author: 'Equipe de conteúdo Íris (demonstração)',
      conceptualSource: 'OMS — Doing What Matters in Times of Stress',
      clinicalReviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      version: '1.2-demo',
      nextReviewDate: '2027-03-10',
      contraindications: <String>[
        'Em crise aguda, procure ajuda urgente antes de praticar.',
      ],
    ),
    Exercise(
      id: 'space-for-thought',
      title: 'Dar espaço ao pensamento',
      goal:
          'Notar um pensamento como pensamento e recuperar a possibilidade de escolher.',
      durationMinutes: 3,
      supportedFormats: {SupportFormat.interactive, SupportFormat.audio},
      needs: [SupportNeed.difficultThought],
      steps: <ExerciseStep>[
        ExerciseStep(
          type: ExerciseStepType.textReflection,
          prompt:
              'Se for seguro fazer isso agora, escreva uma versão curta do pensamento que está mais insistente. Você pode pular esta etapa.',
          feedback:
              'Você trouxe o pensamento para fora da cabeça, em poucas palavras.',
          semanticsHint: 'Campo de texto livre. Nada será salvo ou enviado.',
        ),
        ExerciseStep(
          type: ExerciseStepType.textReflection,
          prompt:
              'Agora experimente a frase: “Estou notando o pensamento de que ___.” Não é preciso discutir se ele é verdadeiro.',
          feedback:
              'Você criou uma pequena distância entre você e o pensamento.',
          semanticsHint: 'Campo de texto livre. Nada será salvo ou enviado.',
        ),
        ExerciseStep(
          type: ExerciseStepType.singleChoice,
          prompt:
              'Sem obedecer nem combater o pensamento, qual passo de dois minutos combina mais com o que importa agora?',
          options: <String>[
            'Voltar por dois minutos à tarefa que eu estava fazendo',
            'Mandar uma mensagem simples para alguém seguro',
            'Preparar um lugar mais confortável para mim',
            'Não fazer nada agora e buscar apoio depois',
          ],
          feedback:
              'Você escolheu uma direção; não precisa executar nada neste instante.',
        ),
        ExerciseStep(
          type: ExerciseStepType.closing,
          prompt:
              'Quando esse pensamento voltar, experimente responder com o mesmo roteiro: “Estou notando o pensamento de que…”, depois escolha uma ação de dois minutos.',
          feedback:
              'A meta não é vencer nem provar que o pensamento está errado. É criar espaço suficiente para escolher o próximo gesto. Se ele trouxer risco, medo de agir ou sensação de não conseguir se manter em segurança, pare e procure ajuda humana.',
        ),
      ],
      author: 'Equipe de conteúdo Íris (demonstração)',
      conceptualSource: 'OMS — Doing What Matters in Times of Stress',
      clinicalReviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      version: '1.2-demo',
      nextReviewDate: '2027-03-10',
      contraindications: <String>[
        'Em crise aguda, procure ajuda urgente antes de praticar.',
      ],
    ),
    Exercise(
      id: 'talk-to-me-kindly',
      title: 'Falar comigo como com alguém querido',
      goal:
          'Responder à dificuldade com um tom menos duro e uma necessidade concreta.',
      durationMinutes: 3,
      supportedFormats: {SupportFormat.interactive, SupportFormat.audio},
      needs: [SupportNeed.selfKindness],
      steps: <ExerciseStep>[
        ExerciseStep(
          type: ExerciseStepType.singleChoice,
          prompt:
              'Imagine alguém de quem você gosta vivendo algo parecido. Qual frase soaria mais honesta e cuidadosa?',
          options: <String>[
            'Isso está difícil; você não precisa dar conta de tudo agora',
            'Você merece uma pausa antes de decidir o que fazer',
            'Você pode pedir companhia sem precisar explicar tudo',
            'Você não precisa se punir por estar tendo um dia difícil',
          ],
          feedback: 'Gentileza pode ser simples e realista.',
        ),
        ExerciseStep(
          type: ExerciseStepType.textReflection,
          prompt:
              'Transforme a ideia em uma frase para você. Comece com “Eu posso…” ou “Eu mereço…”, se isso ajudar.',
          feedback:
              'Você escolheu um jeito de falar consigo que não aumenta o peso do momento.',
          semanticsHint: 'Campo de texto livre. Nada será salvo ou enviado.',
        ),
        ExerciseStep(
          type: ExerciseStepType.singleChoice,
          prompt:
              'Qual cuidado pequeno parece mais possível nas próximas horas?',
          options: <String>[
            'Diminuir uma exigência que posso adiar',
            'Fazer uma pausa curta sem me justificar',
            'Pedir presença a alguém de confiança',
            'Procurar meu profissional quando for possível',
          ],
          feedback: 'Cuidado não precisa resolver tudo para ser válido.',
        ),
        ExerciseStep(
          type: ExerciseStepType.closing,
          prompt:
              'Guarde uma versão curta da sua frase para usar quando a autocrítica aparecer: “Isso está difícil; qual é o cuidado possível agora?”',
          feedback:
              'Gentileza útil não é fingir que está tudo bem. É trocar uma cobrança que machuca por uma pergunta prática: o que posso diminuir, pausar, pedir ou adiar? Escolha apenas uma resposta possível para hoje.',
        ),
      ],
      author: 'Equipe de conteúdo Íris (demonstração)',
      conceptualSource: 'OMS — Doing What Matters in Times of Stress',
      clinicalReviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      version: '1.2-demo-preview',
      nextReviewDate: '2027-03-10',
      contraindications: <String>[
        'Em crise aguda, procure ajuda urgente antes de praticar.',
      ],
      reviewStatus: ExerciseReviewStatus.draft,
      isPreview: true,
    ),
    Exercise(
      id: 'safe-next-step',
      title: 'Próximo passo seguro',
      goal:
          'Transformar uma necessidade em um próximo passo pequeno, claro e voluntário.',
      durationMinutes: 2,
      supportedFormats: {SupportFormat.interactive, SupportFormat.audio},
      needs: [SupportNeed.nextSafeStep],
      steps: <ExerciseStep>[
        ExerciseStep(
          type: ExerciseStepType.singleChoice,
          prompt:
              'Você não precisa resolver o dia inteiro. Qual tipo de apoio faria mais diferença nos próximos minutos?',
          options: <String>[
            'Companhia de alguém seguro',
            'Um ambiente um pouco mais confortável',
            'Uma pausa de exigências',
            'Contato com meu profissional',
          ],
          feedback: 'Você identificou uma necessidade, não uma obrigação.',
        ),
        ExerciseStep(
          type: ExerciseStepType.singleChoice,
          prompt:
              'Escolha um passo que seja específico e caiba em poucos minutos.',
          options: <String>[
            'Enviar: “Você pode ficar comigo por alguns minutos?”',
            'Ir para um lugar com menos estímulos',
            'Separar dois minutos sem decidir nada',
            'Anotar para falar com meu profissional depois',
          ],
          feedback: 'O passo é seu; você decide se, quando e como vai fazê-lo.',
        ),
        ExerciseStep(
          type: ExerciseStepType.closing,
          prompt:
              'Para levar isso adiante, tente deixar o passo escolhido visível: envie a mensagem, mude de lugar, marque a pausa ou anote o assunto.',
          feedback:
              'Um próximo passo funciona melhor quando é pequeno e observável. Se ele não couber agora, reduza-o: escreva só uma palavra, vá até a porta ou envie apenas “preciso de companhia”. Se nada parecer seguro, procure ajuda humana.',
        ),
      ],
      author: 'Equipe de conteúdo Íris (demonstração)',
      conceptualSource: 'OMS — Doing What Matters in Times of Stress',
      clinicalReviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      version: '1.2-demo-preview',
      nextReviewDate: '2027-03-10',
      contraindications: <String>[
        'Em crise aguda, procure ajuda urgente antes de praticar.',
      ],
      reviewStatus: ExerciseReviewStatus.draft,
      isPreview: true,
    ),
  ];

  static Exercise? byId(String id) {
    for (final exercise in exercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }
}
