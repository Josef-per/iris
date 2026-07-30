import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/widgets/app_acompanhamento_date_picker.dart';
import 'package:iris/widgets/app_acompanhamento_graficos.dart';
import 'package:iris/widgets/app_acompanhamento_linha_tempo_card.dart';
import 'package:iris/widgets/app_acompanhamento_linha_tempo_decorator.dart';
import 'package:iris/widgets/app_acompanhamento_registro_card.dart';
import 'package:iris/widgets/app_function_gradient_decoration.dart';
import 'package:iris/widgets/app_function_headers.dart';
import 'package:iris/widgets/app_nav_acompanhamento.dart';

class AcompanhamentoScreen extends StatelessWidget {
  const AcompanhamentoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFunctionGradientDecoration(
      gradientHeight: 232,
      gradientColors: const [
        Color(0xFF7D6AC6),
        Color(0xFF462A7E),
        Color(0xFF28174E),
      ],
      contentPadding: const EdgeInsets.fromLTRB(27, 50, 27, 32),
      content: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: AppFunctionHeaders(
            onTap: _doNothing,
            title: 'Histórico',
            subTitle: 'Acompanhe a sua jornada',
            bottomSpacing: 36,
            acompanhamentoItems: [
              AppNavAcompanhamentoItem(
                label: 'Calendário',
                iconPath: 'assets/icons/Calendario_white.png',
              ),
              AppNavAcompanhamentoItem(
                label: 'Gráficos',
                iconPath: 'assets/icons/Grafico_purple.png',
              ),
              AppNavAcompanhamentoItem(
                label: 'Linha do\ntempo',
                iconPath: 'assets/icons/LinhaTempo_purple.png',
              ),
            ],
            acompanhamentoContents: [
              _AcompanhamentoCalendarSection(),
              AppAcompanhamentoGraficos(),
              _AcompanhamentoLinhaTempoSection(),
            ],
          ),
        ),
      ),
    );
  }
}

void _doNothing() {}

class _AcompanhamentoCalendarSection extends StatelessWidget {
  const _AcompanhamentoCalendarSection();

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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppAcompanhamentoDatePicker(),
          SizedBox(height: 11),
          Divider(height: 1, color: Color(0xFF7D6AC6)),
          SizedBox(height: 12),
          Text(
            'Registros de 09/07/2026',
            style: TextStyle(
              color: Color(0xFF28174E),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 24),
          AppAcompanhamentoRegistroCard(title: 'Check-in rápido'),
          SizedBox(height: 20),
          AppAcompanhamentoRegistroCard(title: 'Diário'),
          SizedBox(height: 20),
          AppAcompanhamentoRegistroCard(title: 'Refeição'),
        ],
      ),
    );
  }
}

class _AcompanhamentoLinhaTempoSection extends StatelessWidget {
  const _AcompanhamentoLinhaTempoSection();

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
                          title: 'Check-in Rápido',
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
