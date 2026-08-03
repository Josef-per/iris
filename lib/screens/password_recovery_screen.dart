import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/widgets/app_auth_layout.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({
    super.key,
    this.authService,
    this.onPasswordUpdated,
  });

  final AuthService? authService;
  final VoidCallback? onPasswordUpdated;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  late final AuthService _authService;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
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
      await _authService.updatePassword(password: _passwordController.text);
      widget.onPasswordUpdated?.call();
      // O link de recuperacao cria uma sessao temporaria. Encerramos essa
      // sessao depois da troca para exigir um novo login com a senha criada.
      await _authService.signOut();
    } catch (error) {
      if (mounted) setState(() => _errorMessage = AppErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel() async {
    final shouldCancel =
        await showDialog<bool>(
          context: context,
          useRootNavigator: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cancelar recuperação?'),
            content: const Text(
              'O link será fechado e você precisará solicitar outro para alterar a senha.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Continuar aqui'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Cancelar recuperação'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldCancel || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signOut();
    } catch (error) {
      if (mounted) setState(() => _errorMessage = AppErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppAuthLayout(
        title: 'Proteja sua conta.',
        subtitle:
            'Crie uma senha nova e exclusiva. Ao concluir, você entrará novamente com ela.',
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Criar nova senha',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  autofillHints: const [AutofillHints.newPassword],
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nova senha',
                    hintText: 'Mínimo de 8 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Mostrar senha'
                          : 'Ocultar senha',
                      onPressed: _isLoading
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      icon: Icon(
                        _obscurePassword
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
                  controller: _confirmationController,
                  autofillHints: const [AutofillHints.newPassword],
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Confirme a nova senha',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                  validator: (value) => value != _passwordController.text
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
                        : const Icon(Icons.password_rounded),
                    label: Text(
                      _isLoading ? 'Atualizando...' : 'Atualizar senha',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _cancel,
                    child: const Text('Cancelar recuperação'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
