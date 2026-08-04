import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/widgets/app_switch_lembretes.dart';

enum SettingsItemIndicatorType { toggle, arrow }

class SettingsItemIndicator extends StatelessWidget {
  const SettingsItemIndicator({
    super.key,
    required this.type,
    this.value = true,
    this.onChanged,
  });

  final SettingsItemIndicatorType type;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      SettingsItemIndicatorType.toggle => IgnorePointer(
        ignoring: onChanged == null,
        child: AppSwitchLembretes(
          value: value,
          onChanged: onChanged ?? _doNothing,
        ),
      ),
      SettingsItemIndicatorType.arrow => const Icon(
        Icons.chevron_right,
        color: AppColors.ink,
        size: 24,
      ),
    };
  }
}

void _doNothing(bool _) {}
