import 'package:flutter/material.dart';
import 'app_filled_button.dart';

class AppAlignFilledButton extends StatelessWidget {
  final String textButton;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const AppAlignFilledButton({
    super.key,
    required this.textButton,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 150,
        child: AppFilledButton(
          text: textButton,
          backgroundColor: backgroundColor,
          textColor: textColor,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
