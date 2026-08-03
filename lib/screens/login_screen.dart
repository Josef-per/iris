import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_config.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/screens/cadastro_screen.dart';
import 'package:iris/widgets/app_account_type_selector.dart';
import 'package:iris/widgets/app_auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.initialProfessional = false,
    this.authService,
    this.initialMessage,
  });

  final bool initialProfessional;
  final AuthService? authService;
  final String? initialMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService;
  bool _isLoading = false;
  bool _obscurePassword = true;
  late bool _isProfessional;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
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

    if (!SupabaseConfig.isConfigured && widget.authService == null) {
      setState(() {
        _errorMessage =
            'Supabase não carregado. Inicie o app com '
            './scripts/flutter_run.sh.';
      });
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

  Future<void> _openCadastro() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CadastroScreen(
          initialProfessional: _isProfessional,
          // Em testes, ou quando o AuthGate fornece o servico, a mesma
          // instancia preserva a validacao de perfil. Sem backend configurado,
          // nao transforme o servico interno em uma falsa injecao funcional.
          authService: widget.authService == null ? null : _authService,
        ),
      ),
    );
  }

  Future<void> _requestPasswordReset() async {
    final sent = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (_) => _EmailActionDialog(
        title: 'Recuperar senha',
        description:
            'Informe seu e-mail. Se houver uma conta, enviaremos um link seguro para criar uma nova senha.',
        actionLabel: 'Enviar link',
        initialEmail: _emailController.text,
        onSubmit: (email) => _authService.requestPasswordReset(email: email),
      ),
    );
    if (!mounted || sent != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Se houver uma conta para esse e-mail, o link de recuperação será enviado.',
        ),
      ),
    );
  }

  Future<void> _resendConfirmation() async {
    final sent = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (_) => _EmailActionDialog(
        title: 'Reenviar confirmação',
        description:
            'Informe o e-mail usado no cadastro para receber um novo link de confirmação.',
        actionLabel: 'Reenviar e-mail',
        initialEmail: _emailController.text,
        onSubmit: (email) =>
            _authService.resendSignUpConfirmation(email: email),
      ),
    );
    if (!mounted || sent != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Se o cadastro estiver pendente, um novo e-mail de confirmação será enviado.',
        ),
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
              if (SupabaseConfig.isConfigured || widget.authService != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : _requestPasswordReset,
                        child: const Text('Esqueci minha senha'),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _resendConfirmation,
                        child: const Text('Reenviar confirmação'),
                      ),
                    ],
                  ),
                ),
              if (widget.initialMessage != null) ...[
                const SizedBox(height: 8),
                _InfoBanner(message: widget.initialMessage!),
              ],
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
                    'Backend não configurado: a autenticação está desativada.',
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.ink)),
    );
  }
}

class _EmailActionDialog extends StatefulWidget {
  const _EmailActionDialog({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.initialEmail,
    required this.onSubmit,
  });

  final String title;
  final String description;
  final String actionLabel;
  final String initialEmail;
  final Future<void> Function(String email) onSubmit;

  @override
  State<_EmailActionDialog> createState() => _EmailActionDialogState();
}

class _EmailActionDialogState extends State<_EmailActionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await widget.onSubmit(_emailController.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = AppErrorMessages.from(error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.description),
            const SizedBox(height: 18),
            TextFormField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Informe seu e-mail.';
                if (!email.contains('@')) return 'Informe um e-mail válido.';
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: Text(_isLoading ? 'Enviando...' : widget.actionLabel),
        ),
      ],
    );
  }
}
