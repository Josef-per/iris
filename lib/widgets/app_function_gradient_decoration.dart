import 'package:flutter/material.dart';

class AppFunctionGradientDecoration extends StatelessWidget {
  final Widget content;
  final double gradientHeight;
  final List<Color> gradientColors;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final EdgeInsetsGeometry contentPadding;

  const AppFunctionGradientDecoration({
    super.key,
    required this.content,
    this.gradientHeight = 330,
    this.gradientColors = const [
      Color(0xFF28174E),
      Color(0xFF53418A),
      Color(0xFF7D6AC6),
    ],
    this.gradientBegin = Alignment.centerLeft,
    this.gradientEnd = Alignment.centerRight,
    this.contentPadding = const EdgeInsets.symmetric(
      vertical: 30,
      horizontal: 30,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFFAF9F6),
          ),
          Container(
            width: double.infinity,
            height: gradientHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: gradientBegin,
                end: gradientEnd,
                colors: gradientColors,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(padding: contentPadding, child: content),
            ),
          ),
        ],
      ),
    );
  }
}
