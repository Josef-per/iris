import 'package:flutter/material.dart';

class AppHomeAtalhos extends StatelessWidget {
  //Parâmetros
  //Cor do card
  final Color CardBackGroundColor1;
  final Color CardBackGroundColor2;

  //Cor da imagem e imagem
  final Color ImageBackGroundColor;
  final String ImageDirectory;

  //Texto do card
  final String CardText;

  //Para o backend depois adicionar a opção de chamar alguma função
  final VoidCallback onPressed;

  const AppHomeAtalhos({
    super.key,
    required this.CardBackGroundColor1,
    required this.CardBackGroundColor2,
    required this.ImageBackGroundColor,
    required this.ImageDirectory,
    required this.CardText,
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
              begin: AlignmentGeometry.topCenter,
              end: AlignmentGeometry.bottomCenter,

              colors: [CardBackGroundColor1, CardBackGroundColor2],
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
                  color: ImageBackGroundColor,
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
                  child: Image.asset(ImageDirectory, width: 40, height: 40),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                CardText,
                style: TextStyle(color: Color(0xFFFAF9F6), fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
