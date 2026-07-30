import 'package:flutter/material.dart';
import 'package:iris/core/supabase/supabase_config.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/professional/presentation/professional_care_plan_view.dart';
import 'package:iris/features/professional/presentation/professional_dashboard_view.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_mock_data.dart';
import 'package:iris/features/professional/presentation/professional_notes_view.dart';
import 'package:iris/features/professional/presentation/professional_patient_detail_view.dart';
import 'package:iris/features/professional/presentation/professional_patients_view.dart';
import 'package:iris/features/professional/presentation/professional_settings_view.dart';
import 'package:iris/screens/login_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfessionalHomeScreen extends StatefulWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  State<ProfessionalHomeScreen> createState() => _ProfessionalHomeScreenState();
}

class _ProfessionalHomeScreenState extends State<ProfessionalHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _authService = AuthService();
  final _store = ProfessionalFrontendStore.seeded();
  final _notifications = <String>[
    'Consulta com Ana Paula às 14:00',
    'Carlos está há 24h sem check-in',
  ];

  ProfessionalDestination _destination = ProfessionalDestination.dashboard;
  ProfessionalPatient _selectedPatient = ProfessionalMockData.patients.first;
  ProfessionalPatient? _detailPatient;

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  void _selectDestination(ProfessionalDestination destination) {
    setState(() {
      _destination = destination;
      _detailPatient = null;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _openPatient(ProfessionalPatient patient) {
    setState(() {
      _selectedPatient = patient;
      _detailPatient = patient;
      _destination = ProfessionalDestination.patients;
    });
  }

  void _openCarePlan([ProfessionalPatient? patient]) {
    setState(() {
      if (patient != null) _selectedPatient = patient;
      _detailPatient = null;
      _destination = ProfessionalDestination.carePlan;
    });
  }

  Future<void> _signOut() async {
    if (SupabaseConfig.isConfigured) {
      await _authService.signOut();
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showInvitePatient() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vincular novo paciente'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Peça ao paciente para escanear o QR Code.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lavender),
                ),
                child: QrImageView(
                  data: 'iris:professional:demo-julia-souza',
                  size: 210,
                  backgroundColor: AppColors.white,
                  eyeStyle: const QrEyeStyle(color: AppColors.ink),
                  dataModuleStyle: const QrDataModuleStyle(
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotifications() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Notificações'),
          content: SizedBox(
            width: 420,
            child: _notifications.isEmpty
                ? const Text('Nenhuma notificação.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final notification in _notifications)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.notifications_none_rounded),
                          title: Text(notification),
                        ),
                    ],
                  ),
          ),
          actions: [
            if (_notifications.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(_notifications.clear);
                  setDialogState(() {});
                },
                child: const Text('Marcar como lidas'),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
    final navigation = ProfessionalNavigation(
      destination: _destination,
      showingPatientDetail: _detailPatient != null,
      onSelected: _selectDestination,
      onSignOut: _signOut,
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: desktop ? null : Drawer(width: 292, child: navigation),
      body: Row(
        children: [
          if (desktop) SizedBox(width: 280, child: navigation),
          Expanded(
            child: Column(
              children: [
                if (!desktop)
                  _MobileProfessionalBar(
                    title: _pageTitle,
                    notificationCount: _notifications.length,
                    onMenuPressed: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                    onNotificationsPressed: _showNotifications,
                  ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _store,
                    builder: (context, _) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: KeyedSubtree(
                        key: ValueKey(
                          '${_destination.name}-${_detailPatient?.id ?? 'list'}',
                        ),
                        child: _currentView,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _pageTitle {
    if (_detailPatient != null) return _detailPatient!.name;
    return switch (_destination) {
      ProfessionalDestination.dashboard => 'Visão geral',
      ProfessionalDestination.patients => 'Pacientes',
      ProfessionalDestination.notes => 'Anotações',
      ProfessionalDestination.carePlan => 'Plano de cuidado',
      ProfessionalDestination.settings => 'Configurações',
    };
  }

  Widget get _currentView {
    final detailPatient = _detailPatient;
    if (detailPatient != null) {
      return ProfessionalPatientDetailView(
        store: _store,
        patient: detailPatient,
        onBack: () => setState(() => _detailPatient = null),
        onOpenCarePlan: () => _openCarePlan(detailPatient),
      );
    }

    return switch (_destination) {
      ProfessionalDestination.dashboard => ProfessionalDashboardView(
        store: _store,
        onOpenPatients: () =>
            _selectDestination(ProfessionalDestination.patients),
        onOpenPatient: _openPatient,
      ),
      ProfessionalDestination.patients => ProfessionalPatientsView(
        store: _store,
        onOpenPatient: _openPatient,
        onInvitePatient: _showInvitePatient,
      ),
      ProfessionalDestination.notes => ProfessionalNotesView(
        store: _store,
        onOpenPatient: _openPatient,
      ),
      ProfessionalDestination.carePlan => ProfessionalCarePlanView(
        store: _store,
        initialPatient: _selectedPatient,
        onOpenPatient: _openPatient,
      ),
      ProfessionalDestination.settings => ProfessionalSettingsView(
        store: _store,
      ),
    };
  }
}

class ProfessionalNavigation extends StatelessWidget {
  const ProfessionalNavigation({
    super.key,
    required this.destination,
    required this.showingPatientDetail,
    required this.onSelected,
    required this.onSignOut,
  });

  final ProfessionalDestination destination;
  final bool showingPatientDetail;
  final ValueChanged<ProfessionalDestination> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Image.asset(
                  'assets/images/Login.png',
                  height: 92,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0x33FFFFFF)),
              const SizedBox(height: 22),
              _NavigationItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_rounded,
                label: 'Visão geral',
                selected:
                    destination == ProfessionalDestination.dashboard &&
                    !showingPatientDetail,
                onTap: () => onSelected(ProfessionalDestination.dashboard),
              ),
              _NavigationItem(
                icon: Icons.people_alt_outlined,
                selectedIcon: Icons.people_alt_rounded,
                label: 'Pacientes',
                selected:
                    destination == ProfessionalDestination.patients ||
                    showingPatientDetail,
                onTap: () => onSelected(ProfessionalDestination.patients),
              ),
              _NavigationItem(
                icon: Icons.auto_stories_outlined,
                selectedIcon: Icons.auto_stories_rounded,
                label: 'Anotações',
                selected: destination == ProfessionalDestination.notes,
                onTap: () => onSelected(ProfessionalDestination.notes),
              ),
              _NavigationItem(
                icon: Icons.health_and_safety_outlined,
                selectedIcon: Icons.health_and_safety_rounded,
                label: 'Plano de cuidado',
                selected: destination == ProfessionalDestination.carePlan,
                onTap: () => onSelected(ProfessionalDestination.carePlan),
              ),
              _NavigationItem(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                label: 'Configurações',
                selected: destination == ProfessionalDestination.settings,
                onTap: () => onSelected(ProfessionalDestination.settings),
              ),
              const Spacer(),
              const Divider(color: Color(0x33FFFFFF)),
              const SizedBox(height: 14),
              const _ProfessionalIdentity(),
              const SizedBox(height: 14),
              const Divider(color: Color(0x33FFFFFF)),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onSignOut,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.lavender.withValues(alpha: .7),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.white.withValues(alpha: .15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  color: AppColors.white,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfessionalIdentity extends StatelessWidget {
  const _ProfessionalIdentity();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Color(0x337D6AC6),
            child: Icon(Icons.person_outline_rounded, color: AppColors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Júlia Souza',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Psiquiatra',
                  style: TextStyle(color: AppColors.lavender, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileProfessionalBar extends StatelessWidget {
  const _MobileProfessionalBar({
    required this.title,
    required this.notificationCount,
    required this.onMenuPressed,
    required this.onNotificationsPressed,
  });

  final String title;
  final int notificationCount;
  final VoidCallback onMenuPressed;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Abrir menu',
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Notificações',
                onPressed: onNotificationsPressed,
                icon: Badge(
                  isLabelVisible: notificationCount > 0,
                  label: Text('$notificationCount'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
