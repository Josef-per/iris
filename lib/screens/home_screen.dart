import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        //estilizar e colocar tamanho no container
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsetsGeometry.symmetric(
                vertical: 30,
                horizontal: 30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //=================
                  // CABEÇALHO
                  //=================
                  Column(
                    children: [
                      Row(
                        children: [
                          //Texto de introdução
                          Column(
                            children: [
                              Text('Olá Marilene'),
                              Text('Como está hoje'),
                            ],
                          ),

                          //espaçamento
                          //Menu flutuante
                          FloatingActionButton(
                            onPressed: () {},
                            //pegar o ícone
                            child: Image.asset(''),
                          ),
                        ],
                      ),

                      //espaçamento
                      Row(
                        children: [
                          //Card Refeições
                          Card.filled(
                            child: Column(
                              children: [
                                Image.asset(''),
                                //espaçamento
                                Text(''),
                                //espaçamento
                                Text(''),
                              ],
                            ),
                          ),

                          //espaçamento
                          //card Humor
                          Card.filled(
                            child: Column(
                              children: [
                                Image.asset(''),
                                //espaçamento
                                Text(''),
                                //espaçamento
                                Text(''),
                              ],
                            ),
                          ),

                          //espaçamento
                          //card Medicação
                          Card.filled(
                            child: Column(
                              children: [
                                Image.asset(''),
                                //espaçamento
                                Text(''),
                                //espaçamento
                                Text(''),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  //espaçamento
                  //==================
                  // MAIN
                  //==================
                  Column(
                    children: [
                      //btns
                      Container(
                        //Adicionar os estilos ao container
                        child: Column(
                          children: [
                            //Btn atalho Registro de alimentação
                            Container(
                              //estilizar o container
                              child: FilledButton(
                                onPressed: () {},
                                child: Row(
                                  children: [
                                    Container(
                                      //Estilizar o container
                                      //Adicionar o icone certo
                                      child: Image.asset(''),
                                    ),
                                    Text(''),
                                  ],
                                ),
                              ),
                            ),

                            //espaçamento
                            //Btn atalho Check-in Diário
                            Container(
                              //estilizar o container
                              child: FilledButton(
                                onPressed: () {},
                                child: Row(
                                  children: [
                                    Container(
                                      //Estilizar o container
                                      //Adicionar o icone certo
                                      child: Image.asset(''),
                                    ),
                                    Text(''),
                                  ],
                                ),
                              ),
                            ),

                            //espaçamento
                            //Btn Diário Emocional
                            Container(
                              //estilizar o container
                              child: FilledButton(
                                onPressed: () {},
                                child: Row(
                                  children: [
                                    Container(
                                      //Estilizar o container
                                      //Adicionar o icone certo
                                      child: Image.asset(''),
                                    ),
                                    Text(''),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      //Espaçamento
                      //Mensagem do dia
                      Card.filled(
                        child: Column(
                          children: [
                            Row(children: [Text(''), Image.asset('')]),
                            Text(''),
                          ],
                        ),
                      ),
                    ],
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
