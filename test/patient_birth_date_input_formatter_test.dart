import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/profile/patient_birth_date_input_formatter.dart';

void main() {
  const formatter = PatientBirthDateInputFormatter();

  test('formata digitos, cola datas e limita a oito digitos', () {
    const empty = TextEditingValue();
    var current = empty;
    for (final digit in '11032007'.split('')) {
      current = formatter.formatEditUpdate(
        current,
        TextEditingValue(
          text: '${current.text}$digit',
          selection: TextSelection.collapsed(offset: current.text.length + 1),
        ),
      );
    }
    expect(current.text, '11/03/2007');

    final typed = formatter.formatEditUpdate(
      empty,
      const TextEditingValue(
        text: '11032007',
        selection: TextSelection.collapsed(offset: 8),
      ),
    );
    expect(typed.text, '11/03/2007');
    expect(typed.selection.baseOffset, 10);

    final pasted = formatter.formatEditUpdate(
      empty,
      const TextEditingValue(
        text: '11/03/200799',
        selection: TextSelection.collapsed(offset: 12),
      ),
    );
    expect(pasted.text, '11/03/2007');
    expect(pasted.selection.baseOffset, 10);
  });

  test('mantem cursor ao editar no meio da data', () {
    final edited = formatter.formatEditUpdate(
      const TextEditingValue(text: '11/03/2007'),
      const TextEditingValue(
        text: '12/03/2007',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(edited.text, '12/03/2007');
    expect(edited.selection.baseOffset, 2);
  });
}
