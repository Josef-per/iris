import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iris/widgets/app_check_in_image_time_picker.dart';
import 'package:iris/widgets/app_slider.dart';
import 'package:iris/widgets/app_text_observacoes.dart';

class AppCheckInForm extends StatelessWidget {
  final File image;

  const AppCheckInForm({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IMAGE + TIME PICKER
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 24),

              // aqui você pode usar a imagem futuramente
              AppCheckInImageTimePicker(),

              const SizedBox(height: 12),

              // preview opcional da imagem tirada
              //Image.file(image, width: double.infinity, fit: BoxFit.cover),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // FORM CARD
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Text(
                    'Nível de fome',
                    style: TextStyle(
                      color: Color(0xFF3E2D73),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.info_outline, color: Color(0xFF3E2D73), size: 15),
                ],
              ),

              SizedBox(height: 20),

              AppSlider(),

              SizedBox(height: 20),

              AppTextObservacoes(
                textLabel: 'Como se sentiu ?',
                textHint: 'Adicione as suas observações aqui ...',
                textLines: 2,
              ),

              SizedBox(height: 20),

              AppTextObservacoes(
                textLabel: 'Algum alimento foi mais desafiador?',
                textHint: 'Adicione as suas observações aqui ...',
                textLines: 2,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
