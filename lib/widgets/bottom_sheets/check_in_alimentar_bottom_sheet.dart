import 'package:flutter/material.dart';
import 'package:iris/widgets/app_filled_button.dart';
import 'package:iris/widgets/bottom_sheets/app_bottom_sheet.dart';

class CheckInAlimentarBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          //espaçamento
          //==============
          //TITLE
          //==============
          Text('Check-in Alimentar'),
          //espaçamento
          Text('Registre rapidamente suas refeições '),
          //espaçamento
          FilledButton(
            onPressed: () {},
            child: Row(
              children: [
                Image.asset('assets/icons/Camera_Purple.png'),
                //espaçamento
                Text('Adicionar foto'),
              ],
            ),
          ),
          //espaçamento
          Card(
            child: Row(
              children: [
                Image.asset('assets/icons/EscudoVerificado_Purple.png'),
                //espaçamento
                Column(
                  children: [
                    Text('Seus dados estão seguros'),
                    Text(
                      'Suas informações são privadas e utilizadas somente para o seu acompanhamento',
                    ),
                  ],
                ),
              ],
            ),
          ),

          //espaçamento
          //alinhamento
          AppFilledButton(
            text: 'Continuar ->',
            backgroundColor: const Color(0xFF7D6AC6),
            textColor: const Color(0xFFFAF9F6),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
