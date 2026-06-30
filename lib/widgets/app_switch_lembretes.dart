import 'package:flutter/material.dart';

class AppSwitchLembretes extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AppSwitchLembretesState();
  }
}

class _AppSwitchLembretesState extends State<AppSwitchLembretes> {
  bool light = true;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: true,
      onChanged: (bool value) => {
        setState(() {
          light = value;
        }),
      },
    );
  }
}
