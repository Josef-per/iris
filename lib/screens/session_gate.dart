import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:iris/screens/patient_session_gate.dart';
import 'package:iris/screens/professional_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key, this.authService, this.userTypeResolver});

  final AuthService? authService;
  final Future<String> Function()? userTypeResolver;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final _users = UserRepository();
  late final AuthService _authService;
  late Future<String> _userTypeFuture;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _userTypeFuture = _loadUserType();
  }

  Future<String> _loadUserType() async {
    try {
      final userType = widget.userTypeResolver == null
          ? await _resolveUserType()
          : await widget.userTypeResolver!();
      if (userType != UserTypes.paciente &&
          userType != UserTypes.profissional) {
        throw const UserRoleConflictException();
      }
      return userType;
    } catch (error) {
      if (_isPermanentSessionError(error)) {
        try {
          await _authService.signOut();
        } catch (_) {
          // O erro original explica por que o bootstrap falhou. O botao de
          // saida continua disponivel caso o encerramento remoto tambem falhe.
        }
      }
      rethrow;
    }
  }

  Future<String> _resolveUserType() async {
    final user = SupabaseClientProvider.client.auth.currentUser;

    if (user == null) throw AuthSessionMissingException();

    await _users.ensureSessionForAuthUser(user);

    final userType = await _users.getCurrentUserType();
    if (userType == null) throw const UserRoleConflictException();
    return userType;
  }

  bool _isPermanentSessionError(Object error) {
    if (error is UserRoleConflictException ||
        error is AuthSessionMissingException) {
      return true;
    }
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      return message.contains('account_inactive') ||
          message.contains('invalid_account_type');
    }
    return false;
  }

  void _refreshUserType() {
    setState(() {
      _userTypeFuture = _loadUserType();
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
    return FutureBuilder<String>(
      future: _userTypeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          final message = AppErrorMessages.from(snapshot.error!);
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Não foi possível carregar sua sessão',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isSigningOut ? null : _refreshUserType,
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

        if (snapshot.data == UserTypes.profissional) {
          return const ProfessionalHomeScreen();
        }

        return PatientSessionGate(authService: _authService);
      },
    );
  }
}
