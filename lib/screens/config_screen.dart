import 'package:flutter/material.dart';
import 'package:iris/widgets/app_function_gradient_decoration.dart';
import 'package:iris/widgets/app_function_headers.dart';
import 'package:iris/widgets/app_nav_acompanhamento.dart';
import 'package:iris/widgets/config/emergency_contacts_section.dart';
import 'package:iris/widgets/config/settings_section.dart';
import 'package:iris/widgets/config/profile_personal_section.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFunctionGradientDecoration(
      gradientHeight: 232,
      gradientColors: const [
        Color(0xFF7D6AC6),
        Color(0xFF462A7E),
        Color(0xFF28174E),
      ],
      contentPadding: const EdgeInsets.fromLTRB(27, 50, 27, 32),
      content: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: AppFunctionHeaders(
            onTap: _doNothing,
            title: 'Perfil e Ajustes',
            subTitle: 'Gerencie as suas configura\u{00E7}\u{00F5}es',
            bottomSpacing: 36,
            acompanhamentoItems: const [
              AppNavAcompanhamentoItem(
                label: 'Pessoal',
                iconPath: 'assets/icons/Perfil_white.png',
                isSelected: true,
              ),
              AppNavAcompanhamentoItem(
                label: 'Contatos',
                iconPath: 'assets/icons/Contatos_purple.png',
              ),
              AppNavAcompanhamentoItem(
                label: 'Config.',
                iconPath: 'assets/icons/Config_purple.png',
              ),
            ],
            acompanhamentoContents: const [
              ProfilePersonalSection(),
              EmergencyContactsSection(),
              SettingsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

void _doNothing() {}
