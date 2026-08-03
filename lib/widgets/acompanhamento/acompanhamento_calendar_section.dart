import 'package:flutter/material.dart';
import 'package:iris/widgets/app_acompanhamento_date_picker.dart';
import 'package:iris/widgets/app_acompanhamento_registro_card.dart';
import 'package:iris/widgets/bottom_sheets/check_in_diario_bottom_sheet.dart';
import 'package:iris/widgets/bottom_sheets/diario_emocional_bottom_sheet.dart';
import 'package:iris/widgets/bottom_sheets/registro_alimentar_bottom_sheet.dart';

class AcompanhamentoCalendarSection extends StatelessWidget {
  const AcompanhamentoCalendarSection({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  void _openBottomSheet(BuildContext context, Widget child) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 24, 11, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1728174E),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppAcompanhamentoDatePicker(
            selectedDate: selectedDate,
            onDateSelected: onDateSelected,
          ),
          const SizedBox(height: 11),
          const Divider(height: 1, color: Color(0xFF7D6AC6)),
          const SizedBox(height: 12),
          Text(
            'Adicionar um registro de hoje',
            style: const TextStyle(
              color: Color(0xFF28174E),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          AppAcompanhamentoRegistroCard(
            title: 'Check-in diário',
            onTap: () =>
                _openBottomSheet(context, const CheckInDiarioBottomSheet()),
          ),
          const SizedBox(height: 20),
          AppAcompanhamentoRegistroCard(
            title: 'Diário emocional',
            onTap: () =>
                _openBottomSheet(context, const DiarioEmocionalBottomSheet()),
          ),
          const SizedBox(height: 20),
          AppAcompanhamentoRegistroCard(
            title: 'Refeição',
            onTap: () =>
                _openBottomSheet(context, const RegistroAlimentarBottomSheet()),
          ),
        ],
      ),
    );
  }
}
