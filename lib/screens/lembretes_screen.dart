import 'package:flutter/material.dart';
import 'package:iris/widgets/app_function_gradient_decoration.dart';

class LembretesScreen extends StatelessWidget {
  LembretesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFunctionGradientDecoration(
      content: Column(
        children: [
          //Btn de voltar para a tela inicial
          FilledButton(onPressed: () {}, child: Text('')),

          //espaçamento
          SizedBox(height: 10),

          //Title
          Text(''),

          //espaçamento
          SizedBox(height: 4),

          //subtitle
          Text(''),

          //espaçaento
          SizedBox(height: 4),

          //btn centralizado
          FilledButton(
            onPressed:
                //aqui vai abrir o pop pra ele cadastrar algo novo
                () {},
            child: Text(''),
          ),

          //espaçaemtno
          SizedBox(height: 4),

          //campo de alteração das refeições e dos medicamentos
          Column(
            children: [
              //Title
              Row(
                children: [
                  //Image.asset(''),
                  SizedBox(width: 4),
                  Text(''),
                ],
              ),

              //espaçamento
              SizedBox(height: 4),

              Container(
                //=-=-=-=-=-=-=-=--=-=
                //adicionar o style ao container e um padding nele
                //=-=-=-=-=-=-=-=-=-=-=
                child: Row(
                  children: [
                    //tipo do lembrete pelo seu ícone
                    Container(
                      child: Padding(padding: EdgeInsets.all(4)),
                      //Image.asset(''),
                    ),

                    //espaçamento
                    SizedBox(width: 4),

                    //informações do lembrete
                    Column(
                      children: [
                        //nome do lembrete
                        Text(''),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            //Horário que vai ser disparado o lembrete
                            //Image.asset('')
                            Text(''),
                          ],
                        ),
                      ],
                    ),

                    //espaçamento
                    SizedBox(width: 4),

                    //Switch
                    Switch(value: false, onChanged: (value) => ()),

                    //espaçametno
                    SizedBox(width: 5),

                    //Btn semelhante ao de voltar mas com ícone e cores diferentes
                    FilledButton(
                      onPressed: () {},
                      child: Text(''),
                      //Image.asset('')
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
