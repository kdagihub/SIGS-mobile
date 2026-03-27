import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/dialogs.dart';
import '../../../core/theme.dart';
import '../../../models/auth_user.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loading = true;
  AuthUser? _freshUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = await ref.read(authProvider.notifier).refreshProfile();
      if (kDebugMode) {
        debugPrint('[PROFILE] groupCode=${user.groupCode}, entityType=${user.entityType}');
        debugPrint('[PROFILE] entityInfo keys=${user.currentEntityInfo?.keys.toList()}');
      }
      if (mounted) setState(() { _freshUser = user; _loading = false; });
    } catch (e) {
      if (kDebugMode) debugPrint('[PROFILE] Erreur chargement: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _freshUser ?? ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: SigsTheme.surfaceGrey,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: _loadProfile,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SigsTheme.primaryOrange))
          : user == null
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: SigsTheme.primaryOrange,
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _ProfileHeader(user: user),
                      const SizedBox(height: 20),
                      _PersonalInfoSection(user: user),
                      if (user.currentEntityInfo != null) ...[
                        const SizedBox(height: 16),
                        _EntityInfoSection(user: user),
                      ],
                      const SizedBox(height: 16),
                      _SecuritySection(user: user),
                      const SizedBox(height: 16),
                      _PinSection(ref: ref),
                      const SizedBox(height: 20),
                      _ActionButtons(
                        user: user,
                        onProfileUpdated: _loadProfile,
                        ref: ref,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Profil non disponible',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// PROFILE HEADER
// ──────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final AuthUser user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = user.fullName.isNotEmpty
        ? user.fullName
        : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: SigsTheme.primaryBlue,
                  child: Text(
                    userInitials(displayName),
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: user.isActive ? SigsTheme.successGreen : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              displayName,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: SigsTheme.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              user.roleLabel,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
            ),
            if (user.code != null && user.code!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SigsTheme.primaryOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.code!,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SigsTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// PERSONAL INFO
// ──────────────────────────────────────────────────────────────

class _PersonalInfoSection extends StatelessWidget {
  final AuthUser user;
  const _PersonalInfoSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = user.fullName.isNotEmpty
        ? user.fullName
        : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();

    return _InfoCard(
      icon: Icons.person_rounded,
      title: 'Informations personnelles',
      items: [
        if (user.firstName != null) _InfoRow('Nom', user.firstName!),
        if (user.lastName != null) _InfoRow('Prénoms', user.lastName!),
        if (displayName.isNotEmpty && user.firstName == null)
          _InfoRow('Nom complet', displayName),
        _InfoRow('Email', user.email.isNotEmpty ? user.email : 'Non renseigné'),
        _InfoRow('Contact', user.contact ?? 'Non renseigné'),
        _InfoRow('Rôle', user.roleLabel),
        if (user.group != null) _InfoRow('Groupe', user.group!),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// ENTITY INFO — dynamic per entity type
// ──────────────────────────────────────────────────────────────

class _EntityInfoSection extends StatelessWidget {
  final AuthUser user;
  const _EntityInfoSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final info = user.currentEntityInfo;
    if (info == null) return const SizedBox.shrink();

    final sections = <Widget>[];

    sections.add(_buildGeneralInfo(info));

    final resp = _buildResponsablesSection(info);
    if (resp != null) sections.add(resp);

    final contacts = _buildContactsSection(info);
    if (contacts != null) sections.add(contacts);

    final pr = _buildPersonneRessourceSection(info);
    if (pr != null) sections.add(pr);

    final sys = _buildSystemSection(info, user);
    if (sys != null) sections.add(sys);

    return _InfoCard(
      icon: Icons.business_rounded,
      title: user.entityTypeLabel,
      children: sections,
    );
  }

  Widget _buildGeneralInfo(Map<String, dynamic> info) {
    final items = <_InfoRow>[];

    final nameKey = _findKey(info, [
      'libelle_fed', 'libelle_ligue', 'libelle_club',
      'libelle_as', 'libelle_dr', 'libelle_dd',
    ]);
    if (nameKey != null) items.add(_InfoRow('Nom', info[nameKey].toString()));

    final sigleKey = _findKey(info, ['sigle_fed', 'sigle_ligue', 'sigle_club', 'sigle_as']);
    if (sigleKey != null) items.add(_InfoRow('Sigle', info[sigleKey].toString()));

    if (info['code'] != null) items.add(_InfoRow('Code', info['code'].toString()));

    if (info['prefix_annee'] != null) {
      items.add(_InfoRow('Préfixe Année', info['prefix_annee'].toString()));
    }

    final adresseKey = _findKey(info, ['adresse_siege', 'adresse_as']);
    if (adresseKey != null) items.add(_InfoRow('Adresse', info[adresseKey].toString()));

    if (info['code_postal'] != null) items.add(_InfoRow('Code postal', info['code_postal'].toString()));
    if (info['ville'] != null) items.add(_InfoRow('Ville', info['ville'].toString()));
    if (info['region'] != null) items.add(_InfoRow('Région', info['region'].toString()));

    final siteKey = _findKey(info, ['site_web', 'siteweb_as']);
    if (siteKey != null) items.add(_InfoRow('Site web', info[siteKey].toString()));

    if (info['num_enregistrement'] != null) {
      items.add(_InfoRow('N° Enregistrement', info['num_enregistrement'].toString()));
    }

    if (info['coordonnees_gps'] != null) {
      items.add(_InfoRow('Coordonnées GPS', info['coordonnees_gps'].toString()));
    }

    return _SubSection(title: 'Informations générales', items: items);
  }

  Widget? _buildResponsablesSection(Map<String, dynamic> info) {
    final items = <_InfoRow>[];

    if (info['responsable_federal'] != null) {
      items.add(_InfoRow('Responsable fédéral', info['responsable_federal'].toString()));
    }
    if (info['responsable_dr'] != null) {
      items.add(_InfoRow('Responsable', info['responsable_dr'].toString()));
    }
    if (info['responsable_dd'] != null) {
      items.add(_InfoRow('Responsable', info['responsable_dd'].toString()));
    }
    if (info['president_nom'] != null) {
      final full = '${info['president_nom']} ${info['president_prenom'] ?? ''}'.trim();
      items.add(_InfoRow('Président', full));
    }
    if (info['president_contact'] != null) {
      items.add(_InfoRow('Contact président', info['president_contact'].toString()));
    }
    if (info['president_email'] != null) {
      items.add(_InfoRow('Email président', info['president_email'].toString()));
    }

    return items.isEmpty ? null : _SubSection(title: 'Responsables', items: items);
  }

  Widget? _buildContactsSection(Map<String, dynamic> info) {
    final items = <_InfoRow>[];

    final phoneKey = _findKey(info, [
      'contact_fed', 'contact_ligue', 'contact_club',
      'contact_as', 'contact_dr', 'contact_dd',
    ]);
    if (phoneKey != null) items.add(_InfoRow('Téléphone', info[phoneKey].toString()));

    final emailKey = _findKey(info, [
      'email_fed', 'email_ligue', 'email_club',
      'email_as', 'email_dr', 'email_dd',
    ]);
    if (emailKey != null) items.add(_InfoRow('Email', info[emailKey].toString()));

    return items.isEmpty ? null : _SubSection(title: 'Contacts', items: items);
  }

  Widget? _buildPersonneRessourceSection(Map<String, dynamic> info) {
    final items = <_InfoRow>[];

    if (info['personne_ressource_nom'] != null || info['personne_ressource_prenom'] != null) {
      final full = '${info['personne_ressource_nom'] ?? ''} ${info['personne_ressource_prenom'] ?? ''}'.trim();
      if (full.isNotEmpty) items.add(_InfoRow('Nom complet', full));
    }
    if (info['personne_ressource_contact'] != null) {
      items.add(_InfoRow('Contact', info['personne_ressource_contact'].toString()));
    }
    if (info['personne_ressource_email'] != null) {
      items.add(_InfoRow('Email', info['personne_ressource_email'].toString()));
    }

    return items.isEmpty ? null : _SubSection(title: 'Personne ressource', items: items);
  }

  Widget? _buildSystemSection(Map<String, dynamic> info, AuthUser user) {
    final items = <_InfoRow>[];

    if (info['est_agree'] != null) {
      items.add(_InfoRow('Statut', (info['est_agree'] as bool) ? 'Agréé(e)' : 'Non agréé(e)'));
    }
    if (info['is_active'] != null) {
      items.add(_InfoRow('État', (info['is_active'] as bool) ? 'Actif' : 'Inactif'));
    }
    if (info['date_creation'] != null || info['date_creation_as'] != null) {
      items.add(_InfoRow('Date d\'enregistrement',
          _formatDate(info['date_creation'] ?? info['date_creation_as'])));
    }
    if (info['discipline'] != null) {
      final disc = info['discipline'];
      final label = disc is Map
          ? (disc['libelle_discipline'] ?? disc['libelle_disc'] ?? disc.toString())
          : disc.toString();
      items.add(_InfoRow('Discipline', label.toString()));
    }

    final drInfo = info['direction_regionale'];
    if (drInfo is Map) {
      items.add(_InfoRow('Direction Régionale', drInfo['libelle_dr']?.toString() ?? drInfo['code']?.toString() ?? ''));
    }

    if (info['ligue'] is Map) {
      final ligue = info['ligue'] as Map;
      items.add(_InfoRow('Ligue', ligue['libelle_ligue']?.toString() ?? ''));
    }
    if (info['federation'] is Map) {
      final fed = info['federation'] as Map;
      final sigle = fed['sigle_fed'] != null ? ' (${fed['sigle_fed']})' : '';
      items.add(_InfoRow('Fédération', '${fed['libelle_fed'] ?? ''}$sigle'.trim()));
    }
    if (info['localite'] is Map) {
      items.add(_InfoRow('Localité', (info['localite'] as Map)['libelle_localite']?.toString() ?? ''));
    }

    if (user.directionRegionaleInfo != null &&
        user.entityType != 'direction_regionale') {
      items.add(_InfoRow('DR rattachée', user.directionRegionaleInfo!['libelle_dr']?.toString() ?? ''));
    }
    if (user.directionDepartementaleInfo != null &&
        user.entityType != 'direction_departementale') {
      items.add(_InfoRow('DD rattachée', user.directionDepartementaleInfo!['libelle_dd']?.toString() ?? ''));
    }

    return items.isEmpty ? null : _SubSection(title: 'Informations système', items: items);
  }

  String? _findKey(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      if (map[k] != null && map[k].toString().isNotEmpty) return k;
    }
    return null;
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr.toString());
      const months = [
        '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }
}

// ──────────────────────────────────────────────────────────────
// SECURITY SECTION
// ──────────────────────────────────────────────────────────────

class _SecuritySection extends StatelessWidget {
  final AuthUser user;
  const _SecuritySection({required this.user});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.shield_rounded,
      title: 'Sécurité',
      items: [
        _InfoRow('Dernière connexion', _formatDate(user.lastLogin)),
        _InfoRow('Statut du compte', user.isActive ? 'Actif' : 'Inactif'),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year} à '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ──────────────────────────────────────────────────────────────
// PIN SECTION — shows PIN status + create/update
// ──────────────────────────────────────────────────────────────

class _PinSection extends StatefulWidget {
  final WidgetRef ref;
  const _PinSection({required this.ref});

  @override
  State<_PinSection> createState() => _PinSectionState();
}

class _PinSectionState extends State<_PinSection> {
  Map<String, dynamic>? _pinStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    setState(() => _loading = true);
    try {
      final status = await widget.ref.read(authProvider.notifier).getPinStatus();
      if (mounted) setState(() { _pinStatus = status; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = _pinStatus?['has_pin'] as bool? ?? false;
    final isLocked = _pinStatus?['is_locked'] as bool? ?? false;
    final attemptsRemaining = _pinStatus?['attempts_remaining'] as int? ?? 3;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: SigsTheme.warningAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.pin_rounded, size: 16, color: SigsTheme.warningAmber),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Code PIN de sécurité',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: SigsTheme.primaryBlue,
                    ),
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: SigsTheme.primaryOrange),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_loading) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasPin
                          ? SigsTheme.successGreen.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasPin ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 14,
                          color: hasPin ? SigsTheme.successGreen : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasPin ? 'PIN configuré' : 'Aucun PIN configuré',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasPin ? SigsTheme.successGreen : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: SigsTheme.dangerRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Verrouillé',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SigsTheme.dangerRed,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasPin && !isLocked) ...[
                const SizedBox(height: 6),
                Text(
                  'Tentatives restantes : $attemptsRemaining/3',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
              const SizedBox(height: 12),
              if (!hasPin)
                _infoNote('Le code PIN sécurise le changement de mot de passe et la réinitialisation du compte.'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLocked ? null : () {
                    if (hasPin) {
                      _showUpdatePinSheet(context);
                    } else {
                      _showCreatePinSheet(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SigsTheme.warningAmber,
                    side: BorderSide(color: SigsTheme.warningAmber.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(hasPin ? Icons.edit_rounded : Icons.add_rounded, size: 18),
                  label: Text(hasPin ? 'Modifier le code PIN' : 'Créer un code PIN'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreatePinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreatePinSheet(
        ref: widget.ref,
        onDone: _loadPinStatus,
      ),
    );
  }

  void _showUpdatePinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpdatePinSheet(
        ref: widget.ref,
        onDone: _loadPinStatus,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CREATE PIN SHEET
// ──────────────────────────────────────────────────────────────

class _CreatePinSheet extends StatefulWidget {
  final WidgetRef ref;
  final VoidCallback onDone;

  const _CreatePinSheet({required this.ref, required this.onDone});

  @override
  State<_CreatePinSheet> createState() => _CreatePinSheetState();
}

class _CreatePinSheetState extends State<_CreatePinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _saving = false;
  bool _obscurePassword = true;
  String? _successMsg;
  String? _errorMsg;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _errorMsg = null; _successMsg = null; });

    try {
      await widget.ref.read(authProvider.notifier).createPin(
        newPin: _pinCtrl.text,
        confirmPin: _confirmCtrl.text,
        currentPassword: _passwordCtrl.text,
      );
      setState(() => _successMsg = 'Code PIN créé avec succès !');
      widget.onDone();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() => _errorMsg = _extractError(e));
    } catch (_) {
      setState(() => _errorMsg = 'Erreur inattendue.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              _sheetTitle('Créer un code PIN', Icons.pin_rounded),
              const SizedBox(height: 8),
              _infoNote('Le code PIN doit contenir entre 4 et 6 chiffres. Il sécurise les opérations sensibles.'),
              const SizedBox(height: 16),
              _buildField('Nouveau code PIN *', _pinCtrl, '••••••',
                  keyboardType: TextInputType.number,
                  validator: _pinValidator),
              const SizedBox(height: 12),
              _buildField('Confirmer le code PIN *', _confirmCtrl, '••••••',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obligatoire';
                    if (v != _pinCtrl.text) return 'Les codes PIN ne correspondent pas';
                    return null;
                  }),
              const SizedBox(height: 12),
              _buildPasswordField(
                'Mot de passe actuel *', _passwordCtrl,
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                validator: _requiredValidator('Obligatoire'),
              ),
              const SizedBox(height: 16),
              if (_successMsg != null) _alertBox(_successMsg!, isSuccess: true),
              if (_errorMsg != null) _alertBox(_errorMsg!, isSuccess: false),
              if (_successMsg != null || _errorMsg != null) const SizedBox(height: 12),
              _saveRow(
                context: context,
                saving: _saving,
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// UPDATE PIN SHEET
// ──────────────────────────────────────────────────────────────

class _UpdatePinSheet extends StatefulWidget {
  final WidgetRef ref;
  final VoidCallback onDone;

  const _UpdatePinSheet({required this.ref, required this.onDone});

  @override
  State<_UpdatePinSheet> createState() => _UpdatePinSheetState();
}

class _UpdatePinSheetState extends State<_UpdatePinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void dispose() {
    _currentPinCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _errorMsg = null; _successMsg = null; });

    try {
      await widget.ref.read(authProvider.notifier).updatePin(
        currentPin: _currentPinCtrl.text,
        newPin: _newPinCtrl.text,
        confirmPin: _confirmCtrl.text,
      );
      setState(() => _successMsg = 'Code PIN modifié avec succès !');
      widget.onDone();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() => _errorMsg = _extractError(e));
    } catch (_) {
      setState(() => _errorMsg = 'Erreur inattendue.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              _sheetTitle('Modifier le code PIN', Icons.pin_rounded),
              const SizedBox(height: 16),
              _buildField('Code PIN actuel *', _currentPinCtrl, '••••••',
                  keyboardType: TextInputType.number,
                  validator: _pinValidator),
              const SizedBox(height: 12),
              _buildField('Nouveau code PIN *', _newPinCtrl, '••••••',
                  keyboardType: TextInputType.number,
                  validator: _pinValidator),
              const SizedBox(height: 12),
              _buildField('Confirmer le nouveau PIN *', _confirmCtrl, '••••••',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obligatoire';
                    if (v != _newPinCtrl.text) return 'Les codes PIN ne correspondent pas';
                    return null;
                  }),
              const SizedBox(height: 16),
              if (_successMsg != null) _alertBox(_successMsg!, isSuccess: true),
              if (_errorMsg != null) _alertBox(_errorMsg!, isSuccess: false),
              if (_successMsg != null || _errorMsg != null) const SizedBox(height: 12),
              _saveRow(
                context: context,
                saving: _saving,
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// ACTION BUTTONS
// ──────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final AuthUser user;
  final VoidCallback onProfileUpdated;
  final WidgetRef ref;

  const _ActionButtons({
    required this.user,
    required this.onProfileUpdated,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showEditPersonalSheet(context),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Modifier le profil'),
          ),
        ),
        if (user.currentEntityInfo != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: user.entityAdmin
                  ? () => _showEditEntitySheet(context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: SigsTheme.primaryBlue,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              icon: const Icon(Icons.business_rounded, size: 18),
              label: Text(user.entityAdmin
                  ? 'Modifier ${user.entityTypeLabel}'
                  : 'Modification ${user.entityTypeLabel} (admin requis)'),
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showChangePasswordSheet(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: SigsTheme.primaryBlue,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.lock_rounded, size: 18),
            label: const Text('Changer le mot de passe'),
          ),
        ),
      ],
    );
  }

  void _showEditPersonalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditPersonalSheet(user: user, onUpdated: onProfileUpdated, ref: ref),
    );
  }

  void _showEditEntitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditEntitySheet(user: user, onUpdated: onProfileUpdated, ref: ref),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChangePasswordSheet(ref: ref),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// EDIT PERSONAL SHEET
// ──────────────────────────────────────────────────────────────

class _EditPersonalSheet extends StatefulWidget {
  final AuthUser user;
  final VoidCallback onUpdated;
  final WidgetRef ref;

  const _EditPersonalSheet({required this.user, required this.onUpdated, required this.ref});

  @override
  State<_EditPersonalSheet> createState() => _EditPersonalSheetState();
}

class _EditPersonalSheetState extends State<_EditPersonalSheet> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _contactCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.user.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.user.lastName ?? '');
    _emailCtrl = TextEditingController(text: widget.user.email);
    _contactCtrl = TextEditingController(text: widget.user.contact ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _errorMsg = null; _successMsg = null; });

    try {
      await widget.ref.read(authProvider.notifier).updateProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        contact: _contactCtrl.text.trim(),
      );
      setState(() => _successMsg = 'Informations mises à jour avec succès !');
      widget.onUpdated();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() => _errorMsg = _extractError(e));
    } catch (_) {
      setState(() => _errorMsg = 'Erreur inattendue. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              _sheetTitle('Modifier le profil', Icons.edit_rounded),
              const SizedBox(height: 8),
              _infoNote('Après modification, les changements seront visibles dans l\'interface.'),
              const SizedBox(height: 16),
              _buildField('Nom *', _firstNameCtrl, 'Votre nom de famille',
                  validator: _requiredValidator('Le nom est obligatoire')),
              const SizedBox(height: 12),
              _buildField('Prénoms *', _lastNameCtrl, 'Votre prénom',
                  validator: _requiredValidator('Le prénom est obligatoire')),
              const SizedBox(height: 12),
              _buildField('Email *', _emailCtrl, 'votre.email@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'L\'email est obligatoire';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) return 'Email invalide';
                    return null;
                  }),
              const SizedBox(height: 12),
              _buildField('Contact', _contactCtrl, '+225XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                  helperText: 'Format international : 0XXXXXXXX → +225XXXXXXXX'),
              const SizedBox(height: 16),
              if (_successMsg != null) _alertBox(_successMsg!, isSuccess: true),
              if (_errorMsg != null) _alertBox(_errorMsg!, isSuccess: false),
              if (_successMsg != null || _errorMsg != null) const SizedBox(height: 12),
              _saveRow(context: context, saving: _saving, onSave: _save),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// EDIT ENTITY SHEET
// ──────────────────────────────────────────────────────────────

class _EditEntitySheet extends StatefulWidget {
  final AuthUser user;
  final VoidCallback onUpdated;
  final WidgetRef ref;

  const _EditEntitySheet({required this.user, required this.onUpdated, required this.ref});

  @override
  State<_EditEntitySheet> createState() => _EditEntitySheetState();
}

class _EditEntitySheetState extends State<_EditEntitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  bool _saving = false;
  String? _successMsg;
  String? _errorMsg;

  late final List<_EntityFieldDef> _fields;

  @override
  void initState() {
    super.initState();
    _fields = _buildFieldDefs();
    final info = widget.user.currentEntityInfo ?? {};
    for (final f in _fields) {
      _controllers[f.key] = TextEditingController(
        text: info[f.key]?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<_EntityFieldDef> _buildFieldDefs() {
    switch (widget.user.entityType) {
      case 'direction_regionale':
        return [
          _EntityFieldDef('libelle_dr', 'Nom direction régionale *', required: true),
          _EntityFieldDef('responsable_dr', 'Responsable'),
          _EntityFieldDef('contact_dr', 'Contact', inputType: TextInputType.phone),
          _EntityFieldDef('email_dr', 'Email', inputType: TextInputType.emailAddress),
          _EntityFieldDef('coordonnees_gps', 'Coordonnées GPS'),
        ];
      case 'direction_departementale':
        return [
          _EntityFieldDef('libelle_dd', 'Nom direction départementale *', required: true),
          _EntityFieldDef('responsable_dd', 'Responsable'),
          _EntityFieldDef('contact_dd', 'Contact', inputType: TextInputType.phone),
          _EntityFieldDef('email_dd', 'Email', inputType: TextInputType.emailAddress),
          _EntityFieldDef('coordonnees_gps', 'Coordonnées GPS'),
        ];
      case 'federation':
        return [
          _EntityFieldDef('libelle_fed', 'Nom de la fédération *', required: true),
          _EntityFieldDef('sigle_fed', 'Sigle *', required: true),
          _EntityFieldDef('prefix_annee', 'Préfixe Année'),
          _EntityFieldDef('adresse_siege', 'Adresse du siège'),
          _EntityFieldDef('president_nom', 'Nom du président'),
          _EntityFieldDef('president_prenom', 'Prénom du président'),
          _EntityFieldDef('president_contact', 'Contact du président', inputType: TextInputType.phone),
          _EntityFieldDef('president_email', 'Email du président', inputType: TextInputType.emailAddress),
          _EntityFieldDef('personne_ressource_nom', 'Personne ressource (nom)'),
          _EntityFieldDef('personne_ressource_prenom', 'Personne ressource (prénom)'),
          _EntityFieldDef('personne_ressource_contact', 'Contact personne ressource', inputType: TextInputType.phone),
          _EntityFieldDef('personne_ressource_email', 'Email personne ressource', inputType: TextInputType.emailAddress),
        ];
      case 'ligue':
        return [
          _EntityFieldDef('libelle_ligue', 'Nom de la ligue *', required: true),
          _EntityFieldDef('sigle_ligue', 'Sigle'),
          _EntityFieldDef('contact_ligue', 'Contact', inputType: TextInputType.phone),
          _EntityFieldDef('email_ligue', 'Email', inputType: TextInputType.emailAddress),
          _EntityFieldDef('president_nom', 'Nom du président'),
          _EntityFieldDef('president_prenom', 'Prénom du président'),
          _EntityFieldDef('president_contact', 'Contact du président', inputType: TextInputType.phone),
          _EntityFieldDef('president_email', 'Email du président', inputType: TextInputType.emailAddress),
          _EntityFieldDef('personne_ressource_nom', 'Personne ressource (nom)'),
          _EntityFieldDef('personne_ressource_prenom', 'Personne ressource (prénom)'),
          _EntityFieldDef('personne_ressource_contact', 'Contact personne ressource', inputType: TextInputType.phone),
          _EntityFieldDef('personne_ressource_email', 'Email personne ressource', inputType: TextInputType.emailAddress),
        ];
      case 'club':
        return [
          _EntityFieldDef('libelle_club', 'Nom du club *', required: true),
          _EntityFieldDef('sigle_club', 'Sigle'),
          _EntityFieldDef('contact_club', 'Contact', inputType: TextInputType.phone),
          _EntityFieldDef('email_club', 'Email', inputType: TextInputType.emailAddress),
          _EntityFieldDef('president_nom', 'Nom du président'),
          _EntityFieldDef('president_prenom', 'Prénom du président'),
          _EntityFieldDef('president_contact', 'Contact du président', inputType: TextInputType.phone),
          _EntityFieldDef('president_email', 'Email du président', inputType: TextInputType.emailAddress),
          _EntityFieldDef('personne_ressource_nom', 'Personne ressource (nom)'),
          _EntityFieldDef('personne_ressource_prenom', 'Personne ressource (prénom)'),
          _EntityFieldDef('personne_ressource_contact', 'Contact personne ressource', inputType: TextInputType.phone),
          _EntityFieldDef('personne_ressource_email', 'Email personne ressource', inputType: TextInputType.emailAddress),
        ];
      case 'association_sportive':
        return [
          _EntityFieldDef('libelle_as', 'Association sportive *', required: true),
          _EntityFieldDef('sigle_as', 'Sigle'),
          _EntityFieldDef('adresse_as', 'Adresse'),
          _EntityFieldDef('contact_as', 'Contact', inputType: TextInputType.phone),
          _EntityFieldDef('email_as', 'Email', inputType: TextInputType.emailAddress),
        ];
      default:
        return [];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _errorMsg = null; _successMsg = null; });

    final data = <String, dynamic>{};
    for (final f in _fields) {
      final val = _controllers[f.key]!.text.trim();
      if (val.isNotEmpty) data[f.key] = val;
    }

    try {
      await widget.ref.read(authProvider.notifier).updateEntityInfo(data);
      setState(() => _successMsg = 'Informations mises à jour avec succès !');
      widget.onUpdated();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() => _errorMsg = _extractError(e));
    } catch (_) {
      setState(() => _errorMsg = 'Erreur inattendue. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetHandle(),
          const SizedBox(height: 16),
          _sheetTitle('Modifier ${widget.user.entityTypeLabel}', Icons.business_rounded),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final f in _fields) ...[
                      _buildField(
                        f.label,
                        _controllers[f.key]!,
                        f.label.replaceAll(' *', ''),
                        keyboardType: f.inputType,
                        validator: f.required ? _requiredValidator('Ce champ est obligatoire') : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_successMsg != null) _alertBox(_successMsg!, isSuccess: true),
                    if (_errorMsg != null) _alertBox(_errorMsg!, isSuccess: false),
                    if (_successMsg != null || _errorMsg != null) const SizedBox(height: 12),
                    _saveRow(
                      context: context,
                      saving: _saving,
                      onSave: _save,
                      primaryColor: SigsTheme.primaryBlue,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CHANGE PASSWORD SHEET
// ──────────────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  final WidgetRef ref;
  const _ChangePasswordSheet({required this.ref});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _successMsg;
  String? _errorMsg;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _errorMsg = null; _successMsg = null; });

    try {
      await widget.ref.read(authProvider.notifier).changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
        confirmNewPassword: _confirmCtrl.text,
        pin: _pinCtrl.text.isNotEmpty ? _pinCtrl.text : null,
      );
      setState(() => _successMsg = 'Mot de passe modifié avec succès !');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() => _errorMsg = _extractError(e));
    } catch (_) {
      setState(() => _errorMsg = 'Erreur inattendue. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              _sheetTitle('Changer le mot de passe', Icons.lock_rounded),
              const SizedBox(height: 16),
              _buildPasswordField(
                'Mot de passe actuel *', _currentCtrl,
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                validator: _requiredValidator('Ce champ est obligatoire'),
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                'Nouveau mot de passe *', _newCtrl,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obligatoire';
                  if (v.length < 8) return 'Minimum 8 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                'Confirmer le mot de passe *', _confirmCtrl,
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obligatoire';
                  if (v != _newCtrl.text) return 'Les mots de passe ne correspondent pas';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildField('Code PIN (si activé)', _pinCtrl, 'Votre code PIN',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              if (_successMsg != null) _alertBox(_successMsg!, isSuccess: true),
              if (_errorMsg != null) _alertBox(_errorMsg!, isSuccess: false),
              if (_successMsg != null || _errorMsg != null) const SizedBox(height: 12),
              _saveRow(context: context, saving: _saving, onSave: _save, saveLabel: 'Modifier'),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SHARED HELPERS & WIDGETS
// ══════════════════════════════════════════════════════════════

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}

class _EntityFieldDef {
  final String key;
  final String label;
  final bool required;
  final TextInputType? inputType;
  const _EntityFieldDef(this.key, this.label, {this.required = false, this.inputType});
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_InfoRow>? items;
  final List<Widget>? children;

  const _InfoCard({
    required this.icon,
    required this.title,
    this.items,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: SigsTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: SigsTheme.primaryOrange),
                ),
                const SizedBox(width: 10),
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
              ],
            ),
            const SizedBox(height: 14),
            if (items != null)
              ...items!.map((item) => _buildInfoRow(item)),
            if (children != null)
              ...children!,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(_InfoRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              row.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.value.isNotEmpty ? row.value : 'Non renseigné',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: row.value.isNotEmpty ? SigsTheme.primaryBlue : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> items;

  const _SubSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: SigsTheme.surfaceGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ...items.map((row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  row.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.value.isNotEmpty ? row.value : 'Non renseigné',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: row.value.isNotEmpty ? SigsTheme.primaryBlue : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

// ── Shared small helpers ──

Widget _sheetHandle() => Container(
  width: 40, height: 4,
  decoration: BoxDecoration(
    color: Colors.grey.shade300,
    borderRadius: BorderRadius.circular(2),
  ),
);

Widget _sheetTitle(String text, IconData icon) => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(icon, size: 20, color: SigsTheme.primaryOrange),
    const SizedBox(width: 8),
    Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: SigsTheme.primaryBlue,
      ),
    ),
  ],
);

Widget _infoNote(String text) => Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: SigsTheme.infoCyan.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: SigsTheme.infoCyan.withValues(alpha: 0.2)),
  ),
  child: Row(
    children: [
      const Icon(Icons.info_outline_rounded, size: 18, color: SigsTheme.infoCyan),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
      ),
    ],
  ),
);

Widget _buildField(
  String label,
  TextEditingController controller,
  String hint, {
  TextInputType? keyboardType,
  String? helperText,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SigsTheme.primaryBlue)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
          helperText: helperText,
          helperMaxLines: 2,
          helperStyle: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
        ),
      ),
    ],
  );
}

