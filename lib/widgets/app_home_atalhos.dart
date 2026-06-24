import 'package:flutter/material.dart';

class AppHomeAtalhos extends StatelessWidget {
  //Parâmetros
  //Cor do card
  final Color cardBackgroundColor1;
  final Color cardBackgroundColor2;

  //Cor da imagem e imagem
  final Color imageBackgroundColor;
  final String imageDirectory;

  //Texto do card
  final String cardText;

  //Para o backend depois adicionar a opção de chamar alguma função
  final VoidCallback onPressed;

  const AppHomeAtalhos({
    super.key,
    required this.cardBackgroundColor1,
    required this.cardBackgroundColor2,
    required this.imageBackgroundColor,
    required this.imageDirectory,
    required this.cardText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          height: 85,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,

              colors: [cardBackgroundColor1, cardBackgroundColor2],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x64000000),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),

              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: imageBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x64000000),
                      blurRadius: 4,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(imageDirectory, width: 40, height: 40),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                cardText,
                style: TextStyle(color: Color(0xFFFAF9F6), fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
