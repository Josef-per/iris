import 'package:flutter/material.dart';
import 'package:iris/screens/home_screen.dart';
//import 'package:iris/screens/qrCode_screen.dart';
//import 'package:iris/screens/cadastro_screen.dart';
//import 'package:iris/screens/login_screen.dart';

//vou considerar para ser mais prático para testes a primeira tela a dela a de login sem ser a de splash

void main() {
  runApp(Iris_app());
}

class Iris_app extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen());
  }
}
