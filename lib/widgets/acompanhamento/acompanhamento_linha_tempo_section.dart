import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AcompanhamentoLinhaTempoSection extends StatelessWidget {
  const AcompanhamentoLinhaTempoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 21, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F28174E),
            blurRadius: 7,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Linha do Tempo',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 24),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'Nenhum registro disponível na linha do tempo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
