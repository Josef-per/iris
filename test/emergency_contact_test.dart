import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/emergency_contact/emergency_contact.dart';
import 'package:iris/features/emergency_contact/emergency_contact_editor.dart';
import 'package:iris/features/emergency_contact/emergency_contact_repository.dart';

class _Source implements EmergencyContactDataSource {
  EmergencyContact? contact;
  int saves = 0;

  @override
  Future<EmergencyContact?> load() async => contact;

  @override
  Future<void> save(EmergencyContact value) async {
    contact = value;
    saves++;
  }

  @override
  Future<void> delete() async => contact = null;
}

void main() {
  test('telefone só aceita número discável e remove formatação', () {
    expect(EmergencyContact.normalizePhone('(11) 99999-9999'), '11999999999');
    expect(
      EmergencyContact.normalizePhone('+55 11 99999-9999'),
      '+5511999999999',
    );
    expect(EmergencyContact.normalizePhone('192'), isNull);
    expect(EmergencyContact.normalizePhone('1199999;192'), isNull);
  });

  testWidgets('paciente cadastra, edita e remove seu contato', (tester) async {
    final source = _Source();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EmergencyContactEditor(dataSource: source),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum contato cadastrado.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('emergency-contact-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('emergency-contact-name')),
      'Ana',
    );
    await tester.enterText(
      find.byKey(const Key('emergency-contact-phone')),
      '123',
    );
    await tester.tap(find.byKey(const Key('emergency-contact-save')));
    await tester.pumpAndSettle();
    expect(source.saves, 0);
    expect(find.text('Informe um telefone válido com DDD.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('emergency-contact-phone')),
      '(11) 99999-9999',
    );
    await tester.tap(find.byKey(const Key('emergency-contact-save')));
    await tester.pumpAndSettle();
    expect(source.contact?.phone, '11999999999');
    expect(find.text('Ana'), findsOneWidget);

    await tester.tap(find.byKey(const Key('emergency-contact-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('emergency-contact-name')),
      'Bia',
    );
    await tester.tap(find.byKey(const Key('emergency-contact-save')));
    await tester.pumpAndSettle();
    expect(source.contact?.name, 'Bia');

    await tester.tap(find.byKey(const Key('emergency-contact-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover').last);
    await tester.pumpAndSettle();
    expect(source.contact, isNull);
    expect(find.text('Nenhum contato cadastrado.'), findsOneWidget);
  });
}
