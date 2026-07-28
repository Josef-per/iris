import 'package:flutter/material.dart';
import 'package:iris/widgets/app_lembretes_content.dart';

class AppLembretesListRefeicao extends StatefulWidget {
  const AppLembretesListRefeicao({super.key});

  @override
  State<AppLembretesListRefeicao> createState() => AppLembretesListState();
}

class AppLembretesListState extends State<AppLembretesListRefeicao> {
  final List<bool> _activeReminders = [true, true, true];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_activeReminders.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == _activeReminders.length - 1 ? 0 : 12,
          ),
          child: AppLembretesContent(
            gradientIconColor1: const Color(0xFFC38CFF),
            gradientIconColor2: const Color(0xFFE5D5FF),
            iconPath: 'assets/icons/GarfoColher_white.png',
            textName: 'Café da manhã',
            textTime: '8h00',
            isActive: _activeReminders[index],
            onSwitchChanged: (value) {
              setState(() => _activeReminders[index] = value);
            },
          ),
        );
      }),
    );
  }
}
