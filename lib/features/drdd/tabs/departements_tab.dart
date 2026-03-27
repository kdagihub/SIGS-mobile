import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../../../models/territoire_models.dart';
import '../../../providers/territoire_provider.dart';

class DepartementsTab extends ConsumerStatefulWidget {
  const DepartementsTab({super.key});

  @override
  ConsumerState<DepartementsTab> createState() => _DepartementsTabState();
}

class _DepartementsTabState extends ConsumerState<DepartementsTab>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = ref.read(departementsProvider.notifier);
      n.loadStats();
      n.load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    ref.read(departementsProvider.notifier).load(search: val);
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final st = ref.watch(departementsProvider);

    return RefreshIndicator(
      color: SigsTheme.primaryOrange,
      onRefresh: () async {
        final n = ref.read(departementsProvider.notifier);
        await Future.wait([n.loadStats(), n.load()]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Header ──
          Text(
            'Directions Départementales',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: SigsTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),

          // ── Stats ──
          _StatsRow(stats: st.stats, loading: st.statsLoading),
          const SizedBox(height: 20),

          // ── Search ──
          _SearchField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onChanged: _onSearch,
          ),
          const SizedBox(height: 12),

          // ── Liste ──
          if (st.loading && st.records.isEmpty)
            const _ListShimmer()
          else if (st.records.isEmpty)
            _EmptyState(message: st.error ?? 'Aucune direction départementale.')
          else
            ...st.records.map((dd) => _DepartementCard(dd: dd)),

          if (st.totalRecords > 25) ...[
            const SizedBox(height: 12),
            _PaginationRow(
              page: st.page,
              total: st.totalRecords,
              onPrev: st.page > 1
                  ? () => ref
                      .read(departementsProvider.notifier)
                      .load(page: st.page - 1)
                  : null,
              onNext: st.page * 25 < st.totalRecords
                  ? () => ref
                      .read(departementsProvider.notifier)
                      .load(page: st.page + 1)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Reusable widgets
// ═══════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final DepartementStats stats;
  final bool loading;
  const _StatsRow({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MiniStat('Total', stats.total, Icons.account_tree_rounded,
          const Color(0xFF7C3AED), const Color(0xFFF3E8FF)),
      _MiniStat('Actives', stats.active, Icons.check_circle_rounded,
          const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
      _MiniStat('Inactives', stats.inactive, Icons.cancel_rounded,
          const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
      _MiniStat('GPS', stats.withGps, Icons.location_on_rounded,
          const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: items
          .map((m) => _MiniStatCard(stat: m, loading: loading))
          .toList(),
    );
  }
}

class _MiniStat {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _MiniStat(this.label, this.value, this.icon, this.color, this.bg);
}

class _MiniStatCard extends StatelessWidget {
  final _MiniStat stat;
  final bool loading;
  const _MiniStatCard({required this.stat, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: stat.bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(stat.icon, color: stat.color, size: 17),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              loading
                  ? Container(
                      width: 28,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : Text(
                      '${stat.value}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: SigsTheme.primaryBlue,
                      ),
                    ),
              Text(
                stat.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Rechercher…',
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SigsTheme.primaryOrange, width: 1.5),
        ),
      ),
    );
  }
}

class _DepartementCard extends StatelessWidget {
  final Departement dd;
  const _DepartementCard({required this.dd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dd.libelleDd,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SigsTheme.primaryBlue,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(isActive: dd.isActive),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dd.code,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          if (dd.responsableDd != null && dd.responsableDd!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dd.responsableDd!,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (dd.contactDd != null && dd.contactDd!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  dd.contactDd!,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (dd.coordonneesGps != null && dd.coordonneesGps!.isNotEmpty)
            _GpsTag(value: dd.coordonneesGps!)
          else
            Text(
              'GPS non renseigné',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade400,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Actif' : 'Inactif',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      ),
    );
  }
}

class _GpsTag extends StatelessWidget {
  final String value;
  const _GpsTag({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 11, color: Color(0xFF2563EB)),
          const SizedBox(width: 3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              value,
              style: GoogleFonts.robotoMono(fontSize: 10, color: const Color(0xFF2563EB)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationRow extends StatelessWidget {
  final int page;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  const _PaginationRow({
    required this.page,
    required this.total,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (total / 25).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          iconSize: 20,
        ),
        Text(
          'Page $page / $totalPages',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          iconSize: 20,
        ),
      ],
    );
  }
}

class _ListShimmer extends StatelessWidget {
  const _ListShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

