import 'package:flutter/material.dart';
import 'package:iris/widgets/app_filled_button.dart';
import 'package:iris/widgets/app_select_field.dart';
import 'package:iris/widgets/app_text_form_field.dart';
import 'package:iris/widgets/app_time_field.dart';

class AppReminderForm extends StatelessWidget {
  const AppReminderForm({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x64000000),
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Novo Lembrete',
              style: TextStyle(fontSize: 20, color: Color(0xFF28174E)),
            ),
          ),
          const SizedBox(height: 22),
          const AppSelectField(labelText: 'Tipo', valueText: 'Refeição'),
          const SizedBox(height: 16),
          const AppTextFormField(
            labelText: 'Título',
            labelColor: Color(0xFF28174E),
            labelFontWeight: FontWeight.normal,
            labelToFieldSpacing: 7,
            hintColor: Color(0xFF877E9B),
            hintText: 'Ex: Jantar',
            backgroundColor: Color(0xFFFAF9F6),
            borderSide: BorderSide(color: Color(0xFF8B70EA)),
            borderRadius: BorderRadius.all(Radius.circular(16)),
            fieldHeight: 30,
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
            isDense: true,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          const AppTimeField(labelText: 'Horário', hintText: 'Ex: 08h00'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppFilledButton(
                  text: 'Adicionar',
                  backgroundColor: const Color(0xFF5C35B4),
                  textColor: Colors.white,
                  onPressed: () {},
                  width: null,
                  height: 32,
                  borderRadius: 18,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  boxShadow: const [],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AppFilledButton(
                  text: 'Cancelar',
                  backgroundColor: const Color(0xFFE8E1FF),
                  textColor: const Color(0xFF28174E),
                  onPressed: onCancel,
                  width: null,
                  height: 32,
                  borderRadius: 18,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  boxShadow: const [],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
