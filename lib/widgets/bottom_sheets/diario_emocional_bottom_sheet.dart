import 'package:flutter/material.dart';
import 'package:iris/widgets/app_filled_button.dart';

class DiarioEmocionalBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentGeometry.topCenter,
            end: AlignmentGeometry.bottomCenter,

            colors: [Color(0xFF28174E), Color(0xFF53418A), Color(0xFF7D6AC6)],
          ),
        ),

        child: Padding(
          padding: const EdgeInsetsGeometry.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //title
              Text(''),
              //subtitle
              Text(''),

              //Campo de envio
              Form(
                child: Container(
                  child: Column(
                    children: [
                      Text('Como você está se sentindo?'),
                      TextFormField(),
                      FilledButton(onPressed: () {}, child: Text('')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
