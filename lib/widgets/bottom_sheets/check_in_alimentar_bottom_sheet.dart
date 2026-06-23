import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iris/widgets/app_add_photo_section.dart';
import 'package:iris/widgets/app_align_filled_button.dart';
import 'package:iris/widgets/app_check_in_header.dart';
import 'package:iris/widgets/bottom_sheets/app_bottom_sheet.dart';

class CheckInAlimentarBottomSheet extends StatefulWidget {
  const CheckInAlimentarBottomSheet({super.key});

  @override
  State<CheckInAlimentarBottomSheet> createState() =>
      _CheckInAlimentarBottomSheetState();
}

class _CheckInAlimentarBottomSheetState
    extends State<CheckInAlimentarBottomSheet> {
  File? _image;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCheckInHeader(
              TextTitle: 'Check-in alimentar',
              TextSubTitle: 'Registre rapidamente suas refeições',
            ),

            AppAddPhotoSection(),

            AppAlignFilledButton(
              TextButton: 'Confirmar →',
              BackgroundColor: const Color(0xFF7D6AC6),
              TextColor: const Color(0xFFFAF9F6),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
