import 'package:flutter/services.dart';

/// Insere os dois-pontos de HH:mm ao digitar apenas números.
class TimeInputFormatter extends TextInputFormatter {
  const TimeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }

    final singleDigitHour = RegExp(r'^\d:\d{2}$').hasMatch(newValue.text);
    final rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digits = singleDigitHour ? '0$rawDigits' : rawDigits;
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final deleting = newValue.text.length < oldValue.text.length;
    final formatted = limited.length < 2 || (limited.length == 2 && deleting)
        ? limited
        : '${limited.substring(0, 2)}:${limited.substring(2)}';

    int cursorOffset(int offset) {
      final cursor = offset.clamp(0, newValue.text.length);
      final count =
          (newValue.text
                      .substring(0, cursor)
                      .replaceAll(RegExp(r'\D'), '')
                      .length +
                  (singleDigitHour && cursor > 0 ? 1 : 0))
              .clamp(0, limited.length);
      var result = count + (count > 2 ? 1 : 0);
      if (count == 2 &&
          formatted.length > 2 &&
          ((cursor > 0 && newValue.text[cursor - 1] == ':') ||
              (!deleting && cursor == newValue.text.length))) {
        result++;
      }
      return result;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection(
        baseOffset: cursorOffset(newValue.selection.baseOffset),
        extentOffset: cursorOffset(newValue.selection.extentOffset),
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
    );
  }
}
