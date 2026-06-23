import 'package:flutter/material.dart';

class AppAddPhotoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 64,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4F3A8A),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: Colors.grey.shade400,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            onPressed: () {},
            child: Row(
              children: [
                Image.asset('assets/icons/Camera_Purple.png', width: 26),

                const SizedBox(width: 18),

                const Text(
                  'Adicionar foto',
                  style: TextStyle(
                    color: Color(0xFF462A7E),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),

        //========================
        // CARD
        //========================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Color(0x99FFFFFF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/icons/EscudoVerificado_Purple.png',
                width: 34,
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seus dados estão seguros',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color(0xFF462A7E),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Suas informações são privadas e utilizadas somente para o seu acompanhamento.',
                      style: TextStyle(color: Color(0xFF462A7E), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
