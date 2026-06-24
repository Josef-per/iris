import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/qr/professional_qr_parser.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/patient_professional/patient_professional_repository.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrcodeScreen extends StatefulWidget {
  const QrcodeScreen({super.key, this.onLinked});

  final VoidCallback? onLinked;

  @override
  State<QrcodeScreen> createState() => _QrcodeScreenState();
}

class _QrcodeScreenState extends State<QrcodeScreen> {
  final _repository = PatientProfessionalRepository();
  final _authService = AuthService();
  final _manualCodeController = TextEditingController();
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _showScanner = false;
  bool _isLinking = false;
  bool _linkHandled = false;
  String? _errorMessage;

  bool get _supportsCameraScanner =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void dispose() {
    _manualCodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _linkWithCode(String rawCode) async {
    if (_isLinking || _linkHandled) {
      return;
    }

    final profissionalId = ProfessionalQrParser.parseProfissionalId(rawCode);

    if (profissionalId == null) {
      setState(() {
        _errorMessage = 'Codigo QR invalido.';
      });
      return;
    }

    setState(() {
      _isLinking = true;
      _errorMessage = null;
    });

    try {
      await _scannerController.stop();
      await _repository.linkCurrentPatientToProfessional(profissionalId);

      if (!mounted) {
        return;
      }

      setState(() {
        _linkHandled = true;
        _showScanner = false;
      });

      widget.onLinked?.call();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = AppErrorMessages.from(error);
      });

      if (_showScanner) {
        await _scannerController.start();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLinking = false;
        });
      }
    }
  }

  void _openScanner() {
    setState(() {
      _showScanner = true;
      _errorMessage = null;
    });
  }

  void _closeScanner() {
    setState(() {
      _showScanner = false;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  void _showManualEntryDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Codigo do profissional'),
          content: TextField(
            controller: _manualCodeController,
            decoration: const InputDecoration(
              hintText: 'Cole o codigo do QR Code',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: _isLinking
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _linkWithCode(_manualCodeController.text);
                    },
              child: const Text('Vincular'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showScanner && _supportsCameraScanner) {
      return _ScannerView(
        controller: _scannerController,
        isLinking: _isLinking,
        errorMessage: _errorMessage,
        onClose: _closeScanner,
        onDetect: (capture) {
          if (capture.barcodes.isEmpty) {
            return;
          }

          final rawValue = capture.barcodes.first.rawValue;
          if (rawValue != null) {
            _linkWithCode(rawValue);
          }
        },
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0XFF7D6AC6), Color(0xFF28174E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Escaneie o QR Code do seu psiquiatra para se conectar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFAF9F6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Esse passo vincula sua conta ao profissional responsavel pelo seu acompanhamento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFFAF9F6),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFD6D6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (_supportsCameraScanner)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLinking ? null : _openScanner,
                        style: OutlinedButton.styleFrom(
                          fixedSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(
                            width: 1,
                            color: Color(0xFFFAF9F6),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/icons/Qr-code_white.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isLinking ? 'Vinculando...' : 'Escanear QR Code',
                              style: const TextStyle(
                                color: Color(0xFFFAF9F6),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_supportsCameraScanner) const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLinking ? null : _showManualEntryDialog,
                      style: OutlinedButton.styleFrom(
                        fixedSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFFFAF9F6),
                        ),
                      ),
                      child: Text(
                        _supportsCameraScanner
                            ? 'Inserir codigo manualmente'
                            : 'Inserir codigo do QR Code',
                        style: const TextStyle(
                          color: Color(0xFFFAF9F6),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _isLinking ? null : _signOut,
                    child: const Text(
                      'Sair da conta',
                      style: TextStyle(color: Color(0xFFFAF9F6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerView extends StatelessWidget {
  const _ScannerView({
    required this.controller,
    required this.isLinking,
    required this.errorMessage,
    required this.onClose,
    required this.onDetect,
  });

  final MobileScannerController controller;
  final bool isLinking;
  final String? errorMessage;
  final VoidCallback onClose;
  final void Function(BarcodeCapture capture) onDetect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Escanear QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: isLinking ? null : onClose,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: controller, onDetect: onDetect),
          if (isLinking)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (errorMessage != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD6D6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF28174E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
