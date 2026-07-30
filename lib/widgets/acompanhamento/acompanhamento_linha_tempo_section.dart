import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/widgets/app_acompanhamento_linha_tempo_card.dart';
import 'package:iris/widgets/app_acompanhamento_linha_tempo_decorator.dart';

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
          SizedBox(height: 31),
          SizedBox(
            height: 350,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AppAcompanhamentoLinhaTempoDecorator(
                    markerOffsets: <double>[13, 135, 257],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 34),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 90,
                        child: AppAcompanhamentoLinhaTempoCard(
                          dateTime: '09/09/2026 · 14:30',
                          title: 'Almoço',
                          description: 'Possível descrição do que foi feito',
                        ),
                      ),
                      SizedBox(height: 32),
                      SizedBox(
                        height: 90,
                        child: AppAcompanhamentoLinhaTempoCard(
                          dateTime: '09/09/2026 · 10:15',
                          title: 'Check-in diário',
                          description: 'Humor: MB, Alimentação: B',
                        ),
                      ),
                      SizedBox(height: 32),
                      SizedBox(
                        height: 106,
                        child: AppAcompanhamentoLinhaTempoCard(
                          dateTime: '08/09/2026 · 19:45',
                          title: 'Exercício de respiração',
                          description:
                              'Usei o Exercício de sla qual que vai estar disponível',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
