import 'package:flutter/material.dart';
import 'package:iris/widgets/app_headers.dart';
import 'package:iris/widgets/app_icons_buttons.dart';
import 'package:iris/widgets/app_nav_acompanhamento.dart';

class AppFunctionHeaders extends StatefulWidget {
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
    this.acompanhamentoItems,
    this.acompanhamentoContents,
    this.contentTopSpacing = 34,
  }) : assert(
         acompanhamentoItems == null
             ? acompanhamentoContents == null
             : acompanhamentoContents != null &&
                   acompanhamentoItems.length ==
                       acompanhamentoContents.length,
       );

  final VoidCallback onTap;
  final String title;
  final String subTitle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final double iconToTitleSpacing;
  final double titleToSubtitleSpacing;
  final double bottomSpacing;
  final List<AppNavAcompanhamentoItem>? acompanhamentoItems;
  final List<Widget>? acompanhamentoContents;
  final double contentTopSpacing;

  @override
  State<AppFunctionHeaders> createState() => _AppFunctionHeadersState();
}

class _AppFunctionHeadersState extends State<AppFunctionHeaders> {
  var _selectedTabIndex = 0;

  bool get _hasAcompanhamentoTabs =>
      widget.acompanhamentoItems != null &&
      widget.acompanhamentoContents != null;

  void _selectTab(int index) {
    if (index == _selectedTabIndex) {
      return;
    }

    setState(() => _selectedTabIndex = index);
  }

  @override
  void didUpdateWidget(covariant AppFunctionHeaders oldWidget) {
    super.didUpdateWidget(oldWidget);
    final itemCount = widget.acompanhamentoItems?.length ?? 0;
    if (_selectedTabIndex >= itemCount) {
      _selectedTabIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconsButtons(
          onTap: widget.onTap,
          width: 22,
          height: 21,
          iconPath: 'assets/icons/VoltarArrow_white.png',
        ),
        SizedBox(height: widget.iconToTitleSpacing),
        AppHeaders(
          textTitle: widget.title,
          textSubTitle: widget.subTitle,
          titleStyle: widget.titleStyle,
          subTitleStyle: widget.subTitleStyle,
          titleToSubtitleSpacing: widget.titleToSubtitleSpacing,
          bottomSpacing: widget.bottomSpacing,
        ),
        if (_hasAcompanhamentoTabs) ...[
          AppNavAcompanhamentoBar(
            items: widget.acompanhamentoItems!,
            selectedIndex: _selectedTabIndex,
            onSelected: _selectTab,
          ),
          SizedBox(height: widget.contentTopSpacing),
          Stack(
            children: [
              for (var index = 0;
                  index < widget.acompanhamentoContents!.length;
                  index++)
                Offstage(
                  offstage: index != _selectedTabIndex,
                  child: TickerMode(
                    enabled: index == _selectedTabIndex,
                    child: widget.acompanhamentoContents![index],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
