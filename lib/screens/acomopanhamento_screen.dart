import 'package:flutter/material.dart';
import 'package:iris/widgets/app_acompanhamento_date_picker.dart';
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFunctionHeaders(
                onTap: _doNothing,
                title: 'Histórico',
                subTitle: 'Acompanhe a sua jornada',
                bottomSpacing: 36,
              ),
              AppNavAcompanhamentoBar(
                items: [
                  AppNavAcompanhamentoItem(
                    label: 'Calendário',
                    iconPath: 'assets/icons/Calendario_white.png',
                    isSelected: true,
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
              ),
              SizedBox(height: 34),
              _AcompanhamentoCalendarSection(),
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
