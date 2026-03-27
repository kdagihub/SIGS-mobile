import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/dialogs.dart';
import '../../../core/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/drdd_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../tabs/associations_tab.dart';
import '../tabs/evenements_tab.dart';
import '../tabs/infrastructures_tab.dart';
import 'drdd_overview_screen.dart';
import 'drdd_territoire_screen.dart';

class DrddShellScreen extends ConsumerStatefulWidget {
  const DrddShellScreen({super.key});

  @override
  ConsumerState<DrddShellScreen> createState() => _DrddShellScreenState();
}

class _DrddShellScreenState extends ConsumerState<DrddShellScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabDef('Accueil', Icons.dashboard_rounded),
    _TabDef('Territoire', Icons.map_rounded),
    _TabDef('Infras', Icons.stadium_rounded),
    _TabDef('Associations', Icons.groups_rounded),
    _TabDef('Événements', Icons.event_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(drddDashboardProvider.notifier).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        context.go(next.sessionExpired ? '/login' : '/role-selection');
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          showExitDialog(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_tabs[_currentIndex].label),
          actions: [
            IconButton(
              onPressed: () =>
                  ref.read(drddDashboardProvider.notifier).fetchDashboard(),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualiser',
            ),
            const SizedBox(width: 4),
            _UserMenuButton(
              fullName: user?.fullName ?? '',
              email: user?.email ?? '',
              group: user?.group,
              onLogout: () => showLogoutDialog(context, ref),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const DrddOverviewScreen(),
            const DrddTerritoireScreen(),
            const InfrastructuresTab(),
            const AssociationsTab(),
            const EvenementsTab(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final selected = i == _currentIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        if (i != _currentIndex) {
                          HapticFeedback.selectionClick();
                          setState(() => _currentIndex = i);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? SigsTheme.primaryOrange
                                        .withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                tab.icon,
                                size: 22,
                                color: selected
                                    ? SigsTheme.primaryOrange
                                    : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tab.label,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? SigsTheme.primaryOrange
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserMenuButton extends StatelessWidget {
  final String fullName;
  final String email;
  final String? group;
  final VoidCallback onLogout;

  const _UserMenuButton({
    required this.fullName,
    required this.email,
    this.group,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.92,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: const ProfileScreen(),
                ),
              ),
            );
          case 'logout':
            onLogout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SigsTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              if (group != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SigsTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    group!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: SigsTheme.primaryOrange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Text(
                'Mon profil',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded,
                  size: 20, color: SigsTheme.dangerRed),
              const SizedBox(width: 12),
              Text(
                'Se déconnecter',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: SigsTheme.dangerRed,
                ),
              ),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: SigsTheme.primaryBlue,
        child: Text(
          userInitials(fullName),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

}

class _TabDef {
  final String label;
  final IconData icon;
  const _TabDef(this.label, this.icon);
}

