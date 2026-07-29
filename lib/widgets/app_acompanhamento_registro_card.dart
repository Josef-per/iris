import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AppAcompanhamentoRegistroCard extends StatelessWidget {
  const AppAcompanhamentoRegistroCard({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFAF9F6), AppColors.lavender, AppColors.purple],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3328174E),
            blurRadius: 5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.ink, size: 23),
        ],
      ),
    );
  }
}
