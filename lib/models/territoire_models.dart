/// Paginated API response wrapper
class PaginatedResponse<T> {
  final int count;
  final List<T> results;

  const PaginatedResponse({required this.count, required this.results});
}

// ──────────────────────────────────────────────────────────────
// Direction Départementale
// ──────────────────────────────────────────────────────────────

class Departement {
  final String code;
  final String libelleDd;
  final String? responsableDd;
  final String? contactDd;
  final String? emailDd;
  final String? coordonneesGps;
  final bool isActive;
  final String? directionRegionaleNom;

  const Departement({
    required this.code,
    required this.libelleDd,
    this.responsableDd,
    this.contactDd,
    this.emailDd,
    this.coordonneesGps,
    this.isActive = true,
    this.directionRegionaleNom,
  });

  factory Departement.fromJson(Map<String, dynamic> j) => Departement(
        code: j['code'] as String? ?? '',
        libelleDd: j['libelle_dd'] as String? ?? '',
        responsableDd: j['responsable_dd'] as String?,
        contactDd: j['contact_dd'] as String?,
        emailDd: j['email_dd'] as String?,
        coordonneesGps: j['coordonnees_gps'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        directionRegionaleNom: j['direction_regionale_nom'] as String?,
      );

  Map<String, dynamic> toWriteJson() => {
        'libelle_dd': libelleDd,
        'responsable_dd': responsableDd ?? '',
        'contact_dd': contactDd ?? '',
        'email_dd': emailDd ?? '',
        'coordonnees_gps': coordonneesGps ?? '',
        'is_active': isActive,
      };
}

class DepartementStats {
  final int total;
  final int active;
  final int inactive;
  final int withGps;

  const DepartementStats({
    this.total = 0,
    this.active = 0,
    this.inactive = 0,
    this.withGps = 0,
  });

  factory DepartementStats.fromJson(Map<String, dynamic> j) =>
      DepartementStats(
        total: (j['total'] as num?)?.toInt() ?? 0,
        active: (j['active'] as num?)?.toInt() ?? 0,
        inactive: (j['inactive'] as num?)?.toInt() ?? 0,
        withGps: (j['with_gps'] as num?)?.toInt() ?? 0,
      );
}

// ──────────────────────────────────────────────────────────────
// Localité
// ──────────────────────────────────────────────────────────────

class Localite {
  final String code;
  final String libelleLocalite;
  final String? coordonneesGps;
  final String? directionRegionale; // FK code
  final String? directionRegionaleNom;
  final String? directionDepartement; // FK code
  final String? directionDepartementNom;
  final int? nbInfrastructures;
  final int? nbAssociations;

  const Localite({
    required this.code,
    required this.libelleLocalite,
    this.coordonneesGps,
    this.directionRegionale,
    this.directionRegionaleNom,
    this.directionDepartement,
    this.directionDepartementNom,
    this.nbInfrastructures,
    this.nbAssociations,
  });

  factory Localite.fromJson(Map<String, dynamic> j) => Localite(
        code: j['code'] as String? ?? '',
        libelleLocalite: j['libelle_localite'] as String? ?? '',
        coordonneesGps: j['coordonnees_gps'] as String?,
        directionRegionale: j['direction_regionale'] as String?,
        directionRegionaleNom: j['direction_regionale_nom'] as String?,
        directionDepartement: j['direction_departement'] as String?,
        directionDepartementNom: j['direction_departement_nom'] as String?,
        nbInfrastructures: (j['nb_infrastructures'] as num?)?.toInt(),
        nbAssociations: (j['nb_associations'] as num?)?.toInt(),
      );
}

class LocaliteStats {
  final int total;
  final int withGps;
  final int withoutGps;
  final int underDd;

  const LocaliteStats({
    this.total = 0,
    this.withGps = 0,
    this.withoutGps = 0,
    this.underDd = 0,
  });

  factory LocaliteStats.fromJson(Map<String, dynamic> j) => LocaliteStats(
        total: (j['total'] as num?)?.toInt() ?? 0,
        withGps: (j['with_gps'] as num?)?.toInt() ?? 0,
        withoutGps: (j['without_gps'] as num?)?.toInt() ?? 0,
        underDd: (j['under_dd'] as num?)?.toInt() ?? 0,
      );
}

/// Options de formulaire renvoyées par l'API form-options
class LocaliteFormOptions {
  final List<Map<String, dynamic>> directionsRegionales;
  final List<Map<String, dynamic>> directionsDepartementales;
  final Map<String, dynamic> defaults;

  const LocaliteFormOptions({
    this.directionsRegionales = const [],
    this.directionsDepartementales = const [],
    this.defaults = const {},
  });

  factory LocaliteFormOptions.fromJson(Map<String, dynamic> j) =>
      LocaliteFormOptions(
        directionsRegionales:
            (j['directions_regionales'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        directionsDepartementales:
            (j['directions_departementales'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        defaults: j['defaults'] as Map<String, dynamic>? ?? {},
      );
}
