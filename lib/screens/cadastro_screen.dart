import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/screens/home_screen.dart';
import 'package:iris/screens/login_screen.dart';
import 'package:iris/widgets/app_filled_button.dart';
import 'package:iris/widgets/app_outlined_button.dart';
import 'package:iris/widgets/app_text_form_field.dart';
import 'package:iris/widgets/app_text_form_field_password.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _displayNameController.text,
      );

      if (!mounted) {
        return;
      }

      if (result.needsEmailConfirmation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro criado. Confirme seu email para entrar.'),
          ),
        );
        _openLogin(replace: true);
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = AppErrorMessages.from(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openLogin({bool replace = false}) {
    final route = MaterialPageRoute(builder: (_) => const LoginScreen());

    if (replace) {
      Navigator.of(context).pushReplacement(route);
      return;
    }

    Navigator.of(context).pushReplacement(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0XFF7D6AC6), Color(0xFF28174E)],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/Login.png',
                          width: 270,
                          height: 129,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Seu espaço de bem-estar e autocuidado',
                          style: TextStyle(
                            color: Color(0xFFFAF9F6),
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppOutlinedButton(
                        text: 'Login',
                        borderColor: const Color(0xFFFAF9F6),
                        textColor: const Color(0xFFFAF9F6),
                        onPressed: _isLoading ? null : _openLogin,
                      ),
                      const SizedBox(width: 8),
                      AppFilledButton(
                        text: 'Criar Conta',
                        backgroundColor: const Color(0xFFFAF9F6),
                        textColor: const Color(0xFF28174E),
                        onPressed: _isLoading ? null : () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextFormField(
                          controller: _emailController,
                          labelText: 'Email',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: 'seuemail@gmail.com',
                          backgroundColor: const Color(0xFFFAF9F6),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 20),
                        AppTextFormFieldPassword(
                          controller: _passwordController,
                          labelText: 'Senha',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: 'Mínimo de 8 caracteres',
                          backgroundColor: const Color(0xFFFAF9F6),
                          imageDirectory: 'assets/icons/Eye_Purple.png',
                          textInputAction: TextInputAction.next,
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 20),
                        AppTextFormFieldPassword(
                          controller: _confirmPasswordController,
                          labelText: 'Confirmar senha',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: 'As senhas devem ser iguais',
                          backgroundColor: const Color(0xFFFAF9F6),
                          imageDirectory: 'assets/icons/Eye_Purple.png',
                          textInputAction: TextInputAction.next,
                          validator: _validateConfirmPassword,
                        ),
                        const SizedBox(height: 32),
                        const Divider(color: Color(0xFFFAF9F6), thickness: 1),
                        const SizedBox(height: 32),
                        AppTextFormField(
                          controller: _displayNameController,
                          labelText: 'Como gostaria de ser chamado?',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: '',
                          backgroundColor: const Color(0xFFFAF9F6),
                          textInputAction: TextInputAction.done,
                          validator: _validateDisplayName,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFFFD6D6),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: AppOutlinedButton(
                            text: _isLoading ? 'Criando...' : 'Avançar',
                            borderColor: const Color(0xFFFAF9F6),
                            textColor: const Color(0xFFFAF9F6),
                            onPressed: _isLoading ? null : _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe seu email.';
    }

    if (!email.contains('@')) {
      return 'Informe um email válido.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.length < 8) {
      return 'Use pelo menos 8 caracteres.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'As senhas precisam ser iguais.';
    }

    return null;
  }

  String? _validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe como gostaria de ser chamado.';
    }

    return null;
  }
}
