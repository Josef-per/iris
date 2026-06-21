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

                        //Precisa de espaçamento
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
                  //Precisa de espaçamento
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

                        //Espaçamento
                        //Campo Senha
                        AppTextFormFieldPassword(
                          labelText: 'Senha',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: '',
                          backgroundColor: const Color(0xFFFAF9F6),
                          ImageDirectory: 'assets/icons/Eye_Purple.png',
                        ),

                        //Espaçamento
                        //Campo confirmar senha
                        AppTextFormFieldPassword(
                          labelText: 'Confirmar senha',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: '',
                          backgroundColor: const Color(0xFFFAF9F6),
                          ImageDirectory: 'assets/icons/Eye_Purple.png',
                        ),

                        //espaçamento
                        //barra divisória
                        AppTextFormField(
                          labelText: 'Como Gostaria de ser chamado',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: '',
                          backgroundColor: const Color(0xFFFAF9F6),
                        ),

                        //espaçamento
                        //ajustar tamanho do btn, para cobrir todo o espaço disponível
                        AppOutlinedButton(
                          text: 'Avançar',
                          borderColor: const Color(0xFFFAF9F6),
                          textColor: const Color(0xFFFAF9F6),
                          onPressed: () {},
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
