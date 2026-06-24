import 'package:flutter/material.dart';

class AppTextObservacoes extends StatelessWidget {
  final String TextLabel;
  final String TextHint;
  final int TextLinhas;

  const AppTextObservacoes({
    super.key,
    required this.TextLabel,
    required this.TextHint,
    required this.TextLinhas,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TextLabel,
          style: TextStyle(
            color: const Color(0xFF462A7E),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.format_quote_rounded,
                size: 28,
                color: Color(0xFF2D175E),
              ),

              const SizedBox(height: 10),

              TextFormField(
                maxLines: TextLinhas,
                decoration: InputDecoration(
                  hintText: TextHint,
                  hintStyle: const TextStyle(
                    color: Color(0xFF2D175E),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(color: Color(0xFF2D175E), fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
