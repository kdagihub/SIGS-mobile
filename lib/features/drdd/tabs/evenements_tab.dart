import 'dart:async';
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
import '../../../models/evenement_models.dart';
import '../../../providers/evenement_provider.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  EVENEMENTS TAB
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class EvenementsTab extends ConsumerStatefulWidget {
  const EvenementsTab({super.key});

  @override
  ConsumerState<EvenementsTab> createState() => _EvenementsTabState();
}

class _EvenementsTabState extends ConsumerState<EvenementsTab>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = ref.read(evenementsProvider.notifier);
      Future.wait([n.loadStats(), n.loadFormOptions(), n.load()]);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(evenementsProvider.notifier).load(page: 1, search: q);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final st = ref.watch(evenementsProvider);

    return RefreshIndicator(
      color: SigsTheme.primaryOrange,
      onRefresh: () async {
        final n = ref.read(evenementsProvider.notifier);
        await Future.wait([n.loadStats(), n.load(page: st.page)]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // ── Header ──
          _Header(
            selectionMode: st.selectionMode,
            onAdd: () => _showEvenementForm(context, ref, null),
            onToggleSelection: () =>
                ref.read(evenementsProvider.notifier).toggleSelectionMode(),
          ),
          const SizedBox(height: 14),

          // ── Stats ──
          _EvtStatsRow(stats: st.stats, loading: st.statsLoading),
          const SizedBox(height: 14),

          // ── Search ──
          _SearchField(controller: _searchCtrl, onChanged: _onSearch),
          const SizedBox(height: 10),

          // ── Filters ──
          _FilterChipsRow(ref: ref, state: st),

          // ── Selection bar ──
          if (st.selectionMode) ...[
            const SizedBox(height: 8),
            _SelectionBar(ref: ref, state: st, context: context),
          ],
          const SizedBox(height: 10),

          // ── List ──
          if (st.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                  child: CircularProgressIndicator(
                      color: SigsTheme.primaryOrange)),
            )
          else if (st.error != null)
            _ErrorCard(message: st.error!)
          else if (st.records.isEmpty)
            _EmptyState()
          else
            ...st.records.map((evt) => _EvenementCard(
                  evt: evt,
                  selectionMode: st.selectionMode,
                  isSelected: st.selectedCodes.contains(evt.code),
                  onToggleSelect: () =>
                      ref.read(evenementsProvider.notifier).toggleSelect(evt.code),
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    final n = ref.read(evenementsProvider.notifier);
                    if (!st.selectionMode) n.toggleSelectionMode();
                    n.toggleSelect(evt.code);
                  },
                  onDetail: () => _showDetail(context, evt),
                  onEdit: () => _showEvenementForm(context, ref, evt),
                  onDelete: () => _confirmDelete(context, ref, evt),
                )),

          if (!st.loading && st.records.isNotEmpty)
            _PaginationRow(state: st, ref: ref),
        ],
      ),
    );
  }

  void _showDetail(BuildContext ctx, Evenement evt) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EvenementDetailSheet(evt: evt),
    );
  }

  void _confirmDelete(BuildContext ctx, WidgetRef ref, Evenement evt) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous supprimer l\'événement « ${evt.nom} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: SigsTheme.dangerRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !ctx.mounted) return;
    HapticFeedback.mediumImpact();
    final err = await ref.read(evenementsProvider.notifier).delete(evt.code);
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(err ?? 'Supprimé avec succès'),
      backgroundColor: err == null ? SigsTheme.successGreen : Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  HEADER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _Header extends StatelessWidget {
  final bool selectionMode;
  final VoidCallback onAdd;
  final VoidCallback onToggleSelection;
  const _Header({
    required this.selectionMode,
    required this.onAdd,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Événements Sportifs',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SigsTheme.primaryBlue,
            ),
          ),
        ),
        IconButton(
          onPressed: onToggleSelection,
          icon: Icon(
            selectionMode ? Icons.close_rounded : Icons.checklist_rounded,
            color: selectionMode ? SigsTheme.dangerRed : SigsTheme.primaryBlue,
            size: 22,
          ),
          tooltip: selectionMode ? 'Quitter la sélection' : 'Sélection multiple',
        ),
        const SizedBox(width: 4),
        SizedBox(
          height: 36,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text('Ajouter',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: SigsTheme.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  STATS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _EvtStatsRow extends StatelessWidget {
  final EvenementStats stats;
  final bool loading;
  const _EvtStatsRow({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 72,
        child: Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: SigsTheme.primaryOrange),
        ),
      );
    }
    return Row(
      children: [
        _MiniCard(
            label: 'Total', value: '${stats.total}', color: SigsTheme.primaryBlue),
        const SizedBox(width: 8),
        _MiniCard(
            label: 'Participants',
            value: _fmt(stats.totalParticipants),
            color: SigsTheme.primaryOrange),
        const SizedBox(width: 8),
        _MiniCard(
            label: 'Avec fédé.',
            value: '${stats.withFederation}',
            color: SigsTheme.successGreen),
        const SizedBox(width: 8),
        _MiniCard(
            label: 'Avec infra.',
            value: '${stats.withInfra}',
            color: SigsTheme.infoCyan),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  SEARCH
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Rechercher (nom, organisateur, type...)',
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  FILTER CHIPS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _FilterChipsRow extends StatelessWidget {
  final WidgetRef ref;
  final EvenementsState state;
  const _FilterChipsRow({required this.ref, required this.state});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _FilterChipBtn(
          label: state.filterType ?? 'Type',
          active: state.filterType != null,
          onTap: () => _showFilterType(context),
        ),
        _FilterChipBtn(
          label: state.filterDiscipline != null
              ? _findLabel(state.formOptions?.disciplines, state.filterDiscipline!, 'libelle_disc')
              : 'Discipline',
          active: state.filterDiscipline != null,
          onTap: () => _showFilterDiscipline(context),
        ),
        if (state.hasActiveFilters)
          ActionChip(
            avatar: const Icon(Icons.clear, size: 14),
            label: Text('Réinitialiser', style: GoogleFonts.inter(fontSize: 11)),
            onPressed: () => ref.read(evenementsProvider.notifier).clearFilters(),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  void _showFilterType(BuildContext context) async {
    var opts = ref.read(evenementsProvider).formOptions;
    if (opts == null) {
      await ref.read(evenementsProvider.notifier).loadFormOptions();
      opts = ref.read(evenementsProvider).formOptions;
    }
    if (opts == null || opts.typesEvenement.isEmpty) return;
    if (!context.mounted) return;
    final picked = await _pickFromList(
      context,
      title: 'Filtrer par type',
      items: opts.typesEvenement
          .map((t) => _PickItem(
                code: t['value'] as String? ?? '',
                label: t['label'] as String? ?? t['value'] as String? ?? '',
              ))
          .toList(),
      selected: state.filterType,
    );
    if (picked != null) {
      ref.read(evenementsProvider.notifier).load(page: 1, filterType: picked);
    }
  }

  void _showFilterDiscipline(BuildContext context) async {
    var opts = ref.read(evenementsProvider).formOptions;
    if (opts == null) {
      await ref.read(evenementsProvider.notifier).loadFormOptions();
      opts = ref.read(evenementsProvider).formOptions;
    }
    if (opts == null || opts.disciplines.isEmpty) return;
    if (!context.mounted) return;
    final picked = await _pickFromList(
      context,
      title: 'Filtrer par discipline',
      items: opts.disciplines
          .map((d) => _PickItem(
                code: d['code'] as String,
                label: d['libelle_disc'] as String? ?? d['code'] as String,
              ))
          .toList(),
      selected: state.filterDiscipline,
    );
    if (picked != null) {
      ref.read(evenementsProvider.notifier).load(page: 1, filterDiscipline: picked);
    }
  }

  String _findLabel(List<Map<String, dynamic>>? list, String code, String key) {
    if (list == null) return code;
    for (final item in list) {
      if (item['code'] == code) return item[key] as String? ?? code;
    }
    return code;
  }
}

class _FilterChipBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChipBtn({required this.label, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? SigsTheme.primaryOrange.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? SigsTheme.primaryOrange : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, size: 14,
                color: active ? SigsTheme.primaryOrange : Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? SigsTheme.primaryOrange : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  SELECTION BAR (identical to associations pattern)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SelectionBar extends StatelessWidget {
  final WidgetRef ref;
  final EvenementsState state;
  final BuildContext context;
  const _SelectionBar({
    required this.ref,
    required this.state,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final count = state.selectedCodes.length;
    final allSelected =
        state.records.isNotEmpty &&
        state.selectedCodes.length == state.records.length;

    return Container(
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
                  final n = ref.read(evenementsProvider.notifier);
                  allSelected ? n.deselectAll() : n.selectAll();
                },
                activeColor: SigsTheme.primaryOrange,
                side: const BorderSide(color: Colors.white54),
              ),
              Expanded(
                child: Text(
                  count == 0
                      ? 'Cochez les événements'
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
              child: Row(
                children: [
                  Expanded(
                    child: _BulkActionBtn(
                      icon: Icons.delete_outline_rounded,
                      label: 'Supprimer',
                      color: SigsTheme.dangerRed,
                      onTap: _doBulkDelete,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _doBulkDelete() async {
    final count = state.selectedCodes.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Suppression en masse'),
        content: Text(
            'Voulez-vous supprimer $count événement(s) ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: SigsTheme.dangerRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    HapticFeedback.heavyImpact();
    final result = await ref.read(evenementsProvider.notifier).bulkDelete();
    if (!context.mounted) return;
    final msg = result.failed == 0
        ? '${result.deleted} événement(s) supprimé(s)'
        : '${result.deleted} supprimé(s), ${result.failed} en erreur';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: result.failed == 0 ? SigsTheme.successGreen : Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

class _BulkActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BulkActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  EVENEMENT CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _EvenementCard extends StatelessWidget {
  final Evenement evt;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onLongPress;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EvenementCard({
    required this.evt,
    required this.selectionMode,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onLongPress,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = AppConstants.toAbsoluteUrl(evt.imageUrl);
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final dateStr = _formatDateShort(evt.dateHeureDebut);

    return GestureDetector(
      onTap: selectionMode ? onToggleSelect : onDetail,
      onLongPress: selectionMode ? null : onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? SigsTheme.primaryOrange.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? SigsTheme.primaryOrange : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header
            if (hasImage)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 140,
                        color: Colors.grey.shade100,
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 140,
                        color: Colors.grey.shade100,
                        child: Icon(Icons.image_not_supported,
                            color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  if (selectionMode)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: SizedBox(
                        width: 24, height: 24,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => onToggleSelect(),
                          activeColor: SigsTheme.primaryOrange,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectionMode && !hasImage)
                    Padding(
                      padding: const EdgeInsets.only(right: 10, top: 2),
                      child: SizedBox(
                        width: 22, height: 22,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => onToggleSelect(),
                          activeColor: SigsTheme.primaryOrange,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  if (!hasImage)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: SigsTheme.primaryOrange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_rounded,
                            color: SigsTheme.primaryOrange, size: 22),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                evt.nom,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: SigsTheme.primaryBlue,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!selectionMode)
                              PopupMenuButton<String>(
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                onSelected: (v) {
                                  if (v == 'edit') onEdit();
                                  if (v == 'delete') onDelete();
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(children: [
                                      Icon(Icons.edit_rounded,
                                          size: 18, color: Colors.grey.shade600),
                                      const SizedBox(width: 10),
                                      const Text('Modifier'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(children: [
                                      const Icon(Icons.delete_rounded,
                                          size: 18, color: SigsTheme.dangerRed),
                                      const SizedBox(width: 10),
                                      const Text('Supprimer',
                                          style: TextStyle(color: SigsTheme.dangerRed)),
                                    ]),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _TagChip(label: evt.typeEvenement, color: SigsTheme.primaryOrange),
                            if (evt.disciplineNom.isNotEmpty)
                              _TagChip(label: evt.disciplineNom, color: SigsTheme.infoCyan),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _IconText(Icons.calendar_today_rounded, dateStr),
                        if (evt.infrastructureNom.isNotEmpty)
                          _IconText(Icons.stadium_rounded, evt.infrastructureNom),
                        if (evt.organisateur != null && evt.organisateur!.isNotEmpty)
                          _IconText(Icons.person_rounded, evt.organisateur!),
                        if (evt.nombreParticipants != null)
                          _IconText(Icons.people_rounded, '${evt.nombreParticipants} participants'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateShort(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat("dd MMM yyyy 'à' HH:mm", 'fr_FR').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconText(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  DETAIL SHEET
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _EvenementDetailSheet extends StatelessWidget {
  final Evenement evt;
  const _EvenementDetailSheet({required this.evt});

  @override
  Widget build(BuildContext context) {
    final imageUrl = AppConstants.toAbsoluteUrl(evt.imageUrl);
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            if (hasImage) const SizedBox(height: 16),
            Text(
              evt.nom,
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800, color: SigsTheme.primaryBlue),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _TagChip(label: evt.typeEvenement, color: SigsTheme.primaryOrange),
                if (evt.disciplineNom.isNotEmpty)
                  _TagChip(label: evt.disciplineNom, color: SigsTheme.infoCyan),
              ],
            ),
            const SizedBox(height: 16),
            _detailSection('Dates', [
              _DRow('Début', _fmtDT(evt.dateHeureDebut)),
              _DRow('Fin', _fmtDT(evt.dateHeureFin)),
            ]),
            _detailSection('Organisation', [
              if (evt.organisateur != null) _DRow('Organisateur', evt.organisateur!),
              if (evt.infrastructureNom.isNotEmpty)
                _DRow('Infrastructure', evt.infrastructureNom),
              if (evt.federationNom.isNotEmpty)
                _DRow('Fédération', evt.federationNom),
              if (evt.nombreParticipants != null)
                _DRow('Participants', '${evt.nombreParticipants}'),
            ]),
            if (evt.budget != null ||
                (evt.billetterie != null && evt.billetterie!.isNotEmpty))
              _detailSection('Finances', [
                if (evt.budget != null)
                  _DRow('Budget', '${NumberFormat('#,###').format(evt.budget)} FCFA'),
                if (evt.billetterie != null && evt.billetterie!.isNotEmpty)
                  _DRow('Billetterie', evt.billetterie!),
              ]),
            if (evt.partenaires != null && evt.partenaires!.isNotEmpty)
              _detailSection('Partenaires', [_DRow('', evt.partenaires!)]),
            if (evt.documentAnnexeUrl != null && evt.documentAnnexeUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.attach_file_rounded, size: 18),
                  label: const Text('Document annexe'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SigsTheme.primaryBlue,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              evt.code,
              style: GoogleFonts.robotoMono(fontSize: 11, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(String title, List<_DRow> rows) {
    final filtered = rows.where((r) => r.value.isNotEmpty).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: SigsTheme.surfaceGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(title,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          ),
          const SizedBox(height: 8),
          ...filtered.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.label.isNotEmpty)
                      SizedBox(
                        width: 110,
                        child: Text(r.label,
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                      ),
                    if (r.label.isNotEmpty) const SizedBox(width: 8),
                    Expanded(
                      child: Text(r.value,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: SigsTheme.primaryBlue)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _fmtDT(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat("EEEE dd MMMM yyyy 'à' HH:mm", 'fr_FR').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

class _DRow {
  final String label;
  final String value;
  const _DRow(this.label, this.value);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  CREATE / EDIT FORM (same pattern as associations)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

void _showEvenementForm(
    BuildContext context, WidgetRef ref, Evenement? existing) async {
  final isEdit = existing != null;

  var formOpts = ref.read(evenementsProvider).formOptions;
  if (formOpts == null) {
    await ref.read(evenementsProvider.notifier).loadFormOptions();
    formOpts = ref.read(evenementsProvider).formOptions;
  }

  final nomCtrl = TextEditingController(text: existing?.nom ?? '');
  final organisateurCtrl = TextEditingController(text: existing?.organisateur ?? '');
  final participantsCtrl =
      TextEditingController(text: existing?.nombreParticipants?.toString() ?? '');
  final budgetCtrl = TextEditingController(text: existing?.budget?.toString() ?? '');
  final partenairesCtrl = TextEditingController(text: existing?.partenaires ?? '');
  final billetterieCtrl = TextEditingController(text: existing?.billetterie ?? '');

  String? selectedType = existing?.typeEvenement;
  String? selectedDiscipline = existing?.discipline;
  String? selectedInfra = existing?.infrastructureUtilisee;
  String? selectedFederation = existing?.federation;
  String? selectedAnnee = existing?.anneeSportive;
  DateTime? dateDebut;
  DateTime? dateFin;
  if (existing != null && existing.dateHeureDebut.isNotEmpty) {
    try { dateDebut = DateTime.parse(existing.dateHeureDebut); } catch (_) {}
  }
  if (existing != null && existing.dateHeureFin.isNotEmpty) {
    try { dateFin = DateTime.parse(existing.dateHeureFin); } catch (_) {}
  }

  String? imageLocalPath;
  bool imageRemoved = false;
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
          final nom = nomCtrl.text.trim();
          if (nom.isEmpty || selectedType == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Le nom et le type sont requis'),
              backgroundColor: Colors.red,
            ));
            return;
          }
          if (dateDebut == null || dateFin == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Les dates de début et de fin sont requises'),
              backgroundColor: Colors.red,
            ));
            return;
          }

          setSheetState(() => saving = true);

          final data = <String, dynamic>{
            'nom': nom,
            'type_evenement': selectedType,
            'date_heure_debut': dateDebut!.toIso8601String(),
            'date_heure_fin': dateFin!.toIso8601String(),
          };
          if (selectedDiscipline != null) data['discipline'] = selectedDiscipline;
          if (selectedInfra != null) data['infrastructure_utilisee'] = selectedInfra;
          if (selectedFederation != null) data['federation'] = selectedFederation;
          if (selectedAnnee != null) data['annee_sportive'] = selectedAnnee;
          _addIfNotEmpty(data, 'organisateur', organisateurCtrl.text);
          if (participantsCtrl.text.trim().isNotEmpty) {
            data['nombre_participants'] = int.tryParse(participantsCtrl.text.trim());
          }
          if (budgetCtrl.text.trim().isNotEmpty) {
            data['budget'] = double.tryParse(budgetCtrl.text.trim());
          }
          _addIfNotEmpty(data, 'partenaires', partenairesCtrl.text);
          _addIfNotEmpty(data, 'billetterie', billetterieCtrl.text);

          if (imageRemoved && imageLocalPath == null) data['image_evenement'] = '';

          final notifier = ref.read(evenementsProvider.notifier);
          final err = isEdit
              ? await notifier.update(existing.code, data, imagePath: imageLocalPath)
              : await notifier.create(data, imagePath: imageLocalPath);

          if (!ctx.mounted) return;
          setSheetState(() => saving = false);

          if (err == null) {
            Navigator.pop(ctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isEdit ? 'Modifié avec succès' : 'Créé avec succès'),
                backgroundColor: SigsTheme.successGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(err),
              backgroundColor: Colors.red.shade600,
            ));
          }
        }

        // Label helpers
        String typeLabel(String? val) {
          if (val == null) return 'Sélectionner';
          final m = (opts?.typesEvenement ?? []).where((t) => t['value'] == val);
          return m.isNotEmpty ? m.first['label'] as String : val;
        }

        String discLabel(String? code) {
          if (code == null) return 'Sélectionner';
          final m = (opts?.disciplines ?? []).where((d) => d['code'] == code);
          return m.isNotEmpty ? m.first['libelle_disc'] as String : code;
        }

        String infraLabel(String? code) {
          if (code == null) return 'Sélectionner';
          final m = (opts?.infrastructures ?? []).where((i) => i['code'] == code);
          return m.isNotEmpty ? m.first['libelle_is'] as String : code;
        }

        String fedLabel(String? code) {
          if (code == null) return 'Sélectionner';
          final m = (opts?.federations ?? []).where((f) => f['code'] == code);
          return m.isNotEmpty ? m.first['sigle_fed'] as String : code;
        }

        String anneeLabel(String? code) {
          if (code == null) return 'Sélectionner';
          final m = (opts?.anneesSportives ?? []).where((a) => a['code'] == code);
          return m.isNotEmpty ? m.first['libelle_annee'] as String : code;
        }

        String fmtDate(DateTime? dt) {
          if (dt == null) return 'Choisir';
          return DateFormat('dd/MM/yyyy HH:mm').format(dt);
        }

        Future<void> pickDateTime(bool isStart) async {
          final now = DateTime.now();
          final date = await showDatePicker(
            context: ctx,
            initialDate: (isStart ? dateDebut : dateFin) ?? now,
            firstDate: DateTime(2020),
            lastDate: DateTime(2040),
          );
          if (date == null || !ctx.mounted) return;
          final time = await showTimePicker(
            context: ctx,
            initialTime: TimeOfDay.fromDateTime(
                (isStart ? dateDebut : dateFin) ?? now),
          );
          if (time == null || !ctx.mounted) return;
          final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          setSheetState(() {
            if (isStart) {
              dateDebut = dt;
            } else {
              dateFin = dt;
            }
          });
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? 'Modifier l\'événement' : 'Nouvel Événement',
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
                      _FormSectionTitle('Identification'),
                      const SizedBox(height: 8),
                      _FField(label: 'Nom de l\'événement *', controller: nomCtrl),
                      _DropdownField(
                        label: 'Type d\'événement *',
                        value: typeLabel(selectedType),
                        onTap: () async {
                          final types = opts?.typesEvenement ?? [];
                          if (types.isEmpty) return;
                          final picked = await _pickFromList(
                            ctx,
                            title: 'Type d\'événement',
                            items: types
                                .map((t) => _PickItem(
                                      code: t['value'] as String? ?? '',
                                      label: t['label'] as String? ?? t['value'] as String? ?? '',
                                    ))
                                .toList(),
                            selected: selectedType,
                          );
                          if (picked != null) setSheetState(() => selectedType = picked);
                        },
                      ),
                      _DropdownField(
                        label: 'Discipline',
                        value: discLabel(selectedDiscipline),
                        onTap: () async {
                          final items = opts?.disciplines ?? [];
                          if (items.isEmpty) return;
                          final picked = await _pickFromList(
                            ctx,
                            title: 'Discipline',
                            items: items
                                .map((d) => _PickItem(
                                      code: d['code'] as String,
                                      label: d['libelle_disc'] as String? ?? '',
                                    ))
                                .toList(),
                            selected: selectedDiscipline,
                          );
                          if (picked != null) setSheetState(() => selectedDiscipline = picked);
                        },
                      ),

                      _FormSectionTitle('Dates'),
                      const SizedBox(height: 8),
                      _DateTimeField(
                        label: 'Date et heure de début *',
                        value: fmtDate(dateDebut),
                        onTap: () => pickDateTime(true),
                      ),
                      _DateTimeField(
                        label: 'Date et heure de fin *',
                        value: fmtDate(dateFin),
                        onTap: () => pickDateTime(false),
                      ),

                      _FormSectionTitle('Organisation'),
                      const SizedBox(height: 8),
                      _DropdownField(
                        label: 'Infrastructure',
                        value: infraLabel(selectedInfra),
                        onTap: () async {
                          final items = opts?.infrastructures ?? [];
                          if (items.isEmpty) return;
                          final picked = await _pickFromList(
                            ctx,
                            title: 'Infrastructure',
                            items: items
                                .map((i) => _PickItem(
                                      code: i['code'] as String,
                                      label: i['libelle_is'] as String? ?? '',
                                    ))
                                .toList(),
                            selected: selectedInfra,
                          );
                          if (picked != null) setSheetState(() => selectedInfra = picked);
                        },
                      ),
                      _FField(label: 'Organisateur', controller: organisateurCtrl),
                      _DropdownField(
                        label: 'Fédération',
                        value: fedLabel(selectedFederation),
                        onTap: () async {
                          final items = opts?.federations ?? [];
                          if (items.isEmpty) return;
                          final picked = await _pickFromList(
                            ctx,
                            title: 'Fédération',
                            items: items
                                .map((f) => _PickItem(
                                      code: f['code'] as String,
                                      label: f['sigle_fed'] as String? ?? '',
                                    ))
                                .toList(),
                            selected: selectedFederation,
                          );
                          if (picked != null) setSheetState(() => selectedFederation = picked);
                        },
                      ),
                      _DropdownField(
                        label: 'Année sportive',
                        value: anneeLabel(selectedAnnee),
                        onTap: () async {
                          final items = opts?.anneesSportives ?? [];
                          if (items.isEmpty) return;
                          final picked = await _pickFromList(
                            ctx,
                            title: 'Année sportive',
                            items: items
                                .map((a) => _PickItem(
                                      code: a['code'] as String,
                                      label: a['libelle_annee'] as String? ?? '',
                                    ))
                                .toList(),
                            selected: selectedAnnee,
                          );
                          if (picked != null) setSheetState(() => selectedAnnee = picked);
                        },
                      ),

                      _FormSectionTitle('Détails'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _FField(
                                label: 'Nb. participants',
                                controller: participantsCtrl,
                                keyboardType: TextInputType.number),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FField(
                                label: 'Budget (FCFA)',
                                controller: budgetCtrl,
                                keyboardType: TextInputType.number),
                          ),
                        ],
                      ),
                      _FField(
                          label: 'Partenaires',
                          controller: partenairesCtrl,
                          maxLines: 2),
                      _FField(
                          label: 'Billetterie',
                          controller: billetterieCtrl,
                          maxLines: 2),

                      // Image
                      _FormSectionTitle('Image'),
                      const SizedBox(height: 8),
                      _ImagePickerWidget(
                        existingUrl: existing?.imageUrl,
                        localPath: imageLocalPath,
                        removed: imageRemoved,
                        onPick: () async {
                          final picked = await ImagePicker()
                              .pickImage(source: ImageSource.gallery, maxWidth: 1200);
                          if (picked != null) {
                            setSheetState(() {
                              imageLocalPath = picked.path;
                              imageRemoved = false;
                            });
                          }
                        },
                        onRemove: () => setSheetState(() {
                          imageLocalPath = null;
                          imageRemoved = true;
                        }),
                      ),

                      const SizedBox(height: 20),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving ? null : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Text('Annuler',
                                  style: TextStyle(color: Colors.grey.shade600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: saving ? null : save,
                              child: saving
                                  ? const SizedBox(
                                      height: 18, width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Text(isEdit ? 'Modifier' : 'Créer'),
                            ),
                          ),
                        ],
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

void _addIfNotEmpty(Map<String, dynamic> data, String key, String text) {
  final v = text.trim();
  if (v.isNotEmpty) data[key] = v;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  REUSABLE FORM WIDGETS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _FormSectionTitle extends StatelessWidget {
  final String title;
  const _FormSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: SigsTheme.primaryOrange,
        ),
      ),
    );
  }
}

class _FField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const _FField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
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
                fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: label.replaceAll('*', '').trim(),
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
              isDense: true,
            ),
          ),
        ],
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
                fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                      style: GoogleFonts.inter(fontSize: 14, color: SigsTheme.primaryBlue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade400, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onTap,
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
                fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: value == 'Choisir'
                            ? Colors.grey.shade400
                            : SigsTheme.primaryBlue,
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
  }
}

class _ImagePickerWidget extends StatelessWidget {
  final String? existingUrl;
  final String? localPath;
  final bool removed;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImagePickerWidget({
    this.existingUrl,
    this.localPath,
    this.removed = false,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = localPath != null;
    final hasRemote = !removed && existingUrl != null && existingUrl!.isNotEmpty;
    final absUrl = AppConstants.toAbsoluteUrl(existingUrl);

    return Column(
      children: [
        if (hasLocal)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(localPath!),
                height: 120, width: double.infinity, fit: BoxFit.cover),
          )
        else if (hasRemote && absUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
                imageUrl: absUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.image_rounded, size: 16),
                label: Text(hasLocal || hasRemote ? 'Changer' : 'Ajouter',
                    style: GoogleFonts.inter(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SigsTheme.primaryOrange,
                  side: BorderSide(color: SigsTheme.primaryOrange.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            if (hasLocal || hasRemote) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: Text('Retirer', style: GoogleFonts.inter(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SigsTheme.dangerRed,
                    side: BorderSide(color: SigsTheme.dangerRed.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  PAGINATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _PaginationRow extends StatelessWidget {
  final EvenementsState state;
  final WidgetRef ref;
  const _PaginationRow({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (state.totalRecords <= 25) return const SizedBox.shrink();
    final totalPages = (state.totalRecords / 25).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: state.page > 1
                ? () => ref.read(evenementsProvider.notifier).load(page: state.page - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            color: SigsTheme.primaryBlue,
          ),
          Text('Page ${state.page} / $totalPages',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: SigsTheme.primaryBlue)),
          IconButton(
            onPressed: state.page < totalPages
                ? () => ref.read(evenementsProvider.notifier).load(page: state.page + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: SigsTheme.primaryBlue,
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  UTILITY
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SigsTheme.dangerRed.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: SigsTheme.dangerRed),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(fontSize: 13, color: SigsTheme.dangerRed)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Aucun événement trouvé.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

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
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700, color: SigsTheme.primaryBlue)),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final active = item.code == selected;
                return ListTile(
                  dense: true,
                  title: Text(
                    item.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? SigsTheme.primaryOrange : SigsTheme.primaryBlue,
                    ),
                  ),
                  trailing: active
                      ? const Icon(Icons.check, color: SigsTheme.primaryOrange, size: 20)
                      : null,
                  onTap: () => Navigator.pop(ctx, item.code),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
