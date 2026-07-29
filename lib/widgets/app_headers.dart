import 'package:flutter/material.dart';

class AppHeaders extends StatelessWidget {
  final String textTitle;
  final String textSubTitle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final double titleToSubtitleSpacing;
  final double bottomSpacing;

  const AppHeaders({
    super.key,
    required this.textTitle,
    required this.textSubTitle,
    this.titleStyle,
    this.subTitleStyle,
    this.titleToSubtitleSpacing = 7,
    this.bottomSpacing = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          textTitle,
          style:
              titleStyle ??
              const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
        ),

        SizedBox(height: titleToSubtitleSpacing),

        Text(
          textSubTitle,
          style:
              subTitleStyle ??
              const TextStyle(fontSize: 14, color: Color(0x99FFFFFF)),
        ),

        SizedBox(height: bottomSpacing),
      ],
    );
  }
}
