import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/professional/professional_repository.dart';
import 'package:iris/features/profile/profile_model.dart';
import 'package:iris/features/profile/profile_repository.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfessionalHomeScreen extends StatefulWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  State<ProfessionalHomeScreen> createState() => _ProfessionalHomeScreenState();
}

class _ProfessionalHomeScreenState extends State<ProfessionalHomeScreen> {
  final _authService = AuthService();
  final _professionalRepository = ProfessionalRepository();
  final _profileRepository = ProfileRepository();

  late final Future<_ProfessionalHomeData> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _loadHomeData();
  }

  Future<_ProfessionalHomeData> _loadHomeData() async {
    final profile = await _profileRepository.getCurrentUserProfile();
    final qrPayload = await _professionalRepository.getCurrentProfessionalQrPayload();
    final linkedPatients = await _professionalRepository.countLinkedPatients();

    return _ProfessionalHomeData(
      profile: profile,
      qrPayload: qrPayload,
      linkedPatients: linkedPatients,
    );
  }

  Future<void> _copyQrPayload(String qrPayload) async {
    await Clipboard.setData(ClipboardData(text: qrPayload));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Codigo copiado para a area de transferencia.')),
    );
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFFAF9F6),
          ),
          Container(
            width: double.infinity,
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF28174E),
                  Color(0xFF53418A),
                  Color(0xFF7D6AC6),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          SafeArea(
            child: FutureBuilder<_ProfessionalHomeData>(
              future: _homeDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppErrorMessages.from(snapshot.error!),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _homeDataFuture = _loadHomeData();
                              });
                            },
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final data = snapshot.data!;
                final displayName = data.profile?.displayName.trim();
                final greetingName =
                    displayName == null || displayName.isEmpty
                    ? 'Profissional'
                    : displayName;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ola, $greetingName!',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Color(0xFFFAF9F6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${data.linkedPatients} paciente(s) vinculado(s)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFFAF9F6),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x64000000),
                              offset: Offset(0, 4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'QR Code de vinculo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF28174E),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Peça para o paciente escanear este QR Code ao criar conta ou entrar no app.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF28174E),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Color(0xFFDBCFFF)),
                              ),
                              child: QrImageView(
                                data: data.qrPayload,
                                version: QrVersions.auto,
                                size: 220,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF28174E),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF28174E),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SelectableText(
                              data.qrPayload,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF53418A),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _copyQrPayload(data.qrPayload),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF28174E),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Copiar codigo',
                                  style: TextStyle(color: Color(0xFF28174E)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalHomeData {
  const _ProfessionalHomeData({
    required this.profile,
    required this.qrPayload,
    required this.linkedPatients,
  });

  final Profile? profile;
  final String qrPayload;
  final int linkedPatients;
}
