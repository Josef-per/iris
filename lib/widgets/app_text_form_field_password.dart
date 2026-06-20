import 'package:flutter/material.dart';

class AppTextFormFieldPassword extends StatelessWidget {
  //texto anterior ao textfield
  //texto anterior ao textfield
  final String labelText;
  final Color labelColor;

  //textformfield
  final Color hintColor;
  final String hintText;
  final Color backgroundColor;
  final String ImageDirectory;

  const AppTextFormFieldPassword({
    super.key,
    required this.labelText,
    required this.labelColor,
    //
    required this.hintColor,
    required this.hintText,
    required this.backgroundColor,
    required this.ImageDirectory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          labelText,
          style: TextStyle(
            color: labelColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 44,
          width: double.infinity,
          child: TextFormField(
            obscureText: true,
            style: TextStyle(color: hintColor),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: backgroundColor, width: 2),
              ),

              hintText: hintText,
              hintStyle: TextStyle(color: hintColor, fontSize: 16),

              filled: true,
              fillColor: backgroundColor,

              suffixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(ImageDirectory),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
