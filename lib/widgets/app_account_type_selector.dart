import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AppAccountTypeSelector extends StatelessWidget {
  const AppAccountTypeSelector({
    super.key,
    required this.isProfessional,
    required this.onChanged,
    this.enabled = true,
  });

  final bool isProfessional;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AccountTypeButton(
            icon: Icons.favorite_outline_rounded,
            label: 'Sou paciente',
            selected: !isProfessional,
            onTap: enabled ? () => onChanged(false) : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AccountTypeButton(
            icon: Icons.medical_services_outlined,
            label: 'Sou profissional',
            selected: isProfessional,
            onTap: enabled ? () => onChanged(true) : null,
          ),
        ),
      ],
    );
  }
}

class _AccountTypeButton extends StatelessWidget {
  const _AccountTypeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? AppColors.lavender.withValues(alpha: dark ? .22 : .4)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? AppColors.purple
              : dark
              ? const Color(0xFF443653)
              : AppColors.outline,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? dark
                          ? AppColors.lavender
                          : AppColors.deepPurple
                    : AppColors.muted,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? dark
                            ? AppColors.lavender
                            : AppColors.ink
                      : AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
