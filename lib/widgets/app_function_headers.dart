import 'package:flutter/material.dart';
import 'package:iris/widgets/app_icons_buttons.dart';
import 'package:iris/widgets/app_headers.dart';

class AppFunctionHeaders extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final String subTitle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final double iconToTitleSpacing;
  final double titleToSubtitleSpacing;
  final double bottomSpacing;

  const AppFunctionHeaders({
    super.key,
    required this.onTap,
    required this.title,
    required this.subTitle,
    this.titleStyle,
    this.subTitleStyle,
    this.iconToTitleSpacing = 13,
    this.titleToSubtitleSpacing = 7,
    this.bottomSpacing = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconsButtons(
          onTap: onTap,
          width: 22,
          height: 21,
          iconPath: 'assets/icons/VoltarArrow_white.png',
        ),

        SizedBox(height: iconToTitleSpacing),

        AppHeaders(
          textTitle: title,
          textSubTitle: subTitle,
          titleStyle: titleStyle,
          subTitleStyle: subTitleStyle,
          titleToSubtitleSpacing: titleToSubtitleSpacing,
          bottomSpacing: bottomSpacing,
        ),
      ],
    );
  }
}
