import 'package:flutter/material.dart';
import 'app_filled_button.dart';

class AppAlignFilledButton extends StatelessWidget {
  final String TextButton;
  final Color BackgroundColor;
  final Color TextColor;
  final VoidCallback onPressed;

  const AppAlignFilledButton({
    super.key,
    required this.TextButton,
    required this.BackgroundColor,
    required this.TextColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 150,
        child: AppFilledButton(
          text: TextButton,
          backgroundColor: BackgroundColor,
          textColor: TextColor,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
