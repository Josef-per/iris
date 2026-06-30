import 'package:flutter/material.dart';
import 'package:iris/widgets/app_filled_button_pre_icon.dart';
import 'package:iris/widgets/app_function_gradient_decoration.dart';
import 'package:iris/widgets/app_function_headers.dart';
import 'package:iris/widgets/app_lembretes_field.dart';

class LembretesScreen extends StatelessWidget {
  LembretesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFunctionGradientDecoration(
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AppFunctionHeaders(
            onTap: () {},
            title: 'Lembretes',
            subTitle: 'Gerencie seus lembretes diários',
          ),

          //espaçaento
          SizedBox(height: 20),

          //btn centralizado
          AppFilledButtonPreIcon(
            onTap: () {},
            icon: 'assets/icons/Add_purple.png',
            text: 'Adiconar lembrete',
          ),
          //espaçaemtno
          SizedBox(height: 80),

          //campo de alteração das refeições e dos medicamentos
          Column(
            children: [
              //Title
              //=-=-=-==-=-=-=-=-=-=-=-
              //Resolver o problema de mostrar os componentes ainda hoje
              //=-=-=-=-=-=-=-=-=-=-=-=-
              AppLembretesField(
                iconSection: 'assets/icons/GarfoColher_purple.png',
                textSection: 'Refeições',
              ),

              //espaçamento
              SizedBox(height: 4),
            ],
          ),
        ],
      ),
    );
  }
}
