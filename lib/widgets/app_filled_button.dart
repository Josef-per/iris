import 'package:flutter/material.dart';

class AppFilledButton extends StatelessWidget {
  //parâmetros para uso
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;

  const AppFilledButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x64000000),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),

      child: FilledButton(
        //estilizando o botãos
        style: FilledButton.styleFrom(
          fixedSize: const Size(159, 48),
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
      ),
    );
  }
}
