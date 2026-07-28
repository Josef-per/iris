import 'package:flutter/material.dart';
import 'package:iris/widgets/app_lembretes_content.dart';

class AppLembretesListMedicamentos extends StatefulWidget {
  const AppLembretesListMedicamentos({super.key});

  @override
  State<AppLembretesListMedicamentos> createState() => AppLembretesListState();
}

class AppLembretesListState extends State<AppLembretesListMedicamentos> {
  bool ativo = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: AppLembretesContent(
            gradientIconColor1: Color(0xFF28174E),
            gradientIconColor2: Color(0xFF5C35B4),
            iconPath: 'assets/icons/FrascoRemedio_white.png',
            textName: 'Vitamina D',
            textTime: '8h00',
            isActive: ativo,
            onSwitchChanged: (value) {
              setState(() {
                ativo = value;
              });
            },
          ),
        ),
      ],
    );
  }
}
