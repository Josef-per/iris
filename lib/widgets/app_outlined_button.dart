import 'package:flutter/material.dart';

class AppOutlinedButton extends StatelessWidget {
  //Parâmetros
  final String text;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onPressed;

  const AppOutlinedButton({
    super.key,
    required this.text,
    required this.borderColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        fixedSize: const Size(159, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(width: 1, color: borderColor),
      ),

      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
