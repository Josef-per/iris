import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/widgets/app_text_form_field.dart';

class ProfilePersonalSection extends StatelessWidget {
  const ProfilePersonalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3328174E),
            blurRadius: 5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppTextFormField(
            labelText: 'Nome',
            labelColor: AppColors.ink,
            hintColor: AppColors.ink,
            hintText: 'Marilene',
            backgroundColor: AppColors.porcelain,
            labelFontSize: 14,
            labelFontWeight: FontWeight.w700,
            labelToFieldSpacing: 10,
            fieldHeight: 40,
            borderSide: BorderSide(color: AppColors.purple),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            isDense: true,
            readOnly: true,
          ),
          const SizedBox(height: 20),
          const AppTextFormField(
            labelText: 'Email',
            labelColor: AppColors.ink,
            hintColor: AppColors.ink,
            hintText: 'marilene@proton.me',
            backgroundColor: AppColors.porcelain,
            labelFontSize: 14,
            labelFontWeight: FontWeight.w700,
            labelToFieldSpacing: 10,
            fieldHeight: 40,
            borderSide: BorderSide(color: AppColors.purple),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            isDense: true,
            readOnly: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 25),
            child: Divider(color: AppColors.purple, height: 1),
          ),
          SizedBox(
            height: 33,
            child: OutlinedButton(
              onPressed: _doNothing,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                backgroundColor: const Color(0x33F29C9D),
                side: const BorderSide(color: Color(0xFFFF8E8E)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 16),
                  SizedBox(width: 8),
                  Text('Sair da conta'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _doNothing() {}
