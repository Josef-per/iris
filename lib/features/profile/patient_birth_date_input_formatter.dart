import 'package:flutter/services.dart';

class PatientBirthDateInputFormatter extends TextInputFormatter {
  const PatientBirthDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();
    for (var index = 0; index < limitedDigits.length; index++) {
      if (index == 2 || index == 4) buffer.write('/');
      buffer.write(limitedDigits[index]);
    }
    final formatted = buffer.toString();

    final cursor = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final digitsBeforeCursor = newValue.text
        .substring(0, cursor)
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, limitedDigits.length);
    var formattedCursor = 0;
    var passedDigits = 0;
    while (formattedCursor < formatted.length &&
        passedDigits < digitsBeforeCursor) {
      if (formatted[formattedCursor] != '/') passedDigits++;
      formattedCursor++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formattedCursor),
    );
  }
}
