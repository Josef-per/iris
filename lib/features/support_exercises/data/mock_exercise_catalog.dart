import 'package:iris/features/support_exercises/domain/exercise.dart';
import 'package:iris/features/support_exercises/domain/exercise_step.dart';
import 'package:iris/features/support_exercises/domain/recommendation_context.dart';

/// Catálogo fictício do protótipo.
///
/// Cada roteiro conduz uma prática. Os botões servem apenas para a pessoa
/// marcar que a experimentou no próprio ritmo — não há respostas certas nem
/// tentativa de medir se ela "melhorou". Nada é persistido.
abstract final class MockExerciseCatalog {
  static const List<Exercise> exercises = <Exercise>[
    Exercise(
      id: 'anchor-present',
      title: 'Ancorar no presente',
      goal: 'Usar o ambiente para recuperar um pouco de orientação no agora.',
      durationMinutes: 2,
      supportedFormats: {SupportFormat.interactive, SupportFormat.audio},
      needs: [SupportNeed.present, SupportNeed.notSure],
      steps: <ExerciseStep>[
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Comece olhando para algo estável ao seu redor.',
          guidance:
              'Mantenha os olhos abertos, se isso for confortável. Escolha um objeto comum e acompanhe devagar seu contorno, uma cor e uma parte clara ou escura. Não precisa achar nada especial.',
          feedback:
              'O ambiente continua aqui, mesmo quando o momento está intenso.',
        ),
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Agora acrescente um som ao que você está percebendo.',
          guidance:
              'Sem procurar muito, note um som perto ou longe. Se os sons incomodarem, volte apenas para o objeto que estava olhando. A prática pode ser ajustada ao que é tolerável hoje.',
          feedback: 'Você pode escolher para onde dirigir a atenção.',
        ),
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Encontre um ponto de apoio disponível neste instante.',
          guidance:
              'Sem mudar a posição, perceba os pés no chão, as costas na cadeira ou as mãos apoiadas. Diga mentalmente: “Estou aqui; há algo me sustentando agora.”',
          feedback:
              'O objetivo não é relaxar à força, só encontrar apoio suficiente para este minuto.',
        ),
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Volte para três fatos simples do momento.',
          guidance:
              'Complete em pensamento: “Estou em ___. Agora é ___. No próximo minuto, vou apenas ___.” Use algo pequeno no final: sentar, beber água, esperar, ou continuar lendo.',
          feedback: 'Você se orientou no lugar, no tempo e no próximo minuto.',
        ),
        ExerciseStep(
          type: ExerciseStepType.closing,
          prompt:
              'Guarde o atalho desta prática para quando precisar: olhar, escutar ou sentir um ponto de apoio.',
          feedback:
              'Não é preciso repetir todas as etapas. Em outro momento, escolha só uma: acompanhe o contorno de um objeto, encontre um som ou sinta um apoio. Fazer menos também conta.',
        ),
      ],
      author: 'Equipe de conteúdo Íris (demonstração)',
      conceptualSource: 'OMS — Doing What Matters in Times of Stress',
      clinicalReviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      version: '2.0-demo',
      nextReviewDate: '2027-03-10',
      contraindications: <String>[
        'Em crise aguda, procure ajuda urgente antes de praticar.',
      ],
    ),
    Exercise(
      id: 'notice-and-name',
      title: 'Perceber e nomear',
      goal: 'Dar um nome aproximado ao que acontece e voltar ao que importa.',
      durationMinutes: 3,
      supportedFormats: {SupportFormat.interactive, SupportFormat.audio},
      needs: [SupportNeed.nameFeelings],
      steps: <ExerciseStep>[
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt:
              'Pare por um instante antes de explicar ou resolver o que sente.',
          guidance:
              'Só observe: há uma frase repetindo na mente, uma emoção mais forte, uma sensação física, ou uma mistura? Não procure a resposta perfeita; basta notar o que aparece primeiro.',
          feedback: 'Observar vem antes de tentar consertar.',
        ),
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Dê uma etiqueta provisória para essa experiência.',
          guidance:
              'Experimente dizer em pensamento: “Agora há preocupação”, “agora há tristeza”, “agora há confusão” ou simplesmente “agora não sei”. A etiqueta pode mudar; ela não precisa explicar tudo.',
          feedback: 'Uma palavra aproximada já cria alguma organização.',
        ),
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Amplie o quadro antes de seguir.',
          guidance:
              'Complete: “Há ___ em mim e também há ___ ao meu redor.” Por exemplo: “Há ansiedade em mim e também há uma cadeira me apoiando.” Depois escolha uma tarefa mínima para os próximos minutos.',
          feedback:
              'A sensação está presente, mas não é a única coisa presente.',
        ),
        ExerciseStep(
          type: ExerciseStepType.closing,
          prompt:
              'Use este percurso como um check-in breve: notar, nomear e refocar.',
          feedback:
              'Na próxima vez, tente uma frase completa: “Agora há ___ em mim; ainda posso ___ por um minuto.” O final pode ser pequeno: tomar banho, responder uma mensagem, sentar ou pedir companhia.',
        ),
      ],
      author: 'Equipe de conteúdo Íris (demonstração)',
      conceptualSource: 'OMS — Doing What Matters in Times of Stress',
      clinicalReviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      version: '2.0-demo',
      nextReviewDate: '2027-03-10',
      contraindications: <String>[
        'Em crise aguda, procure ajuda urgente antes de praticar.',
      ],
    ),
    Exercise(
      id: 'space-for-thought',
      title: 'Dar espaço ao pensamento',
      goal:
          'Reduzir o piloto automático de um pensamento sem precisar debatê-lo.',
      durationMinutes: 3,
      supportedFormats: {SupportFormat.interactive, SupportFormat.audio},
      needs: [SupportNeed.difficultThought],
      steps: <ExerciseStep>[
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Traga o pensamento insistente para uma frase curta.',
          guidance:
              'Sem escrever nem compartilhar, formule mentalmente: “Estou tendo o pensamento de que ___.” Use poucas palavras. Se não quiser tocar no conteúdo, diga apenas: “Há um pensamento difícil aqui.”',
          feedback:
              'Você está notando o pensamento, em vez de ficar totalmente dentro dele.',
        ),
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Dê a esse pensamento o nome de uma história conhecida.',
          guidance:
              'Pode ser “a história de que vou falhar”, “a história do nunca é suficiente” ou qualquer nome simples. O nome não nega o problema; só lembra que sua mente está contando uma versão dele agora.',
          feedback:
              'Uma história pode aparecer muitas vezes sem precisar comandar você.',
        ),
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Reconheça a história e responda com uma frase de distância.',
          guidance:
              'Experimente: “Obrigado, mente. Percebi essa história.” Depois olhe para um objeto à frente ou sinta os pés apoiados. Não tente expulsar o pensamento; deixe-o ficar enquanto você muda o foco por alguns segundos.',
          feedback:
              'Você praticou ficar com o pensamento sem obedecer a ele automaticamente.',
        ),
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Direcione-se para uma ação de dois minutos.',
          guidance:
              'Escolha algo neutro e possível: abrir uma janela, voltar a uma tarefa por dois minutos, lavar o rosto, sentar perto de alguém ou pedir companhia. O objetivo é se mover na direção escolhida, não eliminar o pensamento.',
          feedback:
              'Uma ação pequena pode coexistir com um pensamento difícil.',
        ),
        ExerciseStep(
          type: ExerciseStepType.closing,
          prompt:
              'Quando essa história voltar, repita a sequência: notar, nomear e dar um passo de dois minutos.',
          feedback:
              'A meta não é vencer nem provar que o pensamento está errado. É recuperar uma escolha. Se ele trouxer medo de agir, risco ou sensação de não conseguir se manter em segurança, pare e procure ajuda humana.',
        ),
      ],
      author: 'Equipe de conteúdo Íris (demonstração)',
      conceptualSource: 'OMS — Doing What Matters in Times of Stress',
      clinicalReviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      version: '2.0-demo',
      nextReviewDate: '2027-03-10',
      contraindications: <String>[
        'Em crise aguda, procure ajuda urgente antes de praticar.',
      ],
    ),
    Exercise(
      id: 'talk-to-me-kindly',
      title: 'Falar comigo como com alguém querido',
      goal: 'Trocar autocrítica automática por um cuidado possível e concreto.',
      durationMinutes: 3,
      supportedFormats: {SupportFormat.interactive, SupportFormat.audio},
      needs: [SupportNeed.selfKindness],
      steps: <ExerciseStep>[
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Perceba a regra dura que você está usando contra si.',
          guidance:
              'Complete em pensamento: “Eu deveria ___.” Agora imagine uma pessoa querida na mesma situação. Você usaria exatamente essa mesma regra com ela? Só note a diferença de tom, sem se cobrar para mudar de imediato.',
          feedback:
              'Perceber a cobrança é o primeiro passo para não deixá-la dirigir tudo.',
        ),
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Troque o veredito por uma frase honesta e útil.',
          guidance:
              'Experimente uma destas estruturas: “Isso está difícil e eu posso ir devagar”; “Não preciso resolver tudo agora”; ou “Posso pedir ajuda antes de decidir.” Ajuste as palavras até soarem naturais para você.',
          feedback:
              'Uma frase gentil não precisa parecer perfeita para ser utilizável.',
        ),
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Converta essa frase em um cuidado observável.',
          guidance:
              'Nos próximos dez minutos, escolha uma única forma de agir como falaria com alguém querido: reduzir uma exigência, fazer uma pausa sem se justificar, beber água, mudar de ambiente ou mandar “você pode ficar comigo um pouco?”.',
          feedback: 'Cuidado é algo que pode ser feito em tamanho pequeno.',
        ),
        ExerciseStep(
          type: ExerciseStepType.closing,
          prompt:
              'Quando a autocrítica aparecer, faça uma pergunta prática: “Qual é o cuidado possível agora?”',
          feedback:
              'Gentileza não é fingir que está tudo bem. É substituir uma cobrança que machuca por uma escolha que protege: diminuir, pausar, pedir ou adiar. Escolha apenas uma para hoje.',
        ),
      ],
      author: 'Equipe de conteúdo Íris (demonstração)',
      conceptualSource: 'OMS — Doing What Matters in Times of Stress',
      clinicalReviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      version: '2.0-demo-preview',
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
      goal: 'Sair da paralisia com um passo pequeno, verificável e ajustável.',
      durationMinutes: 2,
      supportedFormats: {SupportFormat.interactive, SupportFormat.audio},
      needs: [SupportNeed.nextSafeStep],
      steps: <ExerciseStep>[
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt:
              'Olhe só para os próximos dez minutos, não para o dia inteiro.',
          guidance:
              'Pergunte em silêncio: “Do que preciso mais agora: companhia, menos estímulo, uma pausa ou apoio profissional?” Não tente resolver a causa inteira; identifique apenas o tipo de apoio que falta neste momento.',
          feedback:
              'Uma necessidade clara é mais fácil de transformar em ação.',
        ),
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt:
              'Transforme a necessidade em uma frase que caiba em cinco minutos.',
          guidance:
              'Use este molde: “Nos próximos cinco minutos, eu vou ___.” Exemplos: “mandar uma mensagem curta”, “ir para outro cômodo”, “sentar perto de alguém” ou “anotar o que preciso falar na consulta”.',
          feedback:
              'Quanto mais concreto o passo, menos ele precisa depender de motivação.',
        ),
        ExerciseStep(
          type: ExerciseStepType.guidedPractice,
          prompt: 'Diminua o primeiro movimento até ele ficar possível agora.',
          guidance:
              'Se mandar uma mensagem parece muito, abra a conversa. Se sair do ambiente parece muito, levante ou vá até a porta. Se falar com o profissional parece muito, escreva uma palavra. Começar menor é permitido.',
          feedback:
              'Você não precisa estar pronto para dar o primeiro movimento.',
        ),
        ExerciseStep(
          type: ExerciseStepType.closing,
          prompt: 'Leve apenas o primeiro movimento, não a lista inteira.',
          feedback:
              'Se o plano deixar de parecer seguro ou possível, mude-o. Um passo menor, a companhia de alguém ou ajuda urgente podem ser o próximo passo mais adequado. Você não precisa fazer isso sozinho.',
        ),
      ],
      author: 'Equipe de conteúdo Íris (demonstração)',
      conceptualSource: 'OMS — Doing What Matters in Times of Stress',
      clinicalReviewer: 'Dra. Ana Ribeiro, psicóloga (revisão fictícia)',
      version: '2.0-demo-preview',
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
