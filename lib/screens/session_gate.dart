import 'package:flutter/material.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:iris/screens/patient_session_gate.dart';
import 'package:iris/screens/professional_home_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final _users = UserRepository();
  late Future<String> _userTypeFuture;

  @override
  void initState() {
    super.initState();
    _userTypeFuture = _resolveUserType();
  }

  Future<String> _resolveUserType() async {
    final user = SupabaseClientProvider.client.auth.currentUser;

    if (user != null) {
      await _users.ensureSessionForAuthUser(user);
    }

    final userType = await _users.getCurrentUserType();
    return userType ?? UserTypes.paciente;
  }

  void _refreshUserType() {
    setState(() {
      _userTypeFuture = _resolveUserType();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _userTypeFuture,
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
                      'Nao foi possivel carregar sua sessao.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _refreshUserType,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.data == UserTypes.profissional) {
          return const ProfessionalHomeScreen();
        }

        return const PatientSessionGate();
      },
    );
  }
}
