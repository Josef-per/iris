import 'package:flutter/material.dart';
import 'package:iris/widgets/app_card_dashboard_simplificado.dart';
import 'package:iris/widgets/app_home_atalhos.dart';
import 'package:iris/widgets/bottom_sheets/check_in_alimentar_bottom_sheet.dart';
import 'package:iris/widgets/bottom_sheets/diario_emocional_bottom_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFFAF9F6),
          ),

          Container(
            width: double.infinity,
            height: 330,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF28174E),
                  Color(0xFF53418A),
                  Color(0xFF7D6AC6),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsetsGeometry.symmetric(
                  vertical: 30,
                  horizontal: 30,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Olá, Marilene !',
                                  style: TextStyle(
                                    fontSize: 34,
                                    color: const Color(0xFFFAF9F6),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  'Como está hoje ?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFFFAF9F6),
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ],
                            ),

                            const SizedBox(width: 70),

                            //Menu flutuante
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              width: 40,
                              height: 40,

                              child: FloatingActionButton(
                                onPressed: () {},
                                backgroundColor: const Color(0x997D6AC6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.circular(
                                    16,
                                  ),
                                ),

                                //pegar o ícone
                                child: Center(
                                  child: Image.asset(
                                    'assets/icons/OpnMenu_white.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            //Card Refeições
                            AppCardDashboardSimplificado(
                              ImageDirectory:
                                  'assets/icons/Batimento_white.png',
                              TextIdentifier: '3/4',
                              TextName: 'Refeições',
                            ),

                            const SizedBox(width: 25),
                            //card Humor
                            AppCardDashboardSimplificado(
                              ImageDirectory: 'assets/icons/Coracao_white.png',
                              TextIdentifier: 'Bom',
                              TextName: 'Humor',
                            ),

                            const SizedBox(width: 25),
                            //card Medicação
                            AppCardDashboardSimplificado(
                              ImageDirectory:
                                  'assets/icons/FrascoRemedio_white.png',
                              TextIdentifier: '1/2',
                              TextName: 'Medicação',
                            ),
                          ],
                        ),
                      ],
                    ),

                    //espaçamento
                    //==================
                    // MAIN
                    //==================
                    const SizedBox(height: 20),

                    Column(
                      children: [
                        //btns
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x64000000),
                                offset: Offset(0, 4),
                                blurRadius: 4,
                              ),
                            ],
                            color: const Color(0xFFFFFFFF),
                          ),

                          width: 359,
                          height: 355,

                          //Adicionar os estilos ao container
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Registro de alimentação
                                AppHomeAtalhos(
                                  CardBackGroundColor1: const Color(0xFFDBCFFF),
                                  CardBackGroundColor2: const Color(0xFF7D6AC6),
                                  ImageBackGroundColor: const Color(0xBFDBCFFF),
                                  ImageDirectory:
                                      'assets/icons/Prancheta_white.png',
                                  CardText: 'Registro de alimentação',
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) {
                                        return CheckInAlimentarBottomSheet();
                                      },
                                    );
                                  },
                                ),

                                const SizedBox(height: 30),

                                AppHomeAtalhos(
                                  CardBackGroundColor1: const Color(0xFF7D6AC6),
                                  CardBackGroundColor2: const Color(0xFF28174E),
                                  ImageBackGroundColor: const Color(0x9928174E),
                                  ImageDirectory:
                                      'assets/icons/Livro_white.png',
                                  CardText: 'Check-in diário',
                                  onPressed: () {},
                                ),

                                const SizedBox(height: 30),

                                AppHomeAtalhos(
                                  CardBackGroundColor1: const Color(0xFF7D6AC6),
                                  CardBackGroundColor2: const Color(0xFF462A7E),
                                  ImageBackGroundColor: const Color(0x99462A7E),
                                  ImageDirectory:
                                      'assets/icons/Coracao_white.png',
                                  CardText: 'Diário emocional',
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) {
                                        return DiarioEmocionalBottomSheet();
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                        //Mensagem do dia
                        Card.filled(
                          color: const Color(0xFFDBCFFF),
                          child: Padding(
                            padding: EdgeInsetsGeometry.all(10),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Mensagem do dia',
                                      style: TextStyle(
                                        color: const Color(0xFF28174E),
                                        fontSize: 14,
                                      ),
                                    ),

                                    const SizedBox(width: 5),

                                    Image.asset(
                                      'assets/icons/EmogiCoracao_Purple.png',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  'Você não precisa resolver tudo de uma vez. Cada pequeno passo já é um avanço, mesmo nos dias difíceis. Eles não apagam seu progresso. Seja gentil com você, porque você merece cuidado. Um dia de cada vez já é suficiente.',
                                  style: TextStyle(
                                    color: const Color(0xFF28174E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
