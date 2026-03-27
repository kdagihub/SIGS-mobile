import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/drdd_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/drdd_provider.dart';
import '../widgets/drdd_stat_card.dart';

class DrddOverviewScreen extends ConsumerWidget {
  const DrddOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(drddDashboardProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return RefreshIndicator(
      color: SigsTheme.primaryOrange,
      onRefresh: () =>
          ref.read(drddDashboardProvider.notifier).fetchDashboard(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _WelcomeCard(
            fullName: user?.fullName ?? '',
            group: user?.group,
            territoire: dashState.territoire,
            isLoading: dashState.loading,
          ),
          const SizedBox(height: 24),

          Text(
            'Statistiques',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: SigsTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),

          _StatsGrid(
            stats: dashState.stats,
            isDR: dashState.isDR,
            isLoading: dashState.loading,
          ),
          const SizedBox(height: 28),

          _ActivitesRecentesSection(
            activites: dashState.activitesRecentes,
            isLoading: dashState.loading,
          ),
          const SizedBox(height: 24),

          if (dashState.territoire != null)
            _TerritoireCard(territoire: dashState.territoire!),

          if (dashState.error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: dashState.error!),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Welcome card with gradient
// ---------------------------------------------------------------------------
class _WelcomeCard extends StatelessWidget {
  final String fullName;
  final String? group;
  final DrddTerritoire? territoire;
  final bool isLoading;

  const _WelcomeCard({
    required this.fullName,
    this.group,
    this.territoire,
    this.isLoading = false,
  });

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2D5A8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  _initials(fullName),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour,',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      fullName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (territoire != null)
                _RoleChip(
                  label: territoire!.roleLabel,
                  color: territoire!.isDR
                      ? SigsTheme.infoCyan
                      : SigsTheme.warningAmber,
                ),
              if (territoire != null) const SizedBox(width: 8),
              if (group != null)
                _RoleChip(label: group!, color: Colors.white),
            ],
          ),
          if (territoire != null && territoire!.nom.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              territoire!.nom,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats grid
// ---------------------------------------------------------------------------
class _StatsGrid extends StatelessWidget {
  final DrddStats? stats;
  final bool isDR;
  final bool isLoading;

  const _StatsGrid({
    this.stats,
    this.isDR = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <_StatDef>[];

    if (isDR) {
      cards.add(_StatDef(
        label: 'Départements',
        value: stats?.departements ?? 0,
        icon: Icons.account_tree_rounded,
        iconColor: const Color(0xFF7C3AED),
        iconBgColor: const Color(0xFFF3E8FF),
      ));
    }
    cards.addAll([
      _StatDef(
        label: 'Localités',
        value: stats?.localites ?? 0,
        icon: Icons.location_on_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBgColor: const Color(0xFFDBEAFE),
      ),
      _StatDef(
        label: 'Infrastructures',
        value: stats?.infrastructures ?? 0,
        icon: Icons.stadium_rounded,
        iconColor: const Color(0xFF16A34A),
        iconBgColor: const Color(0xFFDCFCE7),
      ),
      _StatDef(
        label: 'Associations',
        value: stats?.associations ?? 0,
        icon: Icons.groups_rounded,
        iconColor: const Color(0xFFEA580C),
        iconBgColor: const Color(0xFFFFEDD5),
      ),
      _StatDef(
        label: 'Événements',
        value: stats?.evenements ?? 0,
        icon: Icons.event_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBgColor: const Color(0xFFFEE2E2),
      ),
    ]);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final c = cards[index];
        return DrddStatCard(
          label: c.label,
          value: c.value,
          icon: c.icon,
          iconColor: c.iconColor,
          iconBgColor: c.iconBgColor,
          isLoading: isLoading,
        );
      },
    );
  }
}

class _StatDef {
  final String label;
  final int value;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _StatDef({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

// ---------------------------------------------------------------------------
// Activites recentes section (feed mixte)
// ---------------------------------------------------------------------------
class _ActivitesRecentesSection extends StatelessWidget {
  final List<DrddActiviteRecente> activites;
  final bool isLoading;

  const _ActivitesRecentesSection({
    required this.activites,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: SigsTheme.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Activités récentes',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SigsTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          if (isLoading)
            ...List.generate(
              4,
              (i) => _ShimmerRow(index: i),
            )
          else if (activites.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 36,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune activité récente',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activites.map((a) => _ActiviteTile(activite: a)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ActiviteTile extends StatelessWidget {
  final DrddActiviteRecente activite;

  const _ActiviteTile({required this.activite});

  static const _typeConfig = <String, ({IconData icon, Color color, Color bg})>{
    'departement': (
      icon: Icons.account_tree_rounded,
      color: Color(0xFF7C3AED),
      bg: Color(0xFFF3E8FF),
    ),
    'infrastructure': (
      icon: Icons.stadium_rounded,
      color: Color(0xFF16A34A),
      bg: Color(0xFFDCFCE7),
    ),
    'association': (
      icon: Icons.groups_rounded,
      color: Color(0xFFEA580C),
      bg: Color(0xFFFFEDD5),
    ),
    'evenement': (
      icon: Icons.event_rounded,
      color: Color(0xFFDC2626),
      bg: Color(0xFFFEE2E2),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfig[activite.type] ??
        (
          icon: Icons.circle,
          color: Colors.grey,
          bg: Colors.grey.shade100,
        );

    final dateFormatted = activite.date != null
        ? DateFormat('d MMM yyyy', 'fr_FR').format(activite.date!)
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cfg.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(cfg.icon, color: cfg.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activite.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SigsTheme.primaryBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _TypeChip(
                      label: activite.typeLabel,
                      color: cfg.color,
                      bgColor: cfg.bg,
                    ),
                    if (activite.localite != null &&
                        activite.localite!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          activite.localite!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (activite.discipline != null &&
                        activite.discipline!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          activite.discipline!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (dateFormatted.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              dateFormatted,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _TypeChip({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ShimmerRow extends StatefulWidget {
  final int index;
  const _ShimmerRow({required this.index});

  @override
  State<_ShimmerRow> createState() => _ShimmerRowState();
}

class _ShimmerRowState extends State<_ShimmerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.25, end: 0.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        final color = Colors.grey.shade300.withValues(alpha: _opacity.value);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 110 + widget.index * 18.0,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 70,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Territoire card
// ---------------------------------------------------------------------------
class _TerritoireCard extends StatelessWidget {
  final DrddTerritoire territoire;

  const _TerritoireCard({required this.territoire});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: SigsTheme.primaryOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Territoire',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: SigsTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Rôle',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: territoire.isDR
                    ? SigsTheme.infoCyan.withValues(alpha: 0.12)
                    : SigsTheme.warningAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                territoire.roleLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: territoire.isDR
                      ? SigsTheme.infoCyan
                      : SigsTheme.warningAmber,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Entité',
            child: Text(
              territoire.nom,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SigsTheme.primaryBlue,
              ),
            ),
          ),
          if (territoire.code.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Code',
              child: Text(
                territoire.code,
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _InfoRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
        ),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error banner
// ---------------------------------------------------------------------------
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SigsTheme.dangerRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SigsTheme.dangerRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: SigsTheme.dangerRed,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: SigsTheme.dangerRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
