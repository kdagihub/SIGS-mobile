import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../../../models/territoire_models.dart';
import '../../../providers/territoire_provider.dart';

class LocalitesTab extends ConsumerStatefulWidget {
  const LocalitesTab({super.key});

  @override
  ConsumerState<LocalitesTab> createState() => _LocalitesTabState();
}

class _LocalitesTabState extends ConsumerState<LocalitesTab>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = ref.read(localitesProvider.notifier);
      n.loadStats();
      n.loadFormOptions();
      n.load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    ref.read(localitesProvider.notifier).load(search: val);
  }

  void _showCreateDialog() {
    _showLocaliteForm(context, ref, null);
  }

  void _showEditDialog(Localite loc) {
    _showLocaliteForm(context, ref, loc);
  }

  void _showDetail(Localite loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocaliteDetailSheet(localite: loc),
    );
  }

  Future<void> _confirmDelete(Localite loc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Supprimer la localité « ${loc.libelleLocalite} » ?\nCette action est irréversible.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    HapticFeedback.mediumImpact();
    final err = await ref.read(localitesProvider.notifier).delete(loc.code);
    if (!mounted) return;
    _showSnack(err == null ? 'Supprimé avec succès' : err, err != null);
  }

  void _showSnack(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade600 : SigsTheme.successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final st = ref.watch(localitesProvider);

    return RefreshIndicator(
      color: SigsTheme.primaryOrange,
      onRefresh: () async {
        final n = ref.read(localitesProvider.notifier);
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
                  'Localités',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: SigsTheme.primaryBlue,
                  ),
                ),
              ),
              SizedBox(
                height: 36,
                child: FilledButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Ajouter', style: GoogleFonts.inter(fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: SigsTheme.primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Stats ──
          _LocaliteStatsRow(stats: st.stats, loading: st.statsLoading),
          const SizedBox(height: 20),

          // ── Search ──
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Rechercher une localité…',
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
          ),
          const SizedBox(height: 12),

          // ── Liste ──
          if (st.loading && st.records.isEmpty)
            _ListShimmer()
          else if (st.records.isEmpty)
            _EmptyState(message: st.error ?? 'Aucune localité trouvée.')
          else
            ...st.records.map((loc) => _LocaliteCard(
                  loc: loc,
                  onTap: () => _showDetail(loc),
                  onEdit: () => _showEditDialog(loc),
                  onDelete: () => _confirmDelete(loc),
                )),

          if (st.totalRecords > 25) ...[
            const SizedBox(height: 12),
            _PaginationRow(
              page: st.page,
              total: st.totalRecords,
              onPrev: st.page > 1
                  ? () => ref.read(localitesProvider.notifier).load(page: st.page - 1)
                  : null,
              onNext: st.page * 25 < st.totalRecords
                  ? () => ref.read(localitesProvider.notifier).load(page: st.page + 1)
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

class _LocaliteStatsRow extends StatelessWidget {
  final LocaliteStats stats;
  final bool loading;
  const _LocaliteStatsRow({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MS('Total', stats.total, Icons.location_on_rounded,
          const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
      _MS('Avec GPS', stats.withGps, Icons.gps_fixed_rounded,
          const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
      _MS('Sans GPS', stats.withoutGps, Icons.gps_off_rounded,
          const Color(0xFFEA580C), const Color(0xFFFFEDD5)),
      _MS('Sous DD', stats.underDd, Icons.account_tree_rounded,
          const Color(0xFF7C3AED), const Color(0xFFF3E8FF)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: items.map((m) => _MiniCard(stat: m, loading: loading)).toList(),
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
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Localite card
// ═══════════════════════════════════════════════════════════════

class _LocaliteCard extends StatelessWidget {
  final Localite loc;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _LocaliteCard({
    required this.loc,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: Color(0xFF2563EB), size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.libelleLocalite,
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
                            loc.directionDepartementNom ?? '— (Directe DR)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (loc.coordonneesGps != null &&
                        loc.coordonneesGps!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.gps_fixed,
                                size: 11, color: Color(0xFF16A34A)),
                            const SizedBox(width: 3),
                            Text(
                              'GPS',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (loc.directionRegionaleNom != null)
                      Expanded(
                        child: Text(
                          loc.directionRegionaleNom!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const Spacer(),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

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
// Detail bottom sheet
// ═══════════════════════════════════════════════════════════════

class _LocaliteDetailSheet extends StatelessWidget {
  final Localite localite;
  const _LocaliteDetailSheet({required this.localite});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
            'Détail de la localité',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: SigsTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          _DetailRow('Code', localite.code, mono: true),
          _DetailRow('Libellé', localite.libelleLocalite),
          _DetailRow('Direction Régionale', localite.directionRegionaleNom ?? '—'),
          _DetailRow(
              'Direction Départementale',
              localite.directionDepartementNom ?? '— (Directe DR)'),
          _DetailRow(
            'Coordonnées GPS',
            localite.coordonneesGps ?? 'Non renseigné',
            mono: localite.coordonneesGps != null,
          ),
          if (localite.nbInfrastructures != null)
            _DetailRow('Infrastructures', '${localite.nbInfrastructures}'),
          if (localite.nbAssociations != null)
            _DetailRow('Associations', '${localite.nbAssociations}'),
          const SizedBox(height: 8),
        ],
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
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left), iconSize: 20),
        Text(
          'Page $page / $totalPages',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right), iconSize: 20),
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
          height: 88,
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
          Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.shade300),
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

// ═══════════════════════════════════════════════════════════════
// Create / Edit form bottom sheet
// ═══════════════════════════════════════════════════════════════

void _showLocaliteForm(BuildContext context, WidgetRef ref, Localite? existing) {
  final isEdit = existing != null;
  final formOpts = ref.read(localitesProvider).formOptions;
  final defaults = formOpts?.defaults ?? {};
  final drs = formOpts?.directionsRegionales ?? [];
  final dds = formOpts?.directionsDepartementales ?? [];

  final libelleCtrl =
      TextEditingController(text: existing?.libelleLocalite ?? '');
  final gpsCtrl =
      TextEditingController(text: existing?.coordonneesGps ?? '');

  String? selectedDr = existing?.directionRegionale ??
      defaults['direction_regionale'] as String?;
  String? selectedDd = existing?.directionDepartement ??
      defaults['direction_departement'] as String?;

  final bool drLocked = drs.length <= 1;
  final bool ddLocked = defaults.containsKey('direction_departement');

  bool saving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        Future<void> save() async {
          final libelle = libelleCtrl.text.trim();
          if (libelle.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Le nom est requis'),
              backgroundColor: Colors.red,
            ));
            return;
          }
          setSheetState(() => saving = true);
          final data = <String, dynamic>{
            'libelle_localite': libelle,
            'coordonnees_gps': gpsCtrl.text.trim(),
          };
          if (selectedDr != null) data['direction_regionale'] = selectedDr;
          if (selectedDd != null) data['direction_departement'] = selectedDd;

          final notifier = ref.read(localitesProvider.notifier);
          final err = isEdit
              ? await notifier.update(existing.code, data)
              : await notifier.create(data);

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

        String drLabel(String? code) {
          if (code == null) return 'Aucune';
          final match = drs.where((d) => d['code'] == code);
          return match.isNotEmpty
              ? match.first['libelle_dr'] as String
              : code;
        }

        String ddLabel(String? code) {
          if (code == null) return 'Aucune (directe DR)';
          final match = dds.where((d) => d['code'] == code);
          return match.isNotEmpty
              ? match.first['libelle_dd'] as String
              : code;
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEdit ? 'Modifier la localité' : 'Nouvelle Localité',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SigsTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),

                _FField(
                    label: 'Nom de la localité *', controller: libelleCtrl),

                // Direction Régionale
                _DropdownField(
                  label: 'Direction Régionale',
                  value: drLabel(selectedDr),
                  locked: drLocked,
                  hint: drLocked ? 'Assignée automatiquement' : null,
                  onTap: drLocked
                      ? null
                      : () async {
                          final picked = await _pickFromList(
                            ctx,
                            title: 'Direction Régionale',
                            items: drs
                                .map((d) => _PickItem(
                                      code: d['code'] as String,
                                      label: d['libelle_dr'] as String,
                                    ))
                                .toList(),
                            selected: selectedDr,
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDr = picked);
                          }
                        },
                ),

                // Direction Départementale
                _DropdownField(
                  label: 'Direction Départementale',
                  value: ddLabel(selectedDd),
                  locked: ddLocked,
                  hint: ddLocked ? 'Assignée automatiquement' : null,
                  onTap: ddLocked
                      ? null
                      : () async {
                          final picked = await _pickFromList(
                            ctx,
                            title: 'Direction Départementale',
                            items: [
                              const _PickItem(
                                  code: '', label: 'Aucune (directe DR)'),
                              ...dds.map((d) => _PickItem(
                                    code: d['code'] as String,
                                    label: d['libelle_dd'] as String,
                                  )),
                            ],
                            selected: selectedDd ?? '',
                          );
                          if (picked != null) {
                            setSheetState(() =>
                                selectedDd = picked.isEmpty ? null : picked);
                          }
                        },
                ),

                _FField(
                  label: 'Coordonnées GPS',
                  controller: gpsCtrl,
                  hint: 'latitude,longitude (ex: 5.36,-4.01)',
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
        );
      },
    ),
  );
}

// ── Picker helper ─────────────────────────────────────────────

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

// ── Reusable form fields ──────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final bool locked;
  final String? hint;
  final VoidCallback? onTap;

  const _DropdownField({
    required this.label,
    required this.value,
    this.locked = false,
    this.hint,
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
            onTap: locked ? null : onTap,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: locked ? Colors.grey.shade50 : Colors.white,
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
                        color: locked
                            ? Colors.grey.shade500
                            : SigsTheme.primaryBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!locked)
                    Icon(Icons.arrow_drop_down,
                        color: Colors.grey.shade400, size: 22),
                ],
              ),
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                hint!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade400,
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
  const _FField({
    required this.label,
    required this.controller,
    this.hint,
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
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
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