Widget _buildPasswordField(
  String label,
  TextEditingController controller, {
  required bool obscure,
  required VoidCallback onToggle,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SigsTheme.primaryBlue)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 20, color: Colors.grey.shade500,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    ],
  );
}

Widget _alertBox(String text, {required bool isSuccess}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: (isSuccess ? SigsTheme.successGreen : SigsTheme.dangerRed).withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: (isSuccess ? SigsTheme.successGreen : SigsTheme.dangerRed).withValues(alpha: 0.3),
    ),
  ),
  child: Row(
    children: [
      Icon(
        isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
        size: 18,
        color: isSuccess ? SigsTheme.successGreen : SigsTheme.dangerRed,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text, style: GoogleFonts.inter(
          fontSize: 13,
          color: isSuccess ? SigsTheme.successGreen : SigsTheme.dangerRed,
        )),
      ),
    ],
  ),
);

Widget _saveRow({
  required BuildContext context,
  required bool saving,
  required VoidCallback onSave,
  String saveLabel = 'Enregistrer',
  Color? primaryColor,
}) {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: saving ? null : onSave,
          style: primaryColor != null
              ? ElevatedButton.styleFrom(backgroundColor: primaryColor)
              : null,
          child: saving
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(saveLabel),
        ),
      ),
    ],
  );
}

String? Function(String?) _requiredValidator(String message) {
  return (v) => (v == null || v.trim().isEmpty) ? message : null;
}

String? _pinValidator(String? v) {
  if (v == null || v.isEmpty) return 'Obligatoire';
  if (!RegExp(r'^\d+$').hasMatch(v)) return 'Chiffres uniquement';
  if (v.length < 4 || v.length > 6) return 'Entre 4 et 6 chiffres';
  return null;
}

String _extractError(DioException e) {
  final d = e.response?.data;
  if (d is Map) {
    if (d['detail'] != null) return d['detail'].toString();
    return d.entries
        .map((e) => e.value is List ? (e.value as List).join(', ') : e.value.toString())
        .join('\n');
  }
  return d?.toString() ?? 'Erreur lors de l\'opération';
}
