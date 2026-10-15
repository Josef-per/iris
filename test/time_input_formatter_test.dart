import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/forms/time_input_formatter.dart';

void main() {
  const formatter = TimeInputFormatter();
  TextEditingValue edit(String text) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );

  test('digita só números e insere dois-pontos depois da hora', () {
    var current = edit('');
    const expected = ['0', '09:', '09:3', '09:30'];
    for (var index = 0; index < expected.length; index++) {
      current = formatter.formatEditUpdate(
        current,
        edit('${current.text}${'0930'[index]}'),
      );
      expect(current.text, expected[index]);
      expect(current.selection.baseOffset, current.text.length);
    }
  });

  test('cola horários e limita a quatro dígitos', () {
    for (final input in ['0930', '09:30', '9:30', '09:30999']) {
      final result = formatter.formatEditUpdate(edit(''), edit(input));
      expect(result.text, '09:30');
      expect(result.selection.baseOffset, 5);
    }
    expect(formatter.formatEditUpdate(edit(''), edit('44444')).text, '44:44');
  });

  test('permite apagar tudo inclusive os dois-pontos', () {
    var current = edit('09:30');
    while (current.text.isNotEmpty) {
      final oldLength = current.text.length;
      current = formatter.formatEditUpdate(
        current,
        edit(current.text.substring(0, oldLength - 1)),
      );
      expect(current.text.length, lessThan(oldLength));
      expect(current.selection.baseOffset, current.text.length);
    }
  });

  test('mantém cursor e seleção ao editar no meio', () {
    final result = formatter.formatEditUpdate(
      edit('09:30'),
      const TextEditingValue(
        text: '10:30',
        selection: TextSelection(baseOffset: 0, extentOffset: 2),
      ),
    );
    expect(result.text, '10:30');
    expect(
      result.selection,
      const TextSelection(baseOffset: 0, extentOffset: 2),
    );
    final deleted = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '10:30',
        selection: TextSelection.collapsed(offset: 3),
      ),
      const TextEditingValue(
        text: '1030',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(deleted.text, '10:30');
    expect(deleted.selection.baseOffset, 2);
  });
}
