import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/qr/professional_qr_parser.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/patient_professional/patient_professional_repository.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:iris/widgets/app_responsive.dart';

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
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: AppResponsive(
                maxWidth: 560,
                child: AppSurface(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.lavender.withValues(alpha: .7),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 36,
                          color: AppColors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Conecte-se ao seu profissional',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Escaneie o QR Code fornecido pelo profissional responsável pelo seu acompanhamento.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      if (_supportsCameraScanner)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isLinking ? null : _openScanner,
                            icon: const Icon(Icons.center_focus_strong_rounded),
                            label: Text(
                              _isLinking ? 'Vinculando...' : 'Escanear QR Code',
                            ),
                          ),
                        ),
                      if (_supportsCameraScanner) const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLinking ? null : _showManualEntryDialog,
                          child: Text(
                            _supportsCameraScanner
                                ? 'Inserir código manualmente'
                                : 'Inserir código do QR Code',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _isLinking ? null : _signOut,
                        child: const Text('Sair da conta'),
                      ),
                    ],
                  ),
                ),
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
