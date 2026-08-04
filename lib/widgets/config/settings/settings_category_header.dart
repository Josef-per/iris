import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class SettingsCategoryHeader extends StatelessWidget {
  const SettingsCategoryHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: AppColors.ink),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
