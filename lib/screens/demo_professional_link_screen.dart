import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/patient_professional/patient_professional_repository.dart';
import 'package:iris/widgets/app_responsive.dart';

/// Confirmação temporária exclusiva dos novos cadastros da demonstração.
class DemoProfessionalLinkScreen extends StatefulWidget {
  const DemoProfessionalLinkScreen({
    super.key,
    required this.onLinked,
    required this.onSignOut,
    this.approveLink,
  });

  final VoidCallback onLinked;
  final Future<void> Function() onSignOut;
  final Future<void> Function()? approveLink;

  @override
  State<DemoProfessionalLinkScreen> createState() =>
      _DemoProfessionalLinkScreenState();
}

class _DemoProfessionalLinkScreenState
    extends State<DemoProfessionalLinkScreen> {
  bool _isBusy = false;
  bool _approved = false;
  String? _errorMessage;

  Future<void> _run(Future<void> Function() action) async {
    if (_isBusy || _approved) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = AppErrorMessages.from(error));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _approve() => _run(() async {
    await (widget.approveLink ??
        PatientProfessionalRepository().approveDemoProfessionalLink)();
    if (!mounted) return;
    setState(() => _approved = true);
    widget.onLinked();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: AppResponsive(
                maxWidth: 560,
                child: AppSurface(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 48,
                        color: AppColors.deepPurple,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Confirmar vínculo de teste',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Psiquiatra Lucas (para teste)',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      const Text('lucas@gmail.com'),
                      const SizedBox(height: 16),
                      const Text(
                        'Esta é uma demonstração do Íris. Para testar como '
                        'paciente, aprove o vínculo com o profissional de teste. '
                        'Você não precisa de código. Ao aprovar, Lucas poderá '
                        'acompanhar os registros que você adicionar.',
                        textAlign: TextAlign.center,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isBusy || _approved ? null : _approve,
                          child: Text(
                            _isBusy ? 'Aguarde...' : 'Aprovar vínculo e testar',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _isBusy || _approved
                            ? null
                            : () => _run(widget.onSignOut),
                        child: const Text('Sair da conta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
