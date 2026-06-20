import 'package:flutter/material.dart';
import 'package:iris/widgets/app_filled_button.dart';
import 'package:iris/widgets/app_outlined_button.dart';
import 'package:iris/widgets/app_text_form_field.dart';
import 'package:iris/widgets/app_text_form_field_password.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Começar com o container pra poder estilizar a tela dps
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentGeometry.topCenter,
            end: AlignmentGeometry.bottomCenter,

            colors: [Color(0XFF7D6AC6), Color(0xFF28174E)],
          ),
        ),
        //Isso faz com que a altura e a largura da tela sejam totalmente ocupados
        width: double.infinity,
        height: double.infinity,

        //Começar a tela
        //Campo de defesa da barra de notificações
        child: SafeArea(
          //Scroll
          child: SingleChildScrollView(
            //Pading que cobre toda a tela pra não ficar ruim de ver
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),

              //Aqui que realmente tudo começa, igual a estrutura que vemos no figma
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

                  const SizedBox(height: 40),

                  //====================
                  // BOTÕES LOGIN / CADASTRO
                  //====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppFilledButton(
                        text: 'Login',
                        backgroundColor: const Color(0xFFFAF9F6),
                        textColor: const Color(0xFF28174E),
                        onPressed: () {},
                      ),

                      const SizedBox(width: 15),

                      AppOutlinedButton(
                        text: 'Criar Conta',
                        borderColor: const Color(0xFFFAF9F6),
                        textColor: const Color(0xFFFAF9F6),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 45),

                  //====================
                  // FORMULÁRIO
                  //====================
                  Form(
                    child: Column(
                      children: [
                        AppTextFormField(
                          labelText: 'Email',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: 'seuemail@email.com',
                          backgroundColor: const Color(0xFFFAF9F6),
                        ),

                        const SizedBox(height: 20),

                        AppTextFormFieldPassword(
                          labelText: 'Senha',
                          labelColor: const Color(0xFFFAF9F6),
                          hintColor: const Color(0xFF28174E),
                          hintText: '',
                          backgroundColor: const Color(0xFFFAF9F6),
                          ImageDirectory: 'assets/icons/Eye_Purple.png',
                        ),

                        const SizedBox(height: 35),

                        SizedBox(
                          width: double.infinity,
                          child: AppOutlinedButton(
                            text: 'Entrar',
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
