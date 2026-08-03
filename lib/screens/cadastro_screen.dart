import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_config.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/widgets/app_account_type_selector.dart';
import 'package:iris/widgets/app_auth_layout.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({
    super.key,
    this.initialProfessional = false,
    this.authService,
  });

  final bool initialProfessional;
  final AuthService? authService;

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _displayName = TextEditingController();
  final _specialty = TextEditingController(text: 'Psiquiatria');
  final _professionalRegistration = TextEditingController();
  late final AuthService _authService;
  bool _isLoading = false;
  bool _obscure = true;
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
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _displayName.dispose();
    _specialty.dispose();
    _professionalRegistration.dispose();
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
      final result = await _authService.signUp(
        email: _email.text,
        password: _password.text,
        displayName: _displayName.text,
        userType: _isProfessional ? UserTypes.profissional : UserTypes.paciente,
        specialty: _isProfessional ? _specialty.text : null,
        professionalRegistration: _isProfessional
            ? _professionalRegistration.text
            : null,
      );
      if (!mounted) return;
      if (result.needsEmailConfirmation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirme seu e-mail para entrar.')),
        );
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _errorMessage = AppErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openLogin() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AppAuthLayout(
      title: _isProfessional
          ? 'Cuidado conectado, decisões mais claras.'
          : 'Comece sua jornada.',
      subtitle: _isProfessional
          ? 'Organize o acompanhamento dos seus pacientes em um só lugar.'
          : 'Crie sua conta e tenha um acompanhamento mais claro, humano e conectado.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isProfessional ? 'Criar conta profissional' : 'Criar conta',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _isProfessional
                  ? 'Configure agora o acesso ao painel profissional.'
                  : 'Leva menos de um minuto.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Qual perfil deseja criar?',
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
            if (_isProfessional) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialty,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Especialidade',
                  hintText: 'Ex.: Psiquiatria',
                  prefixIcon: Icon(Icons.psychology_alt_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe sua especialidade.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _professionalRegistration,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Registro profissional',
                  hintText: 'Ex.: CRM/SP 123456',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe seu registro profissional.'
                    : null,
              ),
            ],
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
            if (!SupabaseConfig.isConfigured) ...[
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Backend não configurado: o cadastro está desativado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
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
