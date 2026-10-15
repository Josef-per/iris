import 'package:flutter/services.dart';

/// Máscara DD/MM/AAAA, com texto livre opcional para resumos de consultas.
class DateInputFormatter extends TextInputFormatter {
  const DateInputFormatter({this.allowText = false});

  final bool allowText;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }

    var input = newValue.text;
    var suffix = '';
    if (allowText) {
      final prefix = RegExp(r'^[\d/]+').firstMatch(input);
      if (prefix == null) return newValue;
      suffix = input.substring(prefix.end);
      input = input.substring(0, prefix.end);
    }

    final digits = input.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;
    final deleting = newValue.text.length < oldValue.text.length;
    final buffer = StringBuffer();
    for (var index = 0; index < limitedDigits.length; index++) {
      buffer.write(limitedDigits[index]);
      if ((index == 1 || index == 3) &&
          (index < limitedDigits.length - 1 || (!deleting && suffix.isEmpty))) {
        buffer.write('/');
      }
    }
    final formatted = buffer.toString();

    int cursorOffset(int offset) {
      final cursor = offset.clamp(0, newValue.text.length);
      if (cursor > input.length) {
        return formatted.length + cursor - input.length;
      }
      final digitsBeforeCursor = input
          .substring(0, cursor)
          .replaceAll(RegExp(r'\D'), '')
          .length
          .clamp(0, limitedDigits.length);
      var result = 0;
      var passedDigits = 0;
      while (result < formatted.length && passedDigits < digitsBeforeCursor) {
        if (formatted[result] != '/') passedDigits++;
        result++;
      }
      // Avança sobre uma barra já existente ou recém-inserida ao digitar.
      if (result < formatted.length &&
          formatted[result] == '/' &&
          ((cursor > 0 && input[cursor - 1] == '/') ||
              (!deleting && cursor == input.length))) {
        result++;
      }
      return result;
    }

    return TextEditingValue(
      text: '$formatted$suffix',
      selection: TextSelection(
        baseOffset: cursorOffset(newValue.selection.baseOffset),
        extentOffset: cursorOffset(newValue.selection.extentOffset),
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
    );
  }
}
