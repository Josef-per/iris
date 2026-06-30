import 'package:flutter/material.dart';
import 'package:iris/widgets/app_icons_buttons.dart';
import 'package:iris/widgets/app_switch_lembretes.dart';

class AppLembretesContent extends StatelessWidget {
  final Color gradientIconColor1;
  final Color gradientIconColor2;
  final String iconPath;
  final String textName;
  final String textTime;

  const AppLembretesContent({
    super.key,
    required this.gradientIconColor1,
    required this.gradientIconColor2,
    required this.iconPath,
    required this.textName,
    required this.textTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0x64000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),

      width: 345,
      height: 64,

      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            //icone custom para cada tipo
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientIconColor1, gradientIconColor2],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              width: 40,
              height: 40,
              child: Image.asset(iconPath, width: 25, height: 25),
            ),

            SizedBox(width: 10),

            //Nome e horário
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textName,
                  style: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 2),

                Row(
                  children: [
                    Image.asset(
                      'assets/icons/Time_purple.png',
                      width: 10,
                      height: 10,
                    ),
                    SizedBox(width: 4),
                    Text(
                      textTime,
                      style: TextStyle(
                        color: const Color(0xFF8D80C2),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(width: 70),

            AppSwitchLembretes(),

            SizedBox(width: 10),

            //btn lixo
            AppIconsButtons(
              onTap: () {},
              width: 20,
              height: 20,
              iconPath: 'assets/icons/Lixeira_red.png',
            ),
          ],
        ),
      ),
    );
  }
}
