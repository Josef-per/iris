import 'package:flutter/material.dart';

class AppFunctionGradientDecoration extends StatelessWidget {
  final Widget content;

  const AppFunctionGradientDecoration({super.key, required this.content});

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
            height: 330,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF28174E),
                  Color(0xFF53418A),
                  Color(0xFF7D6AC6),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 30,
                ),
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
