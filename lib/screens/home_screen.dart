import 'package:flutter/material.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/profile/profile_model.dart';
import 'package:iris/features/profile/profile_repository.dart';
import 'package:iris/widgets/app_card_dashboard_simplificado.dart';
import 'package:iris/widgets/app_function_gradient_decoration.dart';
import 'package:iris/widgets/app_home_atalhos.dart';
import 'package:iris/widgets/bottom_sheets/check_in_diario_bottom_sheet.dart';
import 'package:iris/widgets/bottom_sheets/diario_emocional_bottom_sheet.dart';
import 'package:iris/widgets/bottom_sheets/registro_alimentar_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _profileRepository = ProfileRepository();

  late final Future<Profile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileRepository.getCurrentUserProfile();
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  void _openBottomSheet(Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFunctionGradientDecoration(
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FutureBuilder<Profile?>(
                      future: _profileFuture,
                      builder: (context, snapshot) {
                        final displayName = snapshot.data?.displayName.trim();
                        final greetingName =
                            displayName == null || displayName.isEmpty
                            ? 'Olá!'
                            : 'Olá, $displayName!';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greetingName,
                              style: const TextStyle(
                                fontSize: 34,
                                color: Color(0xFFFAF9F6),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Como está hoje?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFFAF9F6),
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: FloatingActionButton(
                      onPressed: _signOut,
                      backgroundColor: const Color(0x997D6AC6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/icons/OpnMenu_white.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    AppCardDashboardSimplificado(
                      imageDirectory: 'assets/icons/Batimento_white.png',
                      textIdentifier: '3/4',
                      textName: 'Refeições',
                    ),
                    SizedBox(width: 16),
                    AppCardDashboardSimplificado(
                      imageDirectory: 'assets/icons/Coracao_white.png',
                      textIdentifier: 'Bom',
                      textName: 'Humor',
                    ),
                    SizedBox(width: 16),
                    AppCardDashboardSimplificado(
                      imageDirectory: 'assets/icons/FrascoRemedio_white.png',
                      textIdentifier: '1/2',
                      textName: 'Medicação',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x64000000),
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                  color: const Color(0xFFFFFFFF),
                ),
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      AppHomeAtalhos(
                        cardBackgroundColor1: const Color(0xFFDBCFFF),
                        cardBackgroundColor2: const Color(0xFF7D6AC6),
                        imageBackgroundColor: const Color(0xBFDBCFFF),
                        imageDirectory: 'assets/icons/Prancheta_white.png',
                        cardText: 'Registro de alimentação',
                        onPressed: () => _openBottomSheet(
                          const RegistroAlimentarBottomSheet(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      AppHomeAtalhos(
                        cardBackgroundColor1: const Color(0xFF7D6AC6),
                        cardBackgroundColor2: const Color(0xFF28174E),
                        imageBackgroundColor: const Color(0x9928174E),
                        imageDirectory: 'assets/icons/Livro_white.png',
                        cardText: 'Check-in diário',
                        onPressed: () =>
                            _openBottomSheet(const CheckInDiarioBottomSheet()),
                      ),
                      const SizedBox(height: 30),
                      AppHomeAtalhos(
                        cardBackgroundColor1: const Color(0xFF7D6AC6),
                        cardBackgroundColor2: const Color(0xFF462A7E),
                        imageBackgroundColor: const Color(0x99462A7E),
                        imageDirectory: 'assets/icons/Coracao_white.png',
                        cardText: 'Diário emocional',
                        onPressed: () => _openBottomSheet(
                          const DiarioEmocionalBottomSheet(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Card.filled(
                color: const Color(0xFFDBCFFF),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Mensagem do dia',
                            style: TextStyle(
                              color: Color(0xFF28174E),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Image.asset('assets/icons/EmogiCoracao_Purple.png'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Você não precisa resolver tudo de uma vez. Cada pequeno passo já é um avanço, mesmo nos dias difíceis. Eles não apagam seu progresso. Seja gentil com você, porque você merece cuidado. Um dia de cada vez já é suficiente.',
                        style: TextStyle(color: Color(0xFF28174E)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
