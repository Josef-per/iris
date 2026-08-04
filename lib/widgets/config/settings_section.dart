import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/widgets/config/settings/language_settings.dart';
import 'package:iris/widgets/config/settings/settings_category_header.dart';
import 'package:iris/widgets/config/settings/settings_item.dart';
import 'package:iris/widgets/config/settings/settings_item_indicator.dart';

class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key});

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  var _notificationsEnabled = true;
  var _soundsEnabled = true;
  var _vibrationEnabled = true;
  var _darkModeEnabled = true;
  var _biometricAuthenticationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsCategoryHeader(
            icon: Icons.notifications_none_outlined,
            title: 'Notificações',
          ),
          const SizedBox(height: 28),
          SettingsItem(
            title: 'Ativar notificações',
            subtitle: 'Receba lembretes e alertas',
            indicatorType: SettingsItemIndicatorType.toggle,
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),
          const SizedBox(height: 10),
          SettingsItem(
            title: 'Sons',
            subtitle: 'Sons de notificação',
            indicatorType: SettingsItemIndicatorType.toggle,
            value: _soundsEnabled,
            onChanged: (value) {
              setState(() => _soundsEnabled = value);
            },
          ),
          const SizedBox(height: 10),
          SettingsItem(
            title: 'Vibração',
            subtitle: 'Vibrar ao receber uma notificação',
            indicatorType: SettingsItemIndicatorType.toggle,
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() => _vibrationEnabled = value);
            },
          ),
          const _SectionDivider(),
          const SettingsCategoryHeader(
            icon: Icons.dark_mode_outlined,
            title: 'Aparência',
          ),
          const SizedBox(height: 28),
          SettingsItem(
            title: 'Modo escuro',
            subtitle: 'Tema escuro para o aplicativo',
            indicatorType: SettingsItemIndicatorType.toggle,
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() => _darkModeEnabled = value);
            },
          ),
          const SizedBox(height: 10),
          const LanguageSettings(),
          const _SectionDivider(),
          const SettingsCategoryHeader(
            icon: Icons.lock_outline,
            title: 'Privacidade e segurança',
          ),
          const SizedBox(height: 28),
          SettingsItem(
            title: 'Autenticação biométrica',
            subtitle: 'Usar impressão digital/Face ID',
            indicatorType: SettingsItemIndicatorType.toggle,
            value: _biometricAuthenticationEnabled,
            onChanged: (value) {
              setState(() => _biometricAuthenticationEnabled = value);
            },
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(color: AppColors.purple, height: 1),
    );
  }
}
