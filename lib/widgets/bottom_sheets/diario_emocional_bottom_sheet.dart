import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iris/widgets/app_filled_button.dart';
import 'package:iris/widgets/bottom_sheets/app_bottom_sheet.dart';

class DiarioEmocionalBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          //title
          Text(
            'Diário emocional',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFFFFF),
            ),
          ),

          const SizedBox(height: 7),

          //subtitle
          Text(
            'Registre suas emoções e sintomas',
            style: TextStyle(fontSize: 14, color: const Color(0x99FFFFFF)),
          ),

          const SizedBox(height: 20),

          //Campo de envio
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Como você está se sentindo?",
                  style: TextStyle(
                    color: Color(0xFF462A7E),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        size: 42,
                        color: Color(0xFF2D175E),
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: "To me sentindo bem ruinzinha viu",
                          hintStyle: TextStyle(
                            color: Color(0xFF2D175E),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF2D175E),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 33),
          //spacing
          Align(
            alignment: Alignment.bottomRight,
            child: AppFilledButton(
              text: 'Confirmar →',
              backgroundColor: const Color(0xFF7D6AC6),
              textColor: const Color(0xFFFAF9F6),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
