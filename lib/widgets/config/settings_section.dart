import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsCategoryHeader(
            icon: Icons.notifications_none_outlined,
            title: 'Notifica\u{00E7}\u{00E3}o',
          ),
          SizedBox(height: 28),
          SettingsItem(
            title: 'Ativar notifica\u{00E7}\u{00F5}es',
            subtitle: 'Receba lembretes e alertas',
            indicator: SettingsItemIndicator.toggle,
          ),
          SizedBox(height: 10),
          SettingsItem(
            title: 'Sons',
            subtitle: 'Sons de notifica\u{00E7}\u{00E3}o',
            indicator: SettingsItemIndicator.toggle,
          ),
          SizedBox(height: 10),
          SettingsItem(
            title: 'Vibra\u{00E7}\u{00E3}o',
            subtitle: 'Vibrar ao receber uma notifica\u{00E7}\u{00E3}o',
            indicator: SettingsItemIndicator.toggle,
          ),
          _SectionDivider(),
          _SettingsCategoryHeader(
            icon: Icons.dark_mode_outlined,
            title: 'Apar\u{00EA}ncia',
          ),
          SizedBox(height: 28),
          SettingsItem(
            title: 'Modo escuro',
            subtitle: 'Tema escuro para o aplicativo',
            indicator: SettingsItemIndicator.toggle,
          ),
          SizedBox(height: 10),
          _LanguageSettingsItem(),
          _SectionDivider(),
          _SettingsCategoryHeader(
            icon: Icons.lock_outline,
            title: 'Privacidade e seguran\u{00E7}a',
          ),
          SizedBox(height: 28),
          SettingsItem(
            title: 'Autentica\u{00E7}\u{00E3}o biom\u{00E9}trica',
            subtitle: 'Usar impress\u{00E3}o digital/Face ID',
            indicator: SettingsItemIndicator.toggle,
          ),
        ],
      ),
    );
  }
}

enum SettingsItemIndicator { toggle, arrow }

class SettingsItem extends StatelessWidget {
  const SettingsItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.indicator = SettingsItemIndicator.arrow,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final SettingsItemIndicator indicator;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 63,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.deepPurple,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (indicator == SettingsItemIndicator.toggle)
                const _StaticSettingsSwitch()
              else
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.ink,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCategoryHeader extends StatelessWidget {
  const _SettingsCategoryHeader({required this.icon, required this.title});

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

class _LanguageSettingsItem extends StatelessWidget {
  const _LanguageSettingsItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsCategoryHeader(
            icon: Icons.language_outlined,
            title: 'Idioma',
          ),
          const SizedBox(height: 8),
          Container(
            height: 37,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.deepPurple),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Portugu\u{00EA}s (Brasil)',
                    style: TextStyle(
                      color: AppColors.deepPurple,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: AppColors.ink),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticSettingsSwitch extends StatelessWidget {
  const _StaticSettingsSwitch();

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: true,
      onChanged: (_) {},
      activeThumbColor: AppColors.white,
      activeTrackColor: AppColors.deepPurple,
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
