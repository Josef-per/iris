import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/ai_support/data/ai_support_event_repository.dart';
import 'package:iris/features/ai_support/data/remote_ai_recommender.dart';

void main() {
  test('aceita UUID opaco e rejeita ID local descritivo', () {
    expect(isAiSupportUuid('0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46'), isTrue);
    expect(isAiSupportUuid('support-checkin-patient-1'), isFalse);
  });

  test('eventos e canais usam allowlist fechada', () {
    expect(AiSupportEventType.opened.wireName, 'aberta');
    expect(AiSupportEventType.dismissed.wireName, 'dispensada');
    expect(
      AiSupportEventChannel.localNotification.wireName,
      'local_notification',
    );
  });
}
