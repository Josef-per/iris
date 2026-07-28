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
  final FontWeight labelFontWeight;
  final double labelFontSize;
  final double labelToFieldSpacing;
  final double? fieldHeight;
  final BorderSide? borderSide;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final bool isDense;
  final bool readOnly;

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
    this.labelFontWeight = FontWeight.bold,
    this.labelFontSize = 16,
    this.labelToFieldSpacing = 10,
    this.fieldHeight,
    this.borderSide,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 12,
    ),
    this.isDense = false,
    this.readOnly = false,
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
            fontSize: labelFontSize,
            fontWeight: labelFontWeight,
          ),
        ),

        SizedBox(height: labelToFieldSpacing),

        SizedBox(
          height: fieldHeight,
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            readOnly: readOnly,
            style: TextStyle(color: hintColor),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: borderSide ?? BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: borderSide ?? BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide:
                    borderSide ?? BorderSide(color: backgroundColor, width: 2),
              ),
              hintText: hintText,
              hintStyle: TextStyle(color: hintColor, fontSize: 16),
              contentPadding: contentPadding,
              isDense: isDense,
              filled: true,
              fillColor: backgroundColor,
            ),
          ),
        ),
      ],
    );
  }
}
