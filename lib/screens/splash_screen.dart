import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iris/core/theme/app_theme.dart';

class IrisSplashScreen extends StatefulWidget {
  const IrisSplashScreen({super.key, required this.next});

  final Widget next;

  @override
  State<IrisSplashScreen> createState() => _IrisSplashScreenState();
}

class _IrisSplashScreenState extends State<IrisSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: .92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 1250), _openNext);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) => widget.next,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/Login.svg',
                    width: MediaQuery.sizeOf(context).width < 600 ? 230 : 330,
                    fit: BoxFit.contain,
                    semanticsLabel: 'Íris',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Cuidado que acompanha.',
                    style: TextStyle(
                      color: AppColors.lavender,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2.4,
                      semanticsLabel: 'Carregando Íris',
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
