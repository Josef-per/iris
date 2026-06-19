import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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

                      const Text('Seu espaço de bem-estar e autocuidado'),
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
                    FilledButton(onPressed: () {}, child: const Text("Login")),

                    const SizedBox(width: 15),

                    FilledButton(
                      onPressed: () {},
                      child: const Text("Cadastrar"),
                    ),
                  ],
                ),

                const SizedBox(height: 45),

                //====================
                // FORMULÁRIO
                //====================
                const Text("Email"),

                const SizedBox(height: 10),

                TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "seuemail@gmail.com",
                  ),
                ),

                const SizedBox(height: 25),

                const Text("Senha"),

                const SizedBox(height: 10),

                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),

                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset("assets/icons/Eye_Purple.png"),
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text("Entrar"),
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
