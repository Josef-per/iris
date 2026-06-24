import 'package:flutter/material.dart';

class AppSlider extends StatefulWidget {
  const AppSlider({super.key});

  @override
  State<AppSlider> createState() => _AppSliderState();
}

class _AppSliderState extends State<AppSlider> {
  double _sliderValue = 5;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _sliderValue,
      min: 0,
      max: 10,
      divisions: 10,
      activeColor: const Color(0xFF28174E),
      inactiveColor: const Color(0xFFE0E0E0),
      label: _sliderValue.round().toString(),
      onChanged: (double value) {
        setState(() {
          _sliderValue = value;
        });
      },
    );
  }
}
