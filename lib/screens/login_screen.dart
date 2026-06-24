import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/screens/cadastro_screen.dart';
import 'package:iris/widgets/app_filled_button.dart';
import 'package:iris/widgets/app_outlined_button.dart';
import 'package:iris/widgets/app_text_form_field.dart';
import 'package:iris/widgets/app_text_form_field_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
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

  void _openCadastro() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
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
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppFilledButton(
                        text: 'Login',
                        backgroundColor: const Color(0xFFFAF9F6),
                        textColor: const Color(0xFF28174E),
                        onPressed: _isLoading ? null : () {},
                      ),
                      const SizedBox(width: 8),
                      AppOutlinedButton(
                        text: 'Criar Conta',
                        borderColor: const Color(0xFFFAF9F6),
                        textColor: const Color(0xFFFAF9F6),
                        onPressed: _isLoading ? null : _openCadastro,
                      ),
                    ],
                  ),
                  const SizedBox(height: 45),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextFormField(
                          controller: _emailController,
                          labelText: 'Email',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: 'seuemail@email.com',
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
                          hintText: '',
                          backgroundColor: const Color(0xFFFAF9F6),
                          imageDirectory: 'assets/icons/Eye_Purple.png',
                          textInputAction: TextInputAction.done,
                          validator: _validatePassword,
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
                        const SizedBox(height: 35),
                        SizedBox(
                          width: double.infinity,
                          child: AppOutlinedButton(
                            text: _isLoading ? 'Entrando...' : 'Entrar',
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
    if (value == null || value.isEmpty) {
      return 'Informe sua senha.';
    }

    return null;
  }
}
