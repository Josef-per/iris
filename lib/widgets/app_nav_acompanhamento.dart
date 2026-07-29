import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AppNavAcompanhamentoItem {
  const AppNavAcompanhamentoItem({
    required this.label,
    required this.iconPath,
    this.isSelected = false,
  });

  final String label;
  final String iconPath;
  final bool isSelected;
}

class AppNavAcompanhamentoBar extends StatelessWidget {
  const AppNavAcompanhamentoBar({super.key, required this.items});

  final List<AppNavAcompanhamentoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 134,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
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
          for (var index = 0; index < items.length; index++) ...[
            Expanded(child: _AppNavAcompanhamentoButton(item: items[index])),
            if (index < items.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _AppNavAcompanhamentoButton extends StatelessWidget {
  const _AppNavAcompanhamentoButton({required this.item});

  final AppNavAcompanhamentoItem item;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = item.isSelected
        ? AppColors.white
        : AppColors.ink;

    return Container(
      decoration: BoxDecoration(
        color: item.isSelected ? null : AppColors.white,
        gradient: item.isSelected
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.deepPurple, AppColors.lavender],
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3328174E),
            blurRadius: 5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(item.iconPath, width: 27, height: 27),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 14,
                height: 1.32,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
