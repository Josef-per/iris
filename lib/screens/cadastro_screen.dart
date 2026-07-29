import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/screens/login_screen.dart';
import 'package:iris/screens/session_gate.dart';
import 'package:iris/widgets/app_auth_layout.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _displayName = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscure = true;
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _authService.signUp(
        email: _email.text,
        password: _password.text,
        displayName: _displayName.text,
      );
      if (!mounted) return;
      if (result.needsEmailConfirmation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirme seu e-mail para entrar.')),
        );
        _openLogin(clearStack: true);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SessionGate()),
          (_) => false,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _errorMessage = AppErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openLogin({bool clearStack = false}) {
    final route = MaterialPageRoute(builder: (_) => const LoginScreen());
    if (clearStack) {
      Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppAuthLayout(
      title: 'Comece sua jornada.',
      subtitle:
          'Crie sua conta e tenha um acompanhamento mais claro, humano e conectado.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Criar conta',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Leva menos de um minuto.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _displayName,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Como gostaria de ser chamado?',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe seu nome.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                hintText: 'seuemail@email.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Informe seu e-mail.';
                if (!email.contains('@')) return 'Informe um e-mail válido.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Senha',
                hintText: 'Mínimo de 8 caracteres',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => (value ?? '').length < 8
                  ? 'Use pelo menos 8 caracteres.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPassword,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Confirme a senha',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
              validator: (value) => value != _password.text
                  ? 'As senhas precisam ser iguais.'
                  : null,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1_rounded),
                label: Text(_isLoading ? 'Criando...' : 'Criar minha conta'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _openLogin,
                child: const Text('Já tenho uma conta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
