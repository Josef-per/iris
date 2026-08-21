import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

/// Cartão tocável com rótulo explícito (nunca apenas cor ou ícone), estado
/// selecionado anunciado por Semantics e área de toque mínima de 48 dp.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.highlight = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? subtitle;

  /// Destaca o cartão (ex.: “Ajuda urgente”) sem depender só de cor.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = highlight
        ? colors.errorContainer
        : selected
        ? colors.primaryContainer
        : colors.surface;
    final foreground = highlight
        ? colors.onErrorContainer
        : selected
        ? colors.onPrimaryContainer
        : colors.onSurface;
    final borderColor = highlight
        ? colors.error
        : selected
        ? colors.primary
        : colors.outlineVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: subtitle == null ? label : '$label. $subtitle',
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: borderColor, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSize.controlHeight + 8,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foreground),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: theme.textTheme.titleSmall?.copyWith(color: foreground)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: foreground.withValues(alpha: .8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded, color: foreground)
                  else
                    Icon(
                      Icons.radio_button_unchecked_rounded,
                      color: colors.outline,
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