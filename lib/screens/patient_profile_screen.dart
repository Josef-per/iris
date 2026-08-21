import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/profile/profile_model.dart';
import 'package:iris/features/profile/profile_repository.dart';
import 'package:iris/widgets/app_responsive.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({
    super.key,
    required this.onBack,
    required this.onSignOut,
  });

  final VoidCallback onBack;
  final Future<void> Function() onSignOut;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _profileRepository = ProfileRepository();
  late Future<Profile?> _profileFuture;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileRepository.getCurrentUserProfile();
  }

  void _reload() {
    setState(() {
      _profileFuture = _profileRepository.getCurrentUserProfile();
    });
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await widget.onSignOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMessages.from(error))),
      );
      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppGradientHeader(
              child: AppResponsive(
                maxWidth: 760,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: widget.onBack,
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.white,
                        backgroundColor: AppColors.white.withValues(alpha: .1),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Perfil',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Seus dados e configurações da conta.',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AppResponsive(
              maxWidth: 760,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
              child: FutureBuilder<Profile?>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return AppSurface(
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 44,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Não foi possível carregar o perfil',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    );
                  }

                  final name = snapshot.data?.displayName.trim();
                  return AppSurface(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          child: const Icon(Icons.person_rounded, size: 38),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name == null || name.isEmpty ? 'Paciente' : name,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        const Divider(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isSigningOut ? null : _signOut,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                            ),
                            icon: _isSigningOut
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.logout_rounded),
                            label: Text(
                              _isSigningOut ? 'Saindo...' : 'Sair da conta',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
