import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/ai_support/data/daily_companion_repository.dart';
import 'package:iris/features/ai_support/domain/daily_companion_message.dart';

void main() {
  test('aceita somente uma reflexao diaria completa e dentro dos limites', () {
    final message = decodeDailyCompanionMessage(<String, Object?>{
      'status': 'ready',
      'title': 'Um passo de cada vez',
      'message':
          'Talvez seja suficiente escolher um próximo passo pequeno e observar como ele fica para você.',
      'reflectionQuestion':
          'O que poderia deixar os próximos minutos um pouco mais possíveis?',
    });

    expect(message.status, DailyCompanionStatus.ready);
    expect(message.isPersonalized, isTrue);
    expect(message.reflectionQuestion, contains('próximos minutos'));
  });

  test('mantem resposta sem conteudo personalizado em estado seguro', () {
    final message = decodeDailyCompanionMessage(<String, Object?>{
      'status': 'waiting_for_context',
    });

    expect(message.status, DailyCompanionStatus.waitingForContext);
    expect(message.message, isNull);
  });

  test('rejeita resposta pronta sem limites ou campos obrigatorios', () {
    expect(
      () => decodeDailyCompanionMessage(<String, Object?>{
        'status': 'ready',
        'title': 'Oi',
        'message': 'Curta demais',
        'reflectionQuestion': null,
      }),
      throwsFormatException,
    );
  });

  test('preserva o markdown restrito da reflexão', () {
    const markdown =
        'Talvez ajude separar o que precisa de atenção agora do que pode esperar:\n\n'
        '- **Agora:** uma prioridade possível.\n'
        '- **Depois:** decisões que não são urgentes.';
    final message = decodeDailyCompanionMessage(<String, Object?>{
      'status': 'ready',
      'title': 'Uma prioridade de cada vez',
      'message': markdown,
      'reflectionQuestion': null,
    });

    expect(message.message, markdown);
  });

  test('rejeita links no markdown da reflexão', () {
    expect(
      () => decodeDailyCompanionMessage(<String, Object?>{
        'status': 'ready',
        'title': 'Uma prioridade de cada vez',
        'message':
            'Talvez ajude organizar uma prioridade.\n\n- **Agora:** [abra este link](https://example.com).',
        'reflectionQuestion': null,
      }),
      throwsFormatException,
    );
  });
}
