import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_config.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/screens/cadastro_screen.dart';
import 'package:iris/screens/home_screen.dart';
import 'package:iris/widgets/app_account_type_selector.dart';
import 'package:iris/widgets/app_auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialProfessional = false});

  final bool initialProfessional;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late bool _isProfessional;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isProfessional = widget.initialProfessional;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!SupabaseConfig.isConfigured) {
      if (_isProfessional) {
        setState(() {
          _errorMessage =
              'Configure o Supabase para acessar a área profissional.';
        });
        return;
      }
      const destination = HomeScreen();
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
        expectedUserType: _isProfessional
            ? UserTypes.profissional
            : UserTypes.paciente,
      );
    } catch (error) {
      if (mounted) setState(() => _errorMessage = AppErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openCadastro() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CadastroScreen(initialProfessional: _isProfessional),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppAuthLayout(
      title: 'Bem-vindo de volta.',
      subtitle:
          'Seu espaço seguro para acompanhar hábitos, emoções e progresso com mais leveza.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Entrar', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                _isProfessional
                    ? 'Acesse o painel de acompanhamento profissional.'
                    : 'Acesse sua conta para continuar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Como deseja entrar?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              AppAccountTypeSelector(
                isProfessional: _isProfessional,
                enabled: !_isLoading,
                onChanged: (value) => setState(() => _isProfessional = value),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                autofillHints: const [AutofillHints.email],
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'seuemail@email.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _passwordController,
                autofillHints: const [AutofillHints.password],
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Mostrar senha'
                        : 'Ocultar senha',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Informe sua senha.'
                    : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: _errorMessage!),
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
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(_isLoading ? 'Entrando...' : 'Entrar'),
                ),
              ),
              if (!SupabaseConfig.isConfigured) ...[
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Modo de demonstração: os dados exibidos são fictícios.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Ainda não tem uma conta?'),
                  TextButton(
                    onPressed: _isLoading ? null : _openCadastro,
                    child: const Text('Criar conta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (!email.contains('@')) return 'Informe um e-mail válido.';
    return null;
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.danger)),
    );
  }
}
