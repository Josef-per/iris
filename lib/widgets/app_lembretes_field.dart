import 'package:flutter/material.dart';
import 'package:iris/widgets/app_lembretes_content.dart';

class AppLembretesField extends StatelessWidget {
  final String iconSection;
  final String textSection;

  const AppLembretesField({
    super.key,
    required this.iconSection,
    required this.textSection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //Header
        Row(
          children: [
            Image.asset(iconSection, width: 25, height: 25),
            SizedBox(width: 4),
            Text(
              textSection,
              style: TextStyle(fontSize: 20, color: const Color(0xFF28174E)),
            ),
          ],
        ),

        //Content
        AppLembretesContent(
          gradientIconColor1: const Color(0xFF8A38F5),
          gradientIconColor2: const Color(0xFFDBCFFF),
          iconPath: 'assets/icons/GarfoColher_white.png',
          textName: 'Café da manhã',
          textTime: '8h00',
        ),

        AppLembretesContent(
          gradientIconColor1: const Color(0xFF8A38F5),
          gradientIconColor2: const Color(0xFFDBCFFF),
          iconPath: 'assets/icons/GarfoColher_white.png',
          textName: 'Café da manhã',
          textTime: '8h00',
        ),

        AppLembretesContent(
          gradientIconColor1: const Color(0xFF8A38F5),
          gradientIconColor2: const Color(0xFFDBCFFF),
          iconPath: 'assets/icons/GarfoColher_white.png',
          textName: 'Café da manhã',
          textTime: '8h00',
        ),
      ],
    );
  }
}
