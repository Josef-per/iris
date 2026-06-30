import 'package:flutter/material.dart';
import 'package:iris/widgets/app_lembretes_content.dart';

class AppLembretesListRefeicao extends StatefulWidget {
  const AppLembretesListRefeicao({super.key});

  @override
  State<AppLembretesListRefeicao> createState() => AppLembretesListState();
}

class AppLembretesListState extends State<AppLembretesListRefeicao> {
  bool ativo = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppLembretesContent(
          gradientIconColor1: Color(0xFF8A38F5),
          gradientIconColor2: Color(0xFFDBCFFF),
          iconPath: 'assets/icons/GarfoColher_white.png',
          textName: 'Café da manhã',
          textTime: '8h00',

          isActive: ativo,

          onSwitchChanged: (value) {
            setState(() {
              ativo = value;
            });
          },
        ),
      ],
    );
  }
}
