import 'package:flutter/material.dart';

class AppCheckInHeader extends StatelessWidget {
  final String TextTitle;
  final String TextSubTitle;

  const AppCheckInHeader({
    super.key,
    required this.TextTitle,
    required this.TextSubTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TextTitle,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFFFFF),
          ),
        ),

        const SizedBox(height: 7),

        Text(
          TextSubTitle,
          style: TextStyle(fontSize: 14, color: const Color(0x99FFFFFF)),
        ),

        const SizedBox(height: 28),
      ],
    );
  }
}
