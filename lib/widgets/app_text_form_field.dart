import 'package:flutter/material.dart';

class AppTextFormField extends StatelessWidget {
  //Parâmetros

  //texto anterior ao textfield
  final String labelText;
  final Color labelColor;

  //textformfield
  final Color hintColor;
  final String hintText;
  final Color backgroundColor;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const AppTextFormField({
    super.key,
    required this.labelText,
    required this.labelColor,
    //
    required this.hintColor,
    required this.hintText,
    required this.backgroundColor,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
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

        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),

            filled: true,
            fillColor: backgroundColor,
          ),
        ),
      ],
    );
  }
}
