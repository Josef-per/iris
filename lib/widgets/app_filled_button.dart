import 'package:flutter/material.dart';

class AppFilledButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final List<BoxShadow>? boxShadow;

  const AppFilledButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.width = 159,
    this.height = 48,
    this.borderRadius = 16,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: boxShadow ?? const [],
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: Size(width ?? 0, height),
            maximumSize: Size(double.infinity, height),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: fontWeight,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }
}
