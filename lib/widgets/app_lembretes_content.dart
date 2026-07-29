import 'package:flutter/material.dart';
import 'package:iris/widgets/app_icons_buttons.dart';
import 'package:iris/widgets/app_switch_lembretes.dart';

class AppLembretesContent extends StatelessWidget {
  final Color gradientIconColor1;
  final Color gradientIconColor2;
  final String iconPath;
  final String textName;
  final String textTime;
  final bool isActive;
  final ValueChanged<bool> onSwitchChanged;

  const AppLembretesContent({
    super.key,
    required this.gradientIconColor1,
    required this.gradientIconColor2,
    required this.iconPath,
    required this.textName,
    required this.textTime,
    required this.isActive,
    required this.onSwitchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DFEB)),
      ),

      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),

      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            //icone custom para cada tipo
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientIconColor1, gradientIconColor2],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              width: 44,
              height: 44,
              child: Image.asset(iconPath, width: 25, height: 25),
            ),

            const SizedBox(width: 12),

            //Nome e horário
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    textName,
                    style: const TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/Time_purple.png',
                        width: 10,
                        height: 10,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        textTime,
                        style: const TextStyle(
                          color: Color(0xFF8D80C2),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            AppSwitchLembretes(value: isActive, onChanged: onSwitchChanged),

            const SizedBox(width: 8),

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
