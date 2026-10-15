import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/forms/date_input_formatter.dart';

void main() {
  const formatter = DateInputFormatter();

  TextEditingValue edit(String text) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );

  test('insere barras assim que completa dia e mês', () {
    var current = const TextEditingValue();
    final expected = ['1', '12/', '12/0', '12/03/', '12/03/2'];
    final digits = '12032'.split('');
    for (var index = 0; index < digits.length; index++) {
      current = formatter.formatEditUpdate(
        current,
        edit('${current.text}${digits[index]}'),
      );
      expect(current.text, expected[index]);
      expect(current.selection.baseOffset, current.text.length);
    }
  });

  test('permite apagar a data inteira sem prender o cursor nas barras', () {
    var current = edit('12/03/1996');
    while (current.text.isNotEmpty) {
      final oldLength = current.text.length;
      current = formatter.formatEditUpdate(
        current,
        edit(current.text.substring(0, current.text.length - 1)),
      );
      expect(current.text.length, lessThan(oldLength));
      expect(current.selection.baseOffset, current.text.length);
    }
  });

  test('apagar uma barra interna permite continuar apagando dígitos', () {
    final result = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '12/03/1996',
        selection: TextSelection.collapsed(offset: 3),
      ),
      const TextEditingValue(
        text: '1203/1996',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(result.text, '12/03/1996');
    expect(result.selection.baseOffset, 2);
    final next = formatter.formatEditUpdate(
      result,
      const TextEditingValue(
        text: '1/03/1996',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    expect(next.text, '10/31/996');
    expect(next.selection.baseOffset, 1);
  });

  test('preserva seleção e composição do teclado', () {
    final selected = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: '12031996',
        selection: TextSelection(baseOffset: 2, extentOffset: 4),
      ),
    );
    expect(
      selected.selection,
      const TextSelection(baseOffset: 2, extentOffset: 5),
    );
    const composing = TextEditingValue(
      text: '12',
      composing: TextRange(start: 0, end: 2),
      selection: TextSelection.collapsed(offset: 2),
    );
    expect(
      formatter.formatEditUpdate(const TextEditingValue(), composing),
      composing,
    );
  });

  test('formata próxima consulta preservando texto e horário', () {
    const summaryFormatter = DateInputFormatter(allowText: true);
    for (final text in ['A definir', 'Sem consulta', 'Hoje, 09:30']) {
      expect(
        summaryFormatter.formatEditUpdate(edit(''), edit(text)).text,
        text,
      );
    }
    final pasted = summaryFormatter.formatEditUpdate(
      edit(''),
      edit('12082026, 09:30'),
    );
    expect(pasted.text, '12/08/2026, 09:30');
    expect(pasted.selection.baseOffset, pasted.text.length);
    expect(
      summaryFormatter.formatEditUpdate(edit(''), edit('12/08 às 09:00')).text,
      '12/08 às 09:00',
    );
  });

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
