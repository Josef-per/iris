import 'package:flutter/material.dart';
import 'package:iris/widgets/acompanhamento/acompanhamento_calendar_section.dart';
import 'package:iris/widgets/acompanhamento/acompanhamento_linha_tempo_section.dart';
import 'package:iris/widgets/app_acompanhamento_graficos.dart';
import 'package:iris/widgets/app_function_gradient_decoration.dart';
import 'package:iris/widgets/app_function_headers.dart';
import 'package:iris/widgets/app_nav_acompanhamento.dart';

class AcompanhamentoScreen extends StatefulWidget {
  const AcompanhamentoScreen({super.key});

  @override
  State<AcompanhamentoScreen> createState() => _AcompanhamentoScreenState();
}

class _AcompanhamentoScreenState extends State<AcompanhamentoScreen> {
  var _selectedDate = DateTime(2026, DateTime.september, 9);

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
              AcompanhamentoCalendarSection(
                selectedDate: _selectedDate,
                onDateSelected: (date) =>
                    setState(() => _selectedDate = date),
              ),
              AppAcompanhamentoGraficos(selectedDate: _selectedDate),
              const AcompanhamentoLinhaTempoSection(),
            ],
          ),
        ),
      ),
    );
  }
}

void _doNothing() {}
