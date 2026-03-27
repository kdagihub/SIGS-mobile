import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../models/association_models.dart';
import '../../../providers/association_provider.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  ASSOCIATIONS TAB
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AssociationsTab extends ConsumerStatefulWidget {
  const AssociationsTab({super.key});

  @override
  ConsumerState<AssociationsTab> createState() => _AssociationsTabState();
}

class _AssociationsTabState extends ConsumerState<AssociationsTab>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = ref.read(associationsProvider.notifier);
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
      ref.read(associationsProvider.notifier).load(page: 1, search: q);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final st = ref.watch(associationsProvider);

    return RefreshIndicator(
      color: SigsTheme.primaryOrange,
      onRefresh: () async {
        final n = ref.read(associationsProvider.notifier);
        await Future.wait([n.loadStats(), n.load(page: st.page)]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          _Header(
            selectionMode: st.selectionMode,
            onAdd: () => _showAssociationForm(context, ref, null),
            onToggleSelection: () =>
                ref.read(associationsProvider.notifier).toggleSelectionMode(),
          ),
          const SizedBox(height: 14),
          _AssocStatsRow(stats: st.stats, loading: st.statsLoading),
          const SizedBox(height: 14),
          _SearchField(controller: _searchCtrl, onChanged: _onSearch),
          const SizedBox(height: 10),
          _FilterChipsRow(ref: ref, state: st),
          if (st.selectionMode) ...[
            const SizedBox(height: 8),
            _SelectionBar(ref: ref, state: st, context: context),
          ],
          const SizedBox(height: 10),
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
            ...st.records.map((a) => _AssociationCard(
                  assoc: a,
                  selectionMode: st.selectionMode,
                  isSelected: st.selectedCodes.contains(a.code),
                  onToggleSelect: () => ref
                      .read(associationsProvider.notifier)
                      .toggleSelect(a.code),
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    final n = ref.read(associationsProvider.notifier);
                    if (!st.selectionMode) n.toggleSelectionMode();
                    n.toggleSelect(a.code);
                  },
                  onDetail: () => _showDetail(context, ref, a.code),
                  onEdit: () => _showAssociationForm(context, ref, a),
                  onDelete: () => _confirmDelete(context, ref, a),
                )),
          if (!st.loading && st.records.isNotEmpty)
            _PaginationRow(state: st, ref: ref),
        ],
      ),
    );
  }

  void _showDetail(BuildContext ctx, WidgetRef ref, String code) async {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssociationDetailLoader(code: code),
    );
  }

  void _confirmDelete(
      BuildContext ctx, WidgetRef ref, Association assoc) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Voulez-vous supprimer l\'association « ${assoc.libelleAs} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style:
                FilledButton.styleFrom(backgroundColor: SigsTheme.dangerRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !ctx.mounted) return;
    final err =
        await ref.read(associationsProvider.notifier).delete(assoc.code);
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
            'Associations Sportives',
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
            selectionMode
                ? Icons.close_rounded
                : Icons.checklist_rounded,
            color:
                selectionMode ? SigsTheme.dangerRed : SigsTheme.primaryBlue,
            size: 22,
          ),
          tooltip:
              selectionMode ? 'Quitter la sélection' : 'Sélection multiple',
        ),
        const SizedBox(width: 4),
        SizedBox(
          height: 36,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Ajouter',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: SigsTheme.primaryOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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

class _AssocStatsRow extends StatelessWidget {
  final AssociationStats stats;
  final bool loading;
  const _AssocStatsRow({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
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
            label: 'Total',
            value: '${stats.total}',
            color: SigsTheme.primaryBlue),
        const SizedBox(width: 8),
        _MiniCard(
            label: 'Agréées',
            value: '${stats.agreees}',
            color: SigsTheme.successGreen),
        const SizedBox(width: 8),
        _MiniCard(
            label: 'Non agréées',
            value: '${stats.nonAgreees}',
            color: SigsTheme.dangerRed),
        const SizedBox(width: 8),
        _MiniCard(
            label: 'Avec fédé.',
            value: '${stats.withFederation}',
            color: SigsTheme.infoCyan),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniCard(
      {required this.label, required this.value, required this.color});

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
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
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
        hintText: 'Rechercher (sigle, nom, président…)',
        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.search, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
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
          borderSide:
              const BorderSide(color: SigsTheme.primaryOrange, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  FILTERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _FilterChipsRow extends StatelessWidget {
  final WidgetRef ref;
  final AssociationsState state;
  const _FilterChipsRow({required this.ref, required this.state});

  @override
  Widget build(BuildContext context) {
    final n = ref.read(associationsProvider.notifier);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _FilterChip(
          label: state.filterAgree == null
              ? 'Agrément'
              : (state.filterAgree == 'true' ? 'Agréées' : 'Non agréées'),
          active: state.filterAgree != null,
          onTap: () async {
            final picked = await _pickFromList(
              context,
              title: 'Filtrer par agrément',
              items: const [
                _PickItem(code: 'true', label: 'Agréées'),
                _PickItem(code: 'false', label: 'Non agréées'),
              ],
              selected: state.filterAgree,
            );
            if (picked != null) {
              n.load(page: 1, filterAgree: picked);
            }
          },
        ),
        _FilterChip(
          label: state.filterFederation == null
              ? 'Fédération'
              : _fedLabel(state.filterFederation!),
          active: state.filterFederation != null,
          onTap: () => _showFilterFederation(context),
        ),
        _FilterChip(
          label: state.filterLocalite == null
              ? 'Localité'
              : _locLabel(state.filterLocalite!),
          active: state.filterLocalite != null,
          onTap: () => _showFilterLocalite(context),
        ),
        if (state.hasActiveFilters)
          ActionChip(
            label: Text('Réinitialiser',
                style: GoogleFonts.inter(
                    fontSize: 12, color: SigsTheme.dangerRed)),
            backgroundColor: Colors.red.shade50,
            side: BorderSide(color: Colors.red.shade200),
            onPressed: () => n.clearFilters(),
          ),
      ],
    );
  }

  String _fedLabel(String code) {
    final opts = ref.read(associationsProvider).formOptions;
    if (opts == null) return code;
    final m = opts.federations.where((f) => f['code'] == code);
    return m.isNotEmpty ? m.first['sigle_fed'] as String : code;
  }

  String _locLabel(String code) {
    final opts = ref.read(associationsProvider).formOptions;
    if (opts == null) return code;
    final m = opts.localites.where((l) => l['code'] == code);
    return m.isNotEmpty ? m.first['libelle_localite'] as String : code;
  }

  void _showFilterFederation(BuildContext ctx) async {
    var opts = ref.read(associationsProvider).formOptions;
    if (opts == null) {
      await ref.read(associationsProvider.notifier).loadFormOptions();
      opts = ref.read(associationsProvider).formOptions;
    }
    if (opts == null || opts.federations.isEmpty) return;
    if (!ctx.mounted) return;
    final picked = await _pickFromList(
      ctx,
      title: 'Filtrer par fédération',
      items: opts.federations
          .map((f) => _PickItem(
                code: f['code'] as String,
                label: f['sigle_fed'] as String,
              ))
          .toList(),
      selected: state.filterFederation,
    );
    if (picked != null) {
      ref.read(associationsProvider.notifier).load(
            page: 1,
            filterFederation: picked,
          );
    }
  }

  void _showFilterLocalite(BuildContext ctx) async {
    var opts = ref.read(associationsProvider).formOptions;
    if (opts == null) {
      await ref.read(associationsProvider.notifier).loadFormOptions();
      opts = ref.read(associationsProvider).formOptions;
    }
    if (opts == null || opts.localites.isEmpty) return;
    if (!ctx.mounted) return;
    final picked = await _pickFromList(
      ctx,
      title: 'Filtrer par localité',
      items: opts.localites
          .map((l) => _PickItem(
                code: l['code'] as String,
                label: l['libelle_localite'] as String,
              ))
          .toList(),
      selected: state.filterLocalite,
    );
    if (picked != null) {
      ref.read(associationsProvider.notifier).load(
            page: 1,
            filterLocalite: picked,
          );
    }
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
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: active ? Colors.white : SigsTheme.primaryBlue,
        ),
      ),
      backgroundColor: active ? SigsTheme.primaryOrange : Colors.white,
      side: BorderSide(
        color: active ? SigsTheme.primaryOrange : Colors.grey.shade300,
      ),
      onPressed: onTap,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  SELECTION BAR (bulk actions)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SelectionBar extends StatelessWidget {
  final WidgetRef ref;
  final AssociationsState state;
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
                  final n = ref.read(associationsProvider.notifier);
                  allSelected ? n.deselectAll() : n.selectAll();
                },
                activeColor: SigsTheme.primaryOrange,
                side: const BorderSide(color: Colors.white54),
              ),
              Expanded(
                child: Text(
                  count == 0
                      ? 'Cochez les associations'
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
                      icon: Icons.verified_rounded,
                      label: 'Agréer',
                      color: SigsTheme.successGreen,
                      onTap: () => _doBulkAgree(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BulkActionBtn(
                      icon: Icons.remove_circle_outline_rounded,
                      label: 'Retirer',
                      color: SigsTheme.warningAmber,
                      onTap: () => _doBulkAgree(false),
                    ),
                  ),
                  const SizedBox(width: 8),
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

  void _doBulkAgree(bool agree) async {
    final count = state.selectedCodes.length;
    final action = agree ? 'agréer' : 'retirer l\'agrément de';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(agree ? 'Agréer en masse' : 'Retirer l\'agrément'),
        content: Text('Voulez-vous $action $count association(s) ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
                backgroundColor:
                    agree ? SigsTheme.successGreen : SigsTheme.warningAmber),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    HapticFeedback.mediumImpact();
    final err =
        await ref.read(associationsProvider.notifier).bulkSetAgree(agree);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ??
          (agree
              ? '$count association(s) agréée(s)'
              : 'Agrément retiré pour $count association(s)')),
      backgroundColor: err == null ? SigsTheme.successGreen : Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _doBulkDelete() async {
    final count = state.selectedCodes.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Suppression en masse'),
        content: Text(
            'Voulez-vous supprimer $count association(s) ? Cette action est irréversible.'),
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
    if (confirmed != true || !context.mounted) return;
    HapticFeedback.heavyImpact();
    final err = await ref.read(associationsProvider.notifier).bulkDelete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? '$count association(s) supprimée(s)'),
      backgroundColor: err == null ? SigsTheme.successGreen : Colors.red.shade600,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  ASSOCIATION CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _AssociationCard extends StatelessWidget {
  final Association assoc;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onLongPress;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssociationCard({
    required this.assoc,
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
            color: isSelected
                ? SigsTheme.primaryOrange
                : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2),
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
              if (assoc.logoUrl != null && assoc.logoUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl:
                          AppConstants.toAbsoluteUrl(assoc.logoUrl!) ?? '',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.groups_rounded,
                            color: Colors.grey.shade400, size: 22),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: SigsTheme.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        assoc.sigleAs.isNotEmpty
                            ? assoc.sigleAs.substring(
                                0,
                                assoc.sigleAs.length > 3
                                    ? 3
                                    : assoc.sigleAs.length)
                            : '?',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: SigsTheme.primaryBlue,
                        ),
                      ),
                    ),
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
                            assoc.sigleAs,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: SigsTheme.primaryBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _AgreeBadge(agree: assoc.estAgree),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      assoc.libelleAs,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (assoc.localiteNom.isNotEmpty)
                          _InfoChip(
                              Icons.location_on_outlined, assoc.localiteNom),
                        if (assoc.federationNom.isNotEmpty)
                          _InfoChip(
                              Icons.account_balance_outlined,
                              assoc.federationNom),
                        if (assoc.presidentAs != null &&
                            assoc.presidentAs!.isNotEmpty)
                          _InfoChip(
                              Icons.person_outline, assoc.presidentAs!),
                      ],
                    ),
                  ],
                ),
              ),
              if (!selectionMode)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: Colors.grey.shade400, size: 20),
                  onSelected: (v) {
                    switch (v) {
                      case 'detail':
                        onDetail();
                      case 'edit':
                        onEdit();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'detail', child: Text('Détail')),
                    const PopupMenuItem(
                        value: 'edit', child: Text('Modifier')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer',
                          style: TextStyle(color: SigsTheme.dangerRed)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreeBadge extends StatelessWidget {
  final bool agree;
  const _AgreeBadge({required this.agree});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: agree
            ? SigsTheme.successGreen.withValues(alpha: 0.12)
            : SigsTheme.dangerRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        agree ? 'Agréée' : 'Non agréée',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: agree ? SigsTheme.successGreen : SigsTheme.dangerRed,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  PAGINATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _PaginationRow extends StatelessWidget {
  final AssociationsState state;
  final WidgetRef ref;
  const _PaginationRow({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    const pageSize = 25;
    final totalPages = (state.totalRecords / pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: state.page > 1
                ? () => ref
                    .read(associationsProvider.notifier)
                    .load(page: state.page - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
          ),
          Text(
            'Page ${state.page} / $totalPages',
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w500),
          ),
          IconButton(
            onPressed: state.page < totalPages
                ? () => ref
                    .read(associationsProvider.notifier)
                    .load(page: state.page + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  DETAIL SHEET (loads full detail from API)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _AssociationDetailLoader extends ConsumerStatefulWidget {
  final String code;
  const _AssociationDetailLoader({required this.code});

  @override
  ConsumerState<_AssociationDetailLoader> createState() =>
      _AssociationDetailLoaderState();
}

class _AssociationDetailLoaderState
    extends ConsumerState<_AssociationDetailLoader> {
  Association? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() async {
    try {
      final repo = ref.read(associationRepoProvider);
      final d = await repo.fetchDetail(widget.code);
      if (mounted) setState(() { _detail = d; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
            child:
                CircularProgressIndicator(color: SigsTheme.primaryOrange)),
      );
    }
    if (_detail == null) {
      return Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: Text('Impossible de charger le détail',
              style: GoogleFonts.inter(color: Colors.grey)),
        ),
      );
    }
    return _AssociationDetailSheet(assoc: _detail!);
  }
}

class _AssociationDetailSheet extends StatelessWidget {
  final Association assoc;
  const _AssociationDetailSheet({required this.assoc});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
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
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Détail de l\'association',
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
                  if (assoc.logoUrl != null &&
                      assoc.logoUrl!.isNotEmpty) ...[
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl:
                              AppConstants.toAbsoluteUrl(assoc.logoUrl!) ??
                                  '',
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 120, width: 120,
                            color: Colors.grey.shade100,
                            child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 120, width: 120,
                            color: Colors.grey.shade100,
                            child: Icon(Icons.broken_image_rounded,
                                size: 40, color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _SectionTitle('Identification'),
                  const SizedBox(height: 8),
                  _DetailRow('Code', assoc.code, mono: true),
                  _DetailRow('Sigle', assoc.sigleAs),
                  _DetailRow('Nom complet', assoc.libelleAs),
                  if (assoc.typeAssociationNom.isNotEmpty)
                    _DetailRow('Type', assoc.typeAssociationNom),
                  _DetailRowWidget(
                    'Agrément',
                    _AgreeBadge(agree: assoc.estAgree),
                  ),
                  if (assoc.statutJuridiqueAs != null &&
                      assoc.statutJuridiqueAs!.isNotEmpty)
                    _DetailRow(
                        'Statut juridique', assoc.statutJuridiqueAs!),
                  if (assoc.dateCreationAs != null)
                    _DetailRow('Date de création',
                        _formatDate(assoc.dateCreationAs!)),

                  const SizedBox(height: 16),
                  _SectionTitle('Localisation'),
                  const SizedBox(height: 8),
                  _DetailRow(
                    'Localité',
                    assoc.localiteNom.isNotEmpty
                        ? assoc.localiteNom
                        : '—',
                  ),
                  if (assoc.siegeSocial != null &&
                      assoc.siegeSocial!.isNotEmpty)
                    _DetailRow('Siège social', assoc.siegeSocial!),
                  if (assoc.adresseAs != null &&
                      assoc.adresseAs!.isNotEmpty)
                    _DetailRow('Adresse', assoc.adresseAs!),

                  const SizedBox(height: 16),
                  _SectionTitle('Contact'),
                  const SizedBox(height: 8),
                  if (assoc.presidentAs != null &&
                      assoc.presidentAs!.isNotEmpty)
                    _DetailRow('Président', assoc.presidentAs!),
                  if (assoc.contactAs != null &&
                      assoc.contactAs!.isNotEmpty)
                    _DetailRow('Téléphone', assoc.contactAs!),
                  if (assoc.emailAs != null && assoc.emailAs!.isNotEmpty)
                    _DetailRow('Email', assoc.emailAs!),
                  if (assoc.sitewebAs != null &&
                      assoc.sitewebAs!.isNotEmpty)
                    _DetailRow('Site web', assoc.sitewebAs!),

                  if (assoc.federationNom.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionTitle('Fédération'),
                    const SizedBox(height: 8),
                    _DetailRow('Fédération', assoc.federationNom),
                  ],

                  if ((assoc.recepisseUrl != null &&
                          assoc.recepisseUrl!.isNotEmpty) ||
                      (assoc.agrementUrl != null &&
                          assoc.agrementUrl!.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    _SectionTitle('Documents'),
                    const SizedBox(height: 8),
                    if (assoc.recepisseUrl != null &&
                        assoc.recepisseUrl!.isNotEmpty)
                      _DocLink(
                          label: 'Récépissé', url: assoc.recepisseUrl!),
                    if (assoc.agrementUrl != null &&
                        assoc.agrementUrl!.isNotEmpty)
                      _DocLink(label: 'Agrément', url: assoc.agrementUrl!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(String iso) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class _DocLink extends StatelessWidget {
  final String label;
  final String url;
  const _DocLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.description_outlined,
              size: 18, color: SigsTheme.primaryOrange),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: SigsTheme.primaryBlue,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  ERROR / EMPTY STATES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: SigsTheme.dangerRed),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.red.shade700))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.groups_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Aucune association trouvée',
            style: GoogleFonts.inter(
                fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  DETAIL HELPERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  FORM (create / edit)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

void _showAssociationForm(
    BuildContext context, WidgetRef ref, Association? existing) async {
  final isEdit = existing != null;

  var formOpts = ref.read(associationsProvider).formOptions;
  if (formOpts == null) {
    await ref.read(associationsProvider.notifier).loadFormOptions();
    formOpts = ref.read(associationsProvider).formOptions;
  }

  final sigleCtrl = TextEditingController(text: existing?.sigleAs ?? '');
  final libelleCtrl = TextEditingController(text: existing?.libelleAs ?? '');
  final presidentCtrl =
      TextEditingController(text: existing?.presidentAs ?? '');
  final contactCtrl = TextEditingController(text: existing?.contactAs ?? '');
  final emailCtrl = TextEditingController(text: existing?.emailAs ?? '');
  final sitewebCtrl = TextEditingController(text: existing?.sitewebAs ?? '');
  final siegeCtrl = TextEditingController(text: existing?.siegeSocial ?? '');
  final adresseCtrl = TextEditingController(text: existing?.adresseAs ?? '');
  final statutJurCtrl =
      TextEditingController(text: existing?.statutJuridiqueAs ?? '');

  String? selectedLocalite = existing?.localite;
  String? selectedFederation = existing?.federation;
  String? selectedType = existing?.typeAssociation;
  bool estAgree = existing?.estAgree ?? false;
  String? dateCreation = existing?.dateCreationAs;

  String? logoLocalPath;
  bool logoRemoved = false;
  String? recepisseLocalPath;
  bool recepisseRemoved = false;
  String? agrementLocalPath;
  bool agrementRemoved = false;

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
          final sigle = sigleCtrl.text.trim();
          final libelle = libelleCtrl.text.trim();
          if (sigle.isEmpty || libelle.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Le sigle et le nom sont requis'),
              backgroundColor: Colors.red,
            ));
            return;
          }

          setSheetState(() => saving = true);

          final data = <String, dynamic>{
            'sigle_as': sigle,
            'libelle_as': libelle,
            'est_agree': estAgree,
          };
          if (selectedLocalite != null) data['localite'] = selectedLocalite;
          if (selectedFederation != null) {
            data['federation'] = selectedFederation;
          }
          if (selectedType != null) {
            data['type_association'] = selectedType;
          }
          _addIfNotEmpty(data, 'president_as', presidentCtrl.text);
          _addIfNotEmpty(data, 'contact_as', contactCtrl.text);
          _addIfNotEmpty(data, 'email_as', emailCtrl.text);
          _addIfNotEmpty(data, 'siteweb_as', sitewebCtrl.text);
          _addIfNotEmpty(data, 'siege_social', siegeCtrl.text);
          _addIfNotEmpty(data, 'adresse_as', adresseCtrl.text);
          _addIfNotEmpty(data, 'statut_juridique_as', statutJurCtrl.text);
          if (dateCreation != null) data['date_creation_as'] = dateCreation;
          if (logoRemoved && logoLocalPath == null) data['logo_as'] = '';
          if (recepisseRemoved && recepisseLocalPath == null) {
            data['recepisse_as'] = '';
          }
          if (agrementRemoved && agrementLocalPath == null) {
            data['agrement_as'] = '';
          }

          final notifier = ref.read(associationsProvider.notifier);
          final err = isEdit
              ? await notifier.update(
                  existing.code, data,
                  logoPath: logoLocalPath,
                  recepisePath: recepisseLocalPath,
                  agrementPath: agrementLocalPath,
                )
              : await notifier.create(
                  data,
                  logoPath: logoLocalPath,
                  recepisePath: recepisseLocalPath,
                  agrementPath: agrementLocalPath,
                );

          if (!ctx.mounted) return;
          setSheetState(() => saving = false);

          if (err == null) {
            Navigator.pop(ctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text(isEdit ? 'Modifié avec succès' : 'Créé avec succès'),
                backgroundColor: SigsTheme.successGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(err),
              backgroundColor: Colors.red.shade600,
            ));
          }
        }

        String locLabel(String? code) {
          if (code == null) return 'Sélectionner';
          final m = (opts?.localites ?? []).where((l) => l['code'] == code);
          return m.isNotEmpty ? m.first['libelle_localite'] as String : code;
        }

        String fedLabel(String? code) {
          if (code == null) return 'Sélectionner';
          final m =
              (opts?.federations ?? []).where((f) => f['code'] == code);
          return m.isNotEmpty ? m.first['sigle_fed'] as String : code;
        }

        String typeLabel(String? code) {
          if (code == null) return 'Sélectionner';
          final m = (opts?.typesAssociation ?? [])
              .where((t) => t['code'] == code);
          return m.isNotEmpty ? m.first['libelleType_AS'] as String : code;
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit
                          ? 'Modifier l\'association'
                          : 'Nouvelle Association',
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
                      // ─── Identification ───
                      _FormSectionTitle('Identification'),
                      const SizedBox(height: 8),
                      _FField(label: 'Sigle *', controller: sigleCtrl),
                      _FField(label: 'Nom complet *', controller: libelleCtrl),
                      _DropdownField(
                        label: 'Type d\'association',
                        value: typeLabel(selectedType),
                        onTap: () async {
                          final types = opts?.typesAssociation ?? [];
                          if (types.isEmpty) return;
                          final picked = await _pickFromList(
                            ctx,
                            title: 'Type d\'association',
                            items: types
                                .map((t) => _PickItem(
                                      code: t['code'] as String,
                                      label: t['libelleType_AS'] as String,
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
                          label: 'Statut juridique',
                          controller: statutJurCtrl),

                      // ─── Statut agrément ───
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Association agréée',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Switch(
                              value: estAgree,
                              activeTrackColor: SigsTheme.successGreen,
                              onChanged: (val) =>
                                  setSheetState(() => estAgree = val),
                            ),
                          ],
                        ),
                      ),

                      // ─── Localisation ───
                      _FormSectionTitle('Localisation'),
                      const SizedBox(height: 8),
                      _DropdownField(
                        label: 'Localité',
                        value: locLabel(selectedLocalite),
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
                      _FField(
                          label: 'Siège social', controller: siegeCtrl),
                      _FField(label: 'Adresse', controller: adresseCtrl),

                      // ─── Contact ───
                      const SizedBox(height: 4),
                      _FormSectionTitle('Contact'),
                      const SizedBox(height: 8),
                      _FField(
                          label: 'Président', controller: presidentCtrl),
                      _FField(
                        label: 'Téléphone',
                        controller: contactCtrl,
                        keyboardType: TextInputType.phone,
                      ),
                      _FField(
                        label: 'Email',
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _FField(
                        label: 'Site web',
                        controller: sitewebCtrl,
                        keyboardType: TextInputType.url,
                      ),

                      // ─── Fédération ───
                      const SizedBox(height: 4),
                      _FormSectionTitle('Fédération'),
                      const SizedBox(height: 8),
                      _DropdownField(
                        label: 'Fédération',
                        value: fedLabel(selectedFederation),
                        onTap: () async {
                          final feds = opts?.federations ?? [];
                          if (feds.isEmpty) return;
                          final picked = await _pickFromList(
                            ctx,
                            title: 'Fédération',
                            items: feds
                                .map((f) => _PickItem(
                                      code: f['code'] as String,
                                      label: f['sigle_fed'] as String,
                                    ))
                                .toList(),
                            selected: selectedFederation,
                          );
                          if (picked != null) {
                            setSheetState(
                                () => selectedFederation = picked);
                          }
                        },
                      ),

                      // ─── Date de création ───
                      const SizedBox(height: 4),
                      _FormSectionTitle('Historique'),
                      const SizedBox(height: 8),
                      _DatePickerField(
                        label: 'Date de création',
                        value: dateCreation,
                        onChanged: (val) =>
                            setSheetState(() => dateCreation = val),
                      ),

                      // ─── Logo ───
                      const SizedBox(height: 4),
                      _FormSectionTitle('Logo'),
                      const SizedBox(height: 8),
                      _ImagePickerSection(
                        existingUrl: (isEdit &&
                                existing.logoUrl != null &&
                                !logoRemoved &&
                                logoLocalPath == null)
                            ? AppConstants.toAbsoluteUrl(existing.logoUrl!)
                            : null,
                        localPath: logoLocalPath,
                        onPickGallery: () async {
                          final xf = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (xf != null) {
                            setSheetState(() {
                              logoLocalPath = xf.path;
                              logoRemoved = false;
                            });
                          }
                        },
                        onPickCamera: () async {
                          final xf = await ImagePicker()
                              .pickImage(source: ImageSource.camera);
                          if (xf != null) {
                            setSheetState(() {
                              logoLocalPath = xf.path;
                              logoRemoved = false;
                            });
                          }
                        },
                        onRemove: () {
                          setSheetState(() {
                            logoLocalPath = null;
                            logoRemoved = true;
                          });
                        },
                        hasFile: logoLocalPath != null ||
                            (isEdit &&
                                existing.logoUrl != null &&
                                !logoRemoved),
                      ),

                      // ─── Documents ───
                      const SizedBox(height: 4),
                      _FormSectionTitle('Documents'),
                      const SizedBox(height: 8),
                      _FilePickerField(
                        label: 'Récépissé',
                        fileName: recepisseLocalPath != null
                            ? recepisseLocalPath!.split('/').last
                            : (isEdit &&
                                    existing.recepisseUrl != null &&
                                    !recepisseRemoved)
                                ? 'Document existant'
                                : null,
                        onPick: () async {
                          final result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: [
                              'pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'
                            ],
                          );
                          if (result != null &&
                              result.files.single.path != null) {
                            setSheetState(() {
                              recepisseLocalPath =
                                  result.files.single.path;
                              recepisseRemoved = false;
                            });
                          }
                        },
                        onRemove: () {
                          setSheetState(() {
                            recepisseLocalPath = null;
                            recepisseRemoved = true;
                          });
                        },
                        hasFile: recepisseLocalPath != null ||
                            (isEdit &&
                                existing.recepisseUrl != null &&
                                !recepisseRemoved),
                      ),
                      _FilePickerField(
                        label: 'Agrément',
                        fileName: agrementLocalPath != null
                            ? agrementLocalPath!.split('/').last
                            : (isEdit &&
                                    existing.agrementUrl != null &&
                                    !agrementRemoved)
                                ? 'Document existant'
                                : null,
                        onPick: () async {
                          final result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: [
                              'pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'
                            ],
                          );
                          if (result != null &&
                              result.files.single.path != null) {
                            setSheetState(() {
                              agrementLocalPath =
                                  result.files.single.path;
                              agrementRemoved = false;
                            });
                          }
                        },
                        onRemove: () {
                          setSheetState(() {
                            agrementLocalPath = null;
                            agrementRemoved = true;
                          });
                        },
                        hasFile: agrementLocalPath != null ||
                            (isEdit &&
                                existing.agrementUrl != null &&
                                !agrementRemoved),
                      ),

                      // ─── Submit ───
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
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white,
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

void _addIfNotEmpty(Map<String, dynamic> data, String key, String text) {
  final v = text.trim();
  if (v.isNotEmpty) data[key] = v;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  FORM WIDGETS (shared helpers)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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

class _FField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  const _FField({
    required this.label,
    required this.controller,
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
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () async {
              DateTime? initial;
              if (value != null) initial = DateTime.tryParse(value!);
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
                child: Text('Effacer',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade500)),
              ),
            ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  IMAGE PICKER SECTION (for logo)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ImagePickerSection extends StatelessWidget {
  final String? existingUrl;
  final String? localPath;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onRemove;
  final bool hasFile;

  const _ImagePickerSection({
    this.existingUrl,
    this.localPath,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRemove,
    required this.hasFile,
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
                height: 120,
                width: 120,
                fit: BoxFit.cover,
              ),
            )
          else if (existingUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: existingUrl!,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 120, width: 120,
                  color: Colors.grey.shade100,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 120, width: 120,
                  color: Colors.grey.shade100,
                  child: Icon(Icons.broken_image_rounded,
                      size: 40, color: Colors.grey.shade400),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SmallActionBtn(
                icon: Icons.photo_library_rounded,
                label: 'Galerie',
                onTap: onPickGallery,
              ),
              const SizedBox(width: 10),
              _SmallActionBtn(
                icon: Icons.camera_alt_rounded,
                label: 'Caméra',
                onTap: onPickCamera,
              ),
              if (hasFile) ...[
                const SizedBox(width: 10),
                _SmallActionBtn(
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

class _SmallActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _SmallActionBtn({
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
                color: danger
                    ? SigsTheme.dangerRed.withValues(alpha: 0.3)
                    : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 3),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  FILE PICKER (for documents: recepisse, agrement)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _FilePickerField extends StatelessWidget {
  final String label;
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final bool hasFile;

  const _FilePickerField({
    required this.label,
    this.fileName,
    required this.onPick,
    required this.onRemove,
    required this.hasFile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: onPick,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasFile
                      ? SigsTheme.primaryOrange.withValues(alpha: 0.4)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasFile
                        ? Icons.description_rounded
                        : Icons.upload_file_rounded,
                    size: 18,
                    color: hasFile
                        ? SigsTheme.primaryOrange
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fileName ?? 'Choisir un fichier',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: hasFile
                            ? SigsTheme.primaryBlue
                            : Colors.grey.shade400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasFile)
                    GestureDetector(
                      onTap: onRemove,
                      child: Icon(Icons.close,
                          size: 18, color: Colors.grey.shade500),
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  PICKER HELPERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
  final searchCtrl = TextEditingController();
  String? result;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final q = searchCtrl.text.toLowerCase();
        final filtered = q.isEmpty
            ? items
            : items.where((i) => i.label.toLowerCase().contains(q)).toList();

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: SigsTheme.primaryBlue)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (_) => setS(() {}),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher…',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final isSel = item.code == selected;
                    return ListTile(
                      dense: true,
                      title: Text(item.label,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isSel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: SigsTheme.primaryBlue)),
                      trailing: isSel
                          ? const Icon(Icons.check,
                              color: SigsTheme.primaryOrange, size: 18)
                          : null,
                      onTap: () {
                        result = item.code;
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  searchCtrl.dispose();
  return result;
}
