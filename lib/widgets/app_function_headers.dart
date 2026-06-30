import 'package:flutter/material.dart';
import 'package:iris/widgets/app_icons_buttons.dart';
import 'package:iris/widgets/app_headers.dart';

class AppFunctionHeaders extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final String subTitle;

  const AppFunctionHeaders({
    super.key,
    required this.onTap,
    required this.title,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconsButtons(
          onTap: () {},
          width: 22,
          height: 21,
          iconPath: 'assets/icons/VoltarArrow_white.png',
        ),

        SizedBox(height: 13),

        AppHeaders(TextTitle: title, TextSubTitle: subTitle),
      ],
    );
  }
}
