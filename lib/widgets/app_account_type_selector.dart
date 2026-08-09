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
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
          side: BorderSide(
            color: selected ? colors.primary : colors.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.medium,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(height: 7),
                SizedBox(
                  height: 36,
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: selected
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
