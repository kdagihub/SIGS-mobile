import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../models/infrastructure_models.dart';
import '../../../providers/infrastructure_provider.dart';

class InfrastructuresTab extends ConsumerStatefulWidget {
  const InfrastructuresTab({super.key});

  @override
  ConsumerState<InfrastructuresTab> createState() => _InfrastructuresTabState();
}

class _InfrastructuresTabState extends ConsumerState<InfrastructuresTab>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = ref.read(infrastructuresProvider.notifier);
      Future.wait([n.loadStats(), n.loadFormOptions(), n.load()]);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    ref.read(infrastructuresProvider.notifier).load(search: val);
  }

  void _showCreateForm() {
    _showInfrastructureForm(context, ref, null);
  }

  void _showEditForm(Infrastructure infra) {
    _showInfrastructureForm(context, ref, infra);
  }

  void _showDetail(Infrastructure infra) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _InfrastructureDetailSheet(infra: infra),
    );
  }

  Future<void> _confirmDelete(Infrastructure infra) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Supprimer l\'infrastructure « ${infra.libelleIs} » ?\nCette action est irréversible.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: Colors.grey)),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    HapticFeedback.mediumImpact();
    final err =
        await ref.read(infrastructuresProvider.notifier).delete(infra.code);
    if (!mounted) return;
    _showSnack(err ?? 'Supprimé avec succès', err != null);
  }

  void _showSnack(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade600 : SigsTheme.successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showFilterEtat() async {
    final items = [
      const _PickItem(code: 'Bon', label: 'Bon'),
      const _PickItem(code: "Hors d'usage", label: "Hors d'usage"),
      const _PickItem(code: 'En réhabilitation', label: 'En réhabilitation'),
    ];
    final picked = await _pickFromList(
      context,
      title: 'Filtrer par état',
      items: items,
      selected: ref.read(infrastructuresProvider).filterEtat,
    );
    if (picked != null) {
      ref
          .read(infrastructuresProvider.notifier)
          .load(page: 1, filterEtat: picked);
    }
  }

  void _showFilterLocalite() async {
    var opts = ref.read(infrastructuresProvider).formOptions;
    if (opts == null) {
      await ref.read(infrastructuresProvider.notifier).loadFormOptions();
      opts = ref.read(infrastructuresProvider).formOptions;
    }
    if (opts == null || opts.localites.isEmpty) return;
    final items = opts.localites
        .map((l) => _PickItem(
              code: l['code'] as String,
              label: l['libelle_localite'] as String,
            ))
        .toList();
    if (!mounted) return;
    final picked = await _pickFromList(
      context,
      title: 'Filtrer par localité',
      items: items,
      selected: ref.read(infrastructuresProvider).filterLocalite,
    );
    if (picked != null) {
      ref
          .read(infrastructuresProvider.notifier)
          .load(page: 1, filterLocalite: picked);
    }
  }

  void _showFilterType() async {
    var opts = ref.read(infrastructuresProvider).formOptions;
    if (opts == null) {
      await ref.read(infrastructuresProvider.notifier).loadFormOptions();
      opts = ref.read(infrastructuresProvider).formOptions;
    }
    if (opts == null || opts.typesInfrastructure.isEmpty) return;
    final items = opts.typesInfrastructure
        .map((t) => _PickItem(
              code: t['code'] as String,
              label: t['libelleType_Infrast'] as String,
            ))
        .toList();
    if (!mounted) return;
    final picked = await _pickFromList(
      context,
      title: 'Filtrer par type',
      items: items,
      selected: ref.read(infrastructuresProvider).filterType,
    );
    if (picked != null) {
      ref
          .read(infrastructuresProvider.notifier)
          .load(page: 1, filterType: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final st = ref.watch(infrastructuresProvider);

    return RefreshIndicator(
      color: SigsTheme.primaryOrange,
      onRefresh: () async {
        final n = ref.read(infrastructuresProvider.notifier);
        await Future.wait([n.loadStats(), n.load()]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Header ──
          Row(
            children: [
              Expanded(
                child: Text(
                  'Infrastructures',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: SigsTheme.primaryBlue,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => ref
                    .read(infrastructuresProvider.notifier)
                    .toggleSelectionMode(),
                icon: Icon(
                  st.selectionMode
                      ? Icons.close_rounded
                      : Icons.checklist_rounded,
                  color: st.selectionMode
                      ? SigsTheme.dangerRed
                      : SigsTheme.primaryBlue,
                  size: 22,
                ),
                tooltip: st.selectionMode
                    ? 'Quitter la sélection'
                    : 'Sélection multiple',
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 36,
                child: FilledButton.icon(
                  onPressed: _showCreateForm,
                  icon: const Icon(Icons.add, size: 18),
                  label:
                      Text('Ajouter', style: GoogleFonts.inter(fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: SigsTheme.primaryOrange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Stats ──
          _InfraStatsRow(stats: st.stats, loading: st.statsLoading),
          const SizedBox(height: 20),

          // ── Search ──
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Rechercher une infrastructure…',
              hintStyle: GoogleFonts.inter(
                  color: Colors.grey.shade400, fontSize: 14),
              prefixIcon:
                  Icon(Icons.search, color: Colors.grey.shade400, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                borderSide: const BorderSide(
                    color: SigsTheme.primaryOrange, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Filters ──
          _FilterChipsRow(
            filterEtat: st.filterEtat,
            filterLocalite: st.filterLocalite,
            filterType: st.filterType,
            formOptions: st.formOptions,
            onTapEtat: _showFilterEtat,
            onTapLocalite: _showFilterLocalite,
            onTapType: _showFilterType,
            onClearAll: () =>
                ref.read(infrastructuresProvider.notifier).clearFilters(),
          ),
          const SizedBox(height: 12),

          // ── Barre de sélection ──
          if (st.selectionMode)
            _InfraSelectionBar(
              state: st,
              ref: ref,
              parentContext: context,
            ),

          // ── Liste ──
          if (st.loading && st.records.isEmpty)
            _ListShimmer()
          else if (st.records.isEmpty)
            _EmptyState(message: st.error ?? 'Aucune infrastructure trouvée.')
          else
            ...st.records.map((infra) => _InfrastructureCard(
                  infra: infra,
                  selectionMode: st.selectionMode,
                  isSelected: st.selectedCodes.contains(infra.code),
                  onToggleSelect: () => ref
                      .read(infrastructuresProvider.notifier)
                      .toggleSelect(infra.code),
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    final n = ref.read(infrastructuresProvider.notifier);
                    if (!st.selectionMode) n.toggleSelectionMode();
                    n.toggleSelect(infra.code);
                  },
                  onTap: () => _showDetail(infra),
                  onEdit: () => _showEditForm(infra),
                  onDelete: () => _confirmDelete(infra),
                )),

          if (st.totalRecords > 25) ...[
            const SizedBox(height: 12),
            _PaginationRow(
              page: st.page,
              total: st.totalRecords,
              onPrev: st.page > 1
                  ? () => ref
                      .read(infrastructuresProvider.notifier)
                      .load(page: st.page - 1)
                  : null,
              onNext: st.page * 25 < st.totalRecords
                  ? () => ref
                      .read(infrastructuresProvider.notifier)
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
// Stats row
// ═══════════════════════════════════════════════════════════════

class _InfraStatsRow extends StatelessWidget {
  final InfrastructureStats stats;
  final bool loading;
  const _InfraStatsRow({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MS('Total', stats.total, Icons.stadium_rounded,
          const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
      _MS('Bon état', stats.bon, Icons.check_circle_rounded,
          const Color(0xFF059669), const Color(0xFFD1FAE5)),
      _MS("Hors d'usage", stats.horsUsage, Icons.warning_rounded,
          const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
      _MS('Places', stats.totalPlaces, Icons.event_seat_rounded,
          const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children:
          items.map((m) => _MiniCard(stat: m, loading: loading)).toList(),
    );
  }
}

class _MS {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _MS(this.label, this.value, this.icon, this.color, this.bg);
}

class _MiniCard extends StatelessWidget {
  final _MS stat;
  final bool loading;
  const _MiniCard({required this.stat, required this.loading});

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
          Expanded(
            child: Column(
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
                      fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Filter chips
// ═══════════════════════════════════════════════════════════════

class _FilterChipsRow extends StatelessWidget {
  final String? filterEtat;
  final String? filterLocalite;
  final String? filterType;
  final InfrastructureFormOptions? formOptions;
  final VoidCallback onTapEtat;
  final VoidCallback onTapLocalite;
  final VoidCallback onTapType;
  final VoidCallback onClearAll;

  const _FilterChipsRow({
    this.filterEtat,
    this.filterLocalite,
    this.filterType,
    this.formOptions,
    required this.onTapEtat,
    required this.onTapLocalite,
    required this.onTapType,
    required this.onClearAll,
  });

  String _localiteLabel(String code) {
    final match =
        formOptions?.localites.where((l) => l['code'] == code);
    if (match != null && match.isNotEmpty) {
      return match.first['libelle_localite'] as String;
    }
    return code;
  }

  String _typeLabel(String code) {
    final match =
        formOptions?.typesInfrastructure.where((t) => t['code'] == code);
    if (match != null && match.isNotEmpty) {
      return match.first['libelleType_Infrast'] as String;
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        filterEtat != null || filterLocalite != null || filterType != null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: filterEtat ?? 'État',
            active: filterEtat != null,
            onTap: onTapEtat,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filterLocalite != null
                ? _localiteLabel(filterLocalite!)
                : 'Localité',
            active: filterLocalite != null,
            onTap: onTapLocalite,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filterType != null ? _typeLabel(filterType!) : 'Type',
            active: filterType != null,
            onTap: onTapType,
          ),
          if (hasFilters) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClearAll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: SigsTheme.dangerRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 14, color: SigsTheme.dangerRed),
                    const SizedBox(width: 4),
                    Text(
                      'Réinitialiser',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: SigsTheme.dangerRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? SigsTheme.primaryOrange.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? SigsTheme.primaryOrange : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? SigsTheme.primaryOrange : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: active ? SigsTheme.primaryOrange : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Infrastructure card
// ═══════════════════════════════════════════════════════════════

class _InfrastructureCard extends StatelessWidget {
  final Infrastructure infra;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InfrastructureCard({
    required this.infra,
    this.selectionMode = false,
    this.isSelected = false,
    required this.onToggleSelect,
    required this.onLongPress,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? SigsTheme.primaryOrange.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? SigsTheme.primaryOrange
              : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: selectionMode ? onToggleSelect : onTap,
          onLongPress: selectionMode ? null : onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (selectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (_) => onToggleSelect(),
                            activeColor: SigsTheme.primaryOrange,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.stadium_rounded,
                          color: Color(0xFF16A34A), size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            infra.libelleIs,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: SigsTheme.primaryBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            infra.typeInfrastructureNom.isNotEmpty
                                ? infra.typeInfrastructureNom
                                : 'Type non renseigné',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (infra.etatInfrastructure != null)
                      _EtatBadge(etat: infra.etatInfrastructure!),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        infra.localiteNom.isNotEmpty
                            ? infra.localiteNom
                            : '—',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (infra.nbPlacesIs > 0) ...[
                      Icon(Icons.event_seat_rounded,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${infra.nbPlacesIs} places',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    if (!selectionMode) ...[
                      const SizedBox(width: 8),
                      _ActionBtn(
                        icon: Icons.visibility_outlined,
                        color: Colors.grey.shade600,
                        onTap: onTap,
                      ),
                      const SizedBox(width: 4),
                      _ActionBtn(
                        icon: Icons.edit_outlined,
                        color: SigsTheme.primaryBlue,
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 4),
                      _ActionBtn(
                        icon: Icons.delete_outline,
                        color: Colors.red.shade600,
                        onTap: onDelete,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EtatBadge extends StatelessWidget {
  final String etat;
  const _EtatBadge({required this.etat});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (etat) {
      case 'Bon':
        color = const Color(0xFF059669);
        bg = const Color(0xFFD1FAE5);
      case "Hors d'usage":
        color = const Color(0xFFDC2626);
        bg = const Color(0xFFFEE2E2);
      case 'En réhabilitation':
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFEF3C7);
      default:
        color = Colors.grey.shade600;
        bg = Colors.grey.shade100;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        etat,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.08),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Selection bar (bulk actions)
// ═══════════════════════════════════════════════════════════════

class _InfraSelectionBar extends StatelessWidget {
  final InfrastructuresState state;
  final WidgetRef ref;
  final BuildContext parentContext;
  const _InfraSelectionBar({
    required this.state,
    required this.ref,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final count = state.selectedCodes.length;
    final allSelected = state.records.isNotEmpty &&
        state.selectedCodes.length == state.records.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SigsTheme.primaryBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: allSelected,
                  onChanged: (_) {
                    final n = ref.read(infrastructuresProvider.notifier);
                    allSelected ? n.deselectAll() : n.selectAll();
                  },
                  activeColor: SigsTheme.primaryOrange,
                  side: const BorderSide(color: Colors.white54),
                ),
                Expanded(
                  child: Text(
                    count == 0
                        ? 'Cochez les infrastructures'
                        : '$count sélectionné${count > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (count > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: SigsTheme.dangerRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _doBulkDelete(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: SigsTheme.dangerRed, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Supprimer ($count)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SigsTheme.dangerRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _doBulkDelete(BuildContext ctx) async {
    final count = state.selectedCodes.length;
    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (c) => AlertDialog(
        title: const Text('Suppression en masse'),
        content: Text(
            'Voulez-vous supprimer $count infrastructure(s) ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style:
                FilledButton.styleFrom(backgroundColor: SigsTheme.dangerRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !parentContext.mounted) return;
    HapticFeedback.heavyImpact();
    final err =
        await ref.read(infrastructuresProvider.notifier).bulkDelete();
    if (!parentContext.mounted) return;
    ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(
      content: Text(err ?? '$count infrastructure(s) supprimée(s)'),
      backgroundColor:
          err == null ? SigsTheme.successGreen : Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ═══════════════════════════════════════════════════════════════
// Detail bottom sheet
// ═══════════════════════════════════════════════════════════════

class _InfrastructureDetailSheet extends StatelessWidget {
  final Infrastructure infra;
  const _InfrastructureDetailSheet({required this.infra});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Détail de l\'infrastructure',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SigsTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade200),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (infra.photoUrl != null &&
                      infra.photoUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl:
                            AppConstants.toAbsoluteUrl(infra.photoUrl!) ??
                                '',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 180,
                          color: Colors.grey.shade100,
                          child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 180,
                          color: Colors.grey.shade100,
                          child: Icon(Icons.broken_image_rounded,
                              size: 48, color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _SectionTitle('Informations générales'),
                  const SizedBox(height: 8),
                  _DetailRow('Code', infra.code, mono: true),
                  _DetailRow('Libellé', infra.libelleIs),
                  _DetailRow(
                    'Type',
                    infra.typeInfrastructureNom.isNotEmpty
                        ? infra.typeInfrastructureNom
                        : '—',
                  ),
                  if (infra.etatInfrastructure != null)
                    _DetailRowWidget(
                      'État',
                      _EtatBadge(etat: infra.etatInfrastructure!),
                    ),
                  _DetailRow('Nombre de places', '${infra.nbPlacesIs}'),
                  _DetailRow(
                    'Socio-éducatif',
                    infra.estSocioEducatif ? 'Oui' : 'Non',
                  ),

                  const SizedBox(height: 16),
                  _SectionTitle('Localisation'),
                  const SizedBox(height: 8),
                  _DetailRow(
                    'Localité',
                    infra.localiteNom.isNotEmpty ? infra.localiteNom : '—',
                  ),
                  _DetailRow(
                    'Coordonnées GPS',
                    infra.gpsIs ?? 'Non renseigné',
                    mono: infra.gpsIs != null,
                  ),

                  if (infra.dateCreationIs != null ||
                      infra.dateInaugurationIs != null ||
                      infra.dureeVieIs != null) ...[
                    const SizedBox(height: 16),
                    _SectionTitle('Historique'),
                    const SizedBox(height: 8),
                    if (infra.dateCreationIs != null)
                      _DetailRow(
                        'Date de création',
                        _formatDateDisplay(infra.dateCreationIs!),
                      ),
                    if (infra.dateInaugurationIs != null)
                      _DetailRow(
                        'Date d\'inauguration',
                        _formatDateDisplay(infra.dateInaugurationIs!),
                      ),
                    if (infra.dureeVieIs != null)
                      _DetailRow(
                          'Durée de vie', '${infra.dureeVieIs} ans'),
                  ],

                  if ((infra.structureGestion != null &&
                          infra.structureGestion!.isNotEmpty) ||
                      (infra.contactStructureGestion != null &&
                          infra.contactStructureGestion!.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    _SectionTitle('Gestion'),
                    const SizedBox(height: 8),
                    if (infra.structureGestion != null &&
                        infra.structureGestion!.isNotEmpty)
                      _DetailRow(
                          'Structure de gestion', infra.structureGestion!),
                    if (infra.contactStructureGestion != null &&
                        infra.contactStructureGestion!.isNotEmpty)
                      _DetailRow(
                          'Contact', infra.contactStructureGestion!),
                  ],

                  if (infra.disciplinesNoms.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionTitle('Disciplines pratiquées'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: infra.disciplinesNoms
                          .map((d) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  d,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateDisplay(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: SigsTheme.primaryOrange,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _DetailRow(this.label, this.value, {this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: (mono ? GoogleFonts.robotoMono : GoogleFonts.inter)(
              fontSize: 14,
              color: SigsTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRowWidget extends StatelessWidget {
  final String label;
  final Widget child;
  const _DetailRowWidget(this.label, this.child);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Pagination, shimmer, empty
// ═══════════════════════════════════════════════════════════════

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
            iconSize: 20),
        Text(
          'Page $page / $totalPages',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
        ),
        IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            iconSize: 20),
      ],
    );
  }
}

class _ListShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 94,
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
          Icon(Icons.stadium_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style:
                GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Picker helper
// ═══════════════════════════════════════════════════════════════

class _PickItem {
  final String code;
  final String label;
  const _PickItem({required this.code, required this.label});
}

Future<String?> _pickFromList(
  BuildContext context, {
  required String title,
  required List<_PickItem> items,
  String? selected,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SigsTheme.primaryBlue,
              ),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final isSel = item.code == selected;
                return ListTile(
                  title: Text(
                    item.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                      color: isSel
                          ? SigsTheme.primaryOrange
                          : SigsTheme.primaryBlue,
                    ),
                  ),
                  trailing: isSel
                      ? const Icon(Icons.check_circle,
                          color: SigsTheme.primaryOrange, size: 20)
                      : null,
                  onTap: () => Navigator.pop(ctx, item.code),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// Multi-select picker for disciplines
// ═══════════════════════════════════════════════════════════════

Future<List<String>?> _pickMultiFromList(
  BuildContext context, {
  required String title,
  required List<_PickItem> items,
  required List<String> selected,
}) async {
  final result = List<String>.from(selected);

  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: SigsTheme.primaryBlue,
                      ),
                    ),
                  ),
                  Text(
                    '${result.length} sélectionnée(s)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final checked = result.contains(item.code);
                  return CheckboxListTile(
                    value: checked,
                    activeColor: SigsTheme.primaryOrange,
                    title: Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: SigsTheme.primaryBlue,
                      ),
                    ),
                    onChanged: (val) {
                      setSheetState(() {
                        if (val == true) {
                          result.add(item.code);
                        } else {
                          result.remove(item.code);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, result),
                  style: FilledButton.styleFrom(
                    backgroundColor: SigsTheme.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Valider',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// Create / Edit form bottom sheet
// ═══════════════════════════════════════════════════════════════

void _showInfrastructureForm(
    BuildContext context, WidgetRef ref, Infrastructure? existing) async {
  final isEdit = existing != null;

  var formOpts = ref.read(infrastructuresProvider).formOptions;
  if (formOpts == null) {
    await ref.read(infrastructuresProvider.notifier).loadFormOptions();
    formOpts = ref.read(infrastructuresProvider).formOptions;
  }

  final libelleCtrl =
      TextEditingController(text: existing?.libelleIs ?? '');
  final nbPlacesCtrl = TextEditingController(
      text: existing != null ? '${existing.nbPlacesIs}' : '');
  final gpsCtrl = TextEditingController(text: existing?.gpsIs ?? '');
  final dureeVieCtrl = TextEditingController(
      text: existing?.dureeVieIs != null ? '${existing!.dureeVieIs}' : '');
  final structGestionCtrl =
      TextEditingController(text: existing?.structureGestion ?? '');
  final contactGestionCtrl =
      TextEditingController(text: existing?.contactStructureGestion ?? '');

  String? selectedLocalite = existing?.localite;
  String? selectedType = existing?.typeInfrastructure;
  String? selectedEtat = existing?.etatInfrastructure;
  List<String> selectedDisciplines =
      List<String>.from(existing?.disciplinePratiquee ?? []);
  bool estSocioEducatif = existing?.estSocioEducatif ?? false;

  String? dateCreation = existing?.dateCreationIs;
  String? dateInaug = existing?.dateInaugurationIs;

  String? photoLocalPath;
  bool photoRemoved = false;

  bool saving = false;

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final opts = formOpts;

        Future<void> save() async {
          final libelle = libelleCtrl.text.trim();
          if (libelle.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Le nom est requis'),
              backgroundColor: Colors.red,
            ));
            return;
          }
          final nbPlaces = int.tryParse(nbPlacesCtrl.text.trim());
          if (nbPlaces == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Le nombre de places est requis'),
              backgroundColor: Colors.red,
            ));
            return;
          }

          setSheetState(() => saving = true);

          final data = <String, dynamic>{
            'libelle_is': libelle,
            'nb_places_is': nbPlaces,
            'est_socio_educatif': estSocioEducatif,
          };
          if (selectedLocalite != null) data['localite'] = selectedLocalite;
          if (selectedType != null) data['type_infrastructure'] = selectedType;
          if (selectedEtat != null) data['etat_infrastructure'] = selectedEtat;
          final gps = gpsCtrl.text.trim();
          if (gps.isNotEmpty) data['gps_is'] = gps;
          if (dateCreation != null) data['date_creation_is'] = dateCreation;
          if (dateInaug != null) data['date_inauguration_is'] = dateInaug;
          final dureeVie = int.tryParse(dureeVieCtrl.text.trim());
          if (dureeVie != null) data['duree_vie_is'] = dureeVie;
          final structGestion = structGestionCtrl.text.trim();
          if (structGestion.isNotEmpty) {
            data['structure_gestion'] = structGestion;
          }
          final contactGestion = contactGestionCtrl.text.trim();
          if (contactGestion.isNotEmpty) {
            data['contact_structure_gestion'] = contactGestion;
          }
          if (selectedDisciplines.isNotEmpty) {
            data['discipline_pratiquee'] = selectedDisciplines;
          }
          if (photoRemoved && photoLocalPath == null) {
            data['photo_is'] = '';
          }

          final notifier = ref.read(infrastructuresProvider.notifier);
          final err = isEdit
              ? await notifier.update(existing.code, data,
                  photoPath: photoLocalPath)
              : await notifier.create(data, photoPath: photoLocalPath);

          if (!ctx.mounted) return;
          setSheetState(() => saving = false);

          if (err == null) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(isEdit ? 'Modifié avec succès' : 'Créé avec succès'),
              backgroundColor: SigsTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(err),
              backgroundColor: Colors.red.shade600,
            ));
          }
        }

        String localiteLabel(String? code) {
          if (code == null) return 'Sélectionner';
          final locs = opts?.localites ?? [];
          final match = locs.where((l) => l['code'] == code);
          return match.isNotEmpty
              ? match.first['libelle_localite'] as String
              : code;
        }

        String typeLabel(String? code) {
          if (code == null) return 'Sélectionner';
          final types = opts?.typesInfrastructure ?? [];
          final match = types.where((t) => t['code'] == code);
          return match.isNotEmpty
              ? match.first['libelleType_Infrast'] as String
              : code;
        }

        String disciplinesLabel() {
          if (selectedDisciplines.isEmpty) return 'Aucune sélectionnée';
          return '${selectedDisciplines.length} discipline(s)';
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit
                          ? 'Modifier l\'infrastructure'
                          : 'Nouvelle Infrastructure',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SigsTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade200),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FormSectionTitle('Informations générales'),
                      const SizedBox(height: 8),
                      _FField(label: 'Libellé *', controller: libelleCtrl),
                      _DropdownField(
                        label: 'Localité *',
                        value: localiteLabel(selectedLocalite),
                        onTap: () async {
                          final locs = opts?.localites ?? [];
                          if (locs.isEmpty) return;
                          final picked = await _pickFromList(
                            ctx,
                            title: 'Localité',
                            items: locs
                                .map((l) => _PickItem(
                                      code: l['code'] as String,
                                      label:
                                          l['libelle_localite'] as String,
                                    ))
                                .toList(),
                            selected: selectedLocalite,
                          );
                          if (picked != null) {
                            setSheetState(() => selectedLocalite = picked);
                          }
                        },
                      ),
                      _DropdownField(
                        label: 'Type d\'infrastructure',
                        value: typeLabel(selectedType),
                        onTap: () async {
                          final types =
                              opts?.typesInfrastructure ?? [];
                          if (types.isEmpty) return;
                          final picked = await _pickFromList(
                            ctx,
                            title: 'Type d\'infrastructure',
                            items: types
                                .map((t) => _PickItem(
                                      code: t['code'] as String,
                                      label: t['libelleType_Infrast']
                                          as String,
                                    ))
                                .toList(),
                            selected: selectedType,
                          );
                          if (picked != null) {
                            setSheetState(() => selectedType = picked);
                          }
                        },
                      ),
                      _FField(
                        label: 'Nombre de places *',
                        controller: nbPlacesCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      _DropdownField(
                        label: 'État',
                        value: selectedEtat ?? 'Sélectionner',
                        onTap: () async {
                          final picked = await _pickFromList(
                            ctx,
                            title: 'État de l\'infrastructure',
                            items: const [
                              _PickItem(code: 'Bon', label: 'Bon'),
                              _PickItem(
                                  code: "Hors d'usage",
                                  label: "Hors d'usage"),
                              _PickItem(
                                  code: 'En réhabilitation',
                                  label: 'En réhabilitation'),
                            ],
                            selected: selectedEtat,
                          );
                          if (picked != null) {
                            setSheetState(() => selectedEtat = picked);
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Socio-éducatif',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Switch(
                              value: estSocioEducatif,
                              activeTrackColor: SigsTheme.primaryOrange,
                              onChanged: (val) =>
                                  setSheetState(() => estSocioEducatif = val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      _FormSectionTitle('Localisation'),
                      const SizedBox(height: 8),
                      _FField(
                        label: 'Coordonnées GPS',
                        controller: gpsCtrl,
                        hint: 'latitude,longitude',
                      ),

                      const SizedBox(height: 8),
                      _FormSectionTitle('Photo'),
                      const SizedBox(height: 8),
                      _PhotoPickerSection(
                        existingUrl: (isEdit &&
                                existing.photoUrl != null &&
                                !photoRemoved &&
                                photoLocalPath == null)
                            ? AppConstants.toAbsoluteUrl(
                                existing.photoUrl!)
                            : null,
                        localPath: photoLocalPath,
                        onPickGallery: () async {
                          final xf = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (xf != null) {
                            setSheetState(() {
                              photoLocalPath = xf.path;
                              photoRemoved = false;
                            });
                          }
                        },
                        onPickCamera: () async {
                          final xf = await ImagePicker()
                              .pickImage(source: ImageSource.camera);
                          if (xf != null) {
                            setSheetState(() {
                              photoLocalPath = xf.path;
                              photoRemoved = false;
                            });
                          }
                        },
                        onRemove: () {
                          setSheetState(() {
                            photoLocalPath = null;
                            photoRemoved = true;
                          });
                        },
                        hasPhoto: photoLocalPath != null ||
                            (isEdit &&
                                existing.photoUrl != null &&
                                !photoRemoved),
                      ),

                      const SizedBox(height: 8),
                      _FormSectionTitle('Historique'),
                      const SizedBox(height: 8),
                      _DatePickerField(
                        label: 'Date de création',
                        value: dateCreation,
                        onChanged: (val) =>
                            setSheetState(() => dateCreation = val),
                      ),
                      _DatePickerField(
                        label: 'Date d\'inauguration',
                        value: dateInaug,
                        onChanged: (val) =>
                            setSheetState(() => dateInaug = val),
                      ),
                      _FField(
                        label: 'Durée de vie (années)',
                        controller: dureeVieCtrl,
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 8),
                      _FormSectionTitle('Gestion'),
                      const SizedBox(height: 8),
                      _FField(
                        label: 'Structure de gestion',
                        controller: structGestionCtrl,
                      ),
                      _FField(
                        label: 'Contact gestion',
                        controller: contactGestionCtrl,
                      ),

                      const SizedBox(height: 8),
                      _FormSectionTitle('Disciplines pratiquées'),
                      const SizedBox(height: 8),
                      _DropdownField(
                        label: 'Disciplines',
                        value: disciplinesLabel(),
                        onTap: () async {
                          final discs = opts?.disciplines ?? [];
                          if (discs.isEmpty) return;
                          final picked = await _pickMultiFromList(
                            ctx,
                            title: 'Disciplines pratiquées',
                            items: discs
                                .map((d) => _PickItem(
                                      code: d['code'] as String,
                                      label: d['libelle_disc'] as String,
                                    ))
                                .toList(),
                            selected: selectedDisciplines,
                          );
                          if (picked != null) {
                            setSheetState(
                                () => selectedDisciplines = picked);
                          }
                        },
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: saving ? null : save,
                          style: FilledButton.styleFrom(
                            backgroundColor: SigsTheme.primaryOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Enregistrer',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _FormSectionTitle extends StatelessWidget {
  final String title;
  const _FormSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: SigsTheme.primaryOrange,
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DropdownField({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: SigsTheme.primaryBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down,
                      color: Colors.grey.shade400, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  const _FField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                  fontSize: 13, color: Colors.grey.shade400),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: SigsTheme.primaryOrange, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    String displayText;
    if (value != null) {
      try {
        final dt = DateTime.parse(value!);
        displayText = DateFormat('dd/MM/yyyy').format(dt);
      } catch (_) {
        displayText = value!;
      }
    } else {
      displayText = 'Sélectionner une date';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () async {
              DateTime? initial;
              if (value != null) {
                initial = DateTime.tryParse(value!);
              }
              final picked = await showDatePicker(
                context: context,
                initialDate: initial ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                locale: const Locale('fr'),
              );
              if (picked != null) {
                onChanged(DateFormat('yyyy-MM-dd').format(picked));
              }
            },
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: value != null
                            ? SigsTheme.primaryBlue
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today_rounded,
                      color: Colors.grey.shade400, size: 18),
                ],
              ),
            ),
          ),
          if (value != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onChanged(null),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Effacer',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoPickerSection extends StatelessWidget {
  final String? existingUrl;
  final String? localPath;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onRemove;
  final bool hasPhoto;

  const _PhotoPickerSection({
    this.existingUrl,
    this.localPath,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRemove,
    required this.hasPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (localPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(localPath!),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else if (existingUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: existingUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 160,
                  color: Colors.grey.shade100,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.grey.shade100,
                  child: Icon(Icons.broken_image_rounded,
                      size: 40, color: Colors.grey.shade400),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _PhotoActionButton(
                icon: Icons.photo_library_rounded,
                label: 'Galerie',
                onTap: onPickGallery,
              ),
              const SizedBox(width: 10),
              _PhotoActionButton(
                icon: Icons.camera_alt_rounded,
                label: 'Caméra',
                onTap: onPickCamera,
              ),
              if (hasPhoto) ...[
                const SizedBox(width: 10),
                _PhotoActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Retirer',
                  onTap: onRemove,
                  danger: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _PhotoActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? SigsTheme.dangerRed : SigsTheme.primaryBlue;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
                color: danger ? SigsTheme.dangerRed.withValues(alpha: 0.3) : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
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
