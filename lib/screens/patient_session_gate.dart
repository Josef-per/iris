import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/patient_professional/patient_professional_repository.dart';
import 'package:iris/screens/home_screen.dart';
import 'package:iris/screens/qr_code_screen.dart';

class PatientSessionGate extends StatefulWidget {
  const PatientSessionGate({super.key, this.authService, this.linkChecker});

  final AuthService? authService;
  final Future<bool> Function()? linkChecker;

  @override
  State<PatientSessionGate> createState() => _PatientSessionGateState();
}

class _PatientSessionGateState extends State<PatientSessionGate> {
  final _repository = PatientProfessionalRepository();
  late final AuthService _authService;
  late Future<bool> _linkCheckFuture;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _linkCheckFuture = _checkLink();
  }

  Future<bool> _checkLink() =>
      widget.linkChecker?.call() ?? _repository.hasActiveProfessionalLink();

  void _refreshLinkCheck() {
    setState(() {
      _linkCheckFuture = _checkLink();
    });
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await _authService.signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMessages.from(error))));
      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _linkCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Não foi possível verificar seu vínculo com o profissional.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isSigningOut ? null : _refreshLinkCheck,
                      child: const Text('Tentar novamente'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _isSigningOut ? null : _signOut,
                      icon: _isSigningOut
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_rounded),
                      label: Text(
                        _isSigningOut ? 'Saindo...' : 'Sair e trocar de conta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return const HomeScreen();
        }

        return QrcodeScreen(onLinked: _refreshLinkCheck);
      },
    );
  }
}
