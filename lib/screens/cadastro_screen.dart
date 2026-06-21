import 'package:flutter/material.dart';
import 'package:iris/widgets/app_filled_button.dart';
import 'package:iris/widgets/app_outlined_button.dart';
import 'package:iris/widgets/app_text_form_field.dart';
import 'package:iris/widgets/app_text_form_field_password.dart';

class CadastroScreen extends StatelessWidget {
  const CadastroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentGeometry.topCenter,
            end: AlignmentGeometry.bottomCenter,

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
                  //====================
                  // LOGO
                  //====================
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

                  //======================
                  // BTNS
                  //======================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //Btn de login
                      AppOutlinedButton(
                        text: 'Login',
                        borderColor: const Color(0xFFFAF9F6),
                        textColor: const Color(0xFFFAF9F6),
                        onPressed: () {},
                      ),

                      const SizedBox(width: 8),

                      //Precisa de espaçamento
                      AppFilledButton(
                        text: 'Criar Conta',
                        backgroundColor: const Color(0xFFFAF9F6),
                        textColor: const Color(0xFF28174E),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  //=======================
                  // FORM
                  //======================
                  const SizedBox(height: 24),

                  Form(
                    child: Column(
                      children: [
                        //Campo de Email
                        AppTextFormField(
                          labelText: 'Email',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: 'seuemail@gmail.com',
                          backgroundColor: const Color(0xFFFAF9F6),
                        ),

                        const SizedBox(height: 20),
                        //Campo Senha
                        AppTextFormFieldPassword(
                          labelText: 'Senha',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: 'Mínimo de 8 caracteres',
                          backgroundColor: const Color(0xFFFAF9F6),
                          ImageDirectory: 'assets/icons/Eye_Purple.png',
                        ),

                        const SizedBox(height: 20),
                        //Campo confirmar senha
                        AppTextFormFieldPassword(
                          labelText: 'Confirmar senha',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: 'As senhas devem ser iguais',
                          backgroundColor: const Color(0xFFFAF9F6),
                          ImageDirectory: 'assets/icons/Eye_Purple.png',
                        ),

                        const SizedBox(height: 32),

                        const Divider(color: Color(0xFFFAF9F6), thickness: 1),

                        const SizedBox(height: 32),

                        AppTextFormField(
                          labelText: 'Como Gostaria de ser chamado ?',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: '',
                          backgroundColor: const Color(0xFFFAF9F6),
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          child: AppOutlinedButton(
                            text: 'Avançar',
                            borderColor: const Color(0xFFFAF9F6),
                            textColor: const Color(0xFFFAF9F6),
                            onPressed: () {},
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
}
