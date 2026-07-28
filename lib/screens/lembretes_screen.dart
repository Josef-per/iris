import 'package:flutter/material.dart';
import 'package:iris/widgets/app_filled_button_pre_icon.dart';
import 'package:iris/widgets/app_function_gradient_decoration.dart';
import 'package:iris/widgets/app_function_headers.dart';
import 'package:iris/widgets/app_lembretes_field.dart';
import 'package:iris/widgets/app_lembretes_list_medicamentos.dart';
import 'package:iris/widgets/app_lembretes_list_refeicao.dart';
import 'package:iris/widgets/app_reminder_form.dart';

class LembretesScreen extends StatefulWidget {
  const LembretesScreen({super.key});

  @override
  State<LembretesScreen> createState() => _LembretesScreenState();
}

class _LembretesScreenState extends State<LembretesScreen> {
  bool _showNewReminder = false;

  @override
  Widget build(BuildContext context) {
    return AppFunctionGradientDecoration(
      gradientHeight: 237,
      gradientColors: const [Color(0xFF7D6AC6), Color(0xFF28174E)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomRight,
      contentPadding: const EdgeInsets.fromLTRB(30, 30, 30, 48),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 33),
                    child: AppFunctionHeaders(
                      onTap: () {},
                      title: 'Lembretes',
                      subTitle: 'Gerencie seus lembretes diários',
                      iconToTitleSpacing: 27,
                      titleToSubtitleSpacing: 4,
                      bottomSpacing: 26,
                      titleStyle: const TextStyle(
                        fontSize: 28,
                        color: Color(0xFFFAF9F6),
                      ),
                      subTitleStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFDDD7EE),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: AppFilledButtonPreIcon(
                    onTap: () => setState(() => _showNewReminder = true),
                    icon: 'assets/icons/Add_purple.png',
                    text: 'Adicionar lembrete',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_showNewReminder) ...[
            AppReminderForm(
              onCancel: () => setState(() => _showNewReminder = false),
            ),
            const SizedBox(height: 30),
          ],
          const AppLembretesField(
            iconSection: 'assets/icons/GarfoColher_purple.png',
            textSection: 'Refeições',
          ),
          const SizedBox(height: 16),
          const AppLembretesListRefeicao(),
          const SizedBox(height: 32),
          const AppLembretesField(
            iconSection: 'assets/icons/FrascoRemedio_purple.png',
            textSection: 'Medicamentos',
          ),
          const SizedBox(height: 16),
          const AppLembretesListMedicamentos(),
        ],
      ),
    );
  }
}
