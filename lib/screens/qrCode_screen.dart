import 'package:flutter/material.dart';

class QrcodeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentGeometry.topCenter,
            end: AlignmentGeometry.bottomCenter,

            colors: [Color(0XFF7D6AC6), Color(0xFF28174E)],
          ),
        ),
        width: double.infinity,
        height: double.infinity,

        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Escaneie o QR Code do seu psiquiatra para se conectar'),
                  OutlinedButton(onPressed: () {}, child: Text('Avançar')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
