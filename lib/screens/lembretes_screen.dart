import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/widgets/app_lembretes_field.dart';
import 'package:iris/widgets/app_lembretes_list_medicamentos.dart';
import 'package:iris/widgets/app_lembretes_list_refeicao.dart';
import 'package:iris/widgets/app_reminder_form.dart';
import 'package:iris/widgets/app_responsive.dart';

class LembretesScreen extends StatefulWidget {
  const LembretesScreen({super.key});

  @override
  State<LembretesScreen> createState() => _LembretesScreenState();
}

class _LembretesScreenState extends State<LembretesScreen> {
  bool _showNewReminder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppGradientHeader(
              padding: EdgeInsets.zero,
              child: SafeArea(
                bottom: false,
                child: AppResponsive(
                  maxWidth: 760,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: 'Voltar',
                        onPressed: () => Navigator.maybePop(context),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.white,
                          backgroundColor: AppColors.white.withValues(
                            alpha: .1,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Lembretes',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppColors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Gerencie seus lembretes diários',
                        style: TextStyle(color: AppColors.lavender),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: FilledButton.icon(
                          onPressed: () => setState(
                            () => _showNewReminder = !_showNewReminder,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.deepPurple,
                          ),
                          icon: Icon(
                            _showNewReminder
                                ? Icons.close_rounded
                                : Icons.add_rounded,
                          ),
                          label: Text(
                            _showNewReminder
                                ? 'Fechar formulário'
                                : 'Adicionar lembrete',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AppResponsive(
              maxWidth: 760,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _showNewReminder
                        ? Padding(
                            key: const ValueKey('reminder-form'),
                            padding: const EdgeInsets.only(bottom: 30),
                            child: AppReminderForm(
                              onCancel: () =>
                                  setState(() => _showNewReminder = false),
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('empty-reminder-form'),
                          ),
                  ),
                  const AppLembretesField(
                    iconSection: 'assets/icons/GarfoColher_purple.png',
                    textSection: 'Refeições',
                  ),
                  const SizedBox(height: 16),
                  const AppLembretesListRefeicao(),
                  const SizedBox(height: 36),
                  const AppLembretesField(
                    iconSection: 'assets/icons/FrascoRemedio_purple.png',
                    textSection: 'Medicamentos',
                  ),
                  const SizedBox(height: 16),
                  const AppLembretesListMedicamentos(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
