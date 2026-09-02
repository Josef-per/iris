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
      'reflectionQuestion': 'O que poderia deixar os próximos minutos um pouco mais possíveis?',
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
}
