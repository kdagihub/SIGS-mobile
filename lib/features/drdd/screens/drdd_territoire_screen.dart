import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../../../providers/drdd_provider.dart';
import '../tabs/departements_tab.dart';
import '../tabs/localites_tab.dart';

class DrddTerritoireScreen extends ConsumerStatefulWidget {
  const DrddTerritoireScreen({super.key});

  @override
  ConsumerState<DrddTerritoireScreen> createState() =>
      _DrddTerritoireScreenState();
}

class _DrddTerritoireScreenState extends ConsumerState<DrddTerritoireScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final isDR = ref.watch(drddDashboardProvider).isDR;
    final tabCount = isDR ? 2 : 1;

    if (_selectedTab >= tabCount) {
      _selectedTab = 0;
    }

    return Column(
      children: [
        Material(
          color: Colors.white,
          elevation: 1,
          child: Row(
            children: [
              if (isDR)
                _TabButton(
                  icon: Icons.account_tree_rounded,
                  label: 'Départements',
                  selected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
              _TabButton(
                icon: Icons.location_on_rounded,
                label: 'Localités',
                selected: isDR ? _selectedTab == 1 : _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = isDR ? 1 : 0),
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              if (isDR) const DepartementsTab(),
              const LocalitesTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? SigsTheme.primaryOrange : Colors.grey.shade500;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? SigsTheme.primaryOrange : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
