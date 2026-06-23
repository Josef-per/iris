import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iris/widgets/app_add_photo_section.dart';
import 'package:iris/widgets/app_align_filled_button.dart';
import 'package:iris/widgets/app_check_in_form.dart';
import 'package:iris/widgets/app_check_in_header.dart';
import 'package:iris/widgets/bottom_sheets/app_bottom_sheet.dart';

class CheckInAlimentarBottomSheet extends StatefulWidget {
  const CheckInAlimentarBottomSheet({super.key});

  @override
  State<CheckInAlimentarBottomSheet> createState() =>
      _CheckInAlimentarBottomSheetState();
}

enum CheckInStep { photo, form }

class _CheckInAlimentarBottomSheetState
    extends State<CheckInAlimentarBottomSheet> {
  CheckInStep _step = CheckInStep.photo;
  File? _image;

  void _takePhoto() async {
    File fakeImage = File('path');

    setState(() {
      _image = fakeImage;
      _step = CheckInStep.form;
    });
  }

  void _submit() {
    // Aqui você envia os dados do formulário
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ======================
              // HEADER
              // ======================
              const AppCheckInHeader(
                TextTitle: 'Check-in alimentar',
                TextSubTitle: 'Registre rapidamente suas refeições',
              ),

              const SizedBox(height: 16),

              // ======================
              // CONTEÚDO DINÂMICO
              // ======================
              if (_step == CheckInStep.photo)
                AppAddPhotoSection(onPressed: _takePhoto)
              else
                AppCheckInForm(image: _image!),

              const SizedBox(height: 20),

              // ======================
              // BOTÃO
              // ======================
              AppAlignFilledButton(
                TextButton: _step == CheckInStep.photo
                    ? 'Tirar foto'
                    : 'Confirmar →',
                BackgroundColor: const Color(0xFF7D6AC6),
                TextColor: const Color(0xFFFAF9F6),
                onPressed: _step == CheckInStep.photo ? _takePhoto : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
