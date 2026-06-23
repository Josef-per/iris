import 'package:flutter/material.dart';
import 'package:iris/features/patient_professional/patient_professional_repository.dart';
import 'package:iris/screens/home_screen.dart';
import 'package:iris/screens/qr_code_screen.dart';

class PatientSessionGate extends StatefulWidget {
  const PatientSessionGate({super.key});

  @override
  State<PatientSessionGate> createState() => _PatientSessionGateState();
}

class _PatientSessionGateState extends State<PatientSessionGate> {
  final _repository = PatientProfessionalRepository();
  late Future<bool> _linkCheckFuture;

  @override
  void initState() {
    super.initState();
    _linkCheckFuture = _repository.hasActiveProfessionalLink();
  }

  void _refreshLinkCheck() {
    setState(() {
      _linkCheckFuture = _repository.hasActiveProfessionalLink();
    });
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
                      'Nao foi possivel verificar seu vinculo com o profissional.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _refreshLinkCheck,
                      child: const Text('Tentar novamente'),
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
