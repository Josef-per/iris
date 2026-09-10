import 'package:flutter/material.dart';

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
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _AccountTypeButton(
                  icon: Icons.favorite_outline_rounded,
                  label: 'Sou paciente',
                  selected: !isProfessional,
                  onTap: enabled ? () => onChanged(false) : null,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _AccountTypeButton(
                  icon: Icons.medical_services_outlined,
                  label: 'Sou profissional',
                  selected: isProfessional,
                  onTap: enabled ? () => onChanged(true) : null,
                ),
              ),
            ],
          ),
        ),
      ),
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
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;
    final radius = BorderRadius.circular(12);

    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        animationDuration: const Duration(milliseconds: 180),
        color: selected ? colors.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected
                ? colors.primary.withValues(alpha: .35)
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
