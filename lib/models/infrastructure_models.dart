import 'territoire_models.dart';

class Infrastructure {
  final String code;
  final String libelleIs;
  final String? localite;
  final String localiteNom;
  final String? typeInfrastructure;
  final String typeInfrastructureNom;
  final int nbPlacesIs;
  final String? etatInfrastructure;
  final String? photoUrl;
  // Detail-only fields
  final String? gpsIs;
  final String? dateCreationIs;
  final String? dateInaugurationIs;
  final int? dureeVieIs;
  final List<String> disciplinesNoms;
  final List<String> disciplinePratiquee;
  final String? structureGestion;
  final String? contactStructureGestion;
  final bool estSocioEducatif;

  const Infrastructure({
    required this.code,
    required this.libelleIs,
    this.localite,
    this.localiteNom = '',
    this.typeInfrastructure,
    this.typeInfrastructureNom = '',
    this.nbPlacesIs = 0,
    this.etatInfrastructure,
    this.photoUrl,
    this.gpsIs,
    this.dateCreationIs,
    this.dateInaugurationIs,
    this.dureeVieIs,
    this.disciplinesNoms = const [],
    this.disciplinePratiquee = const [],
    this.structureGestion,
    this.contactStructureGestion,
    this.estSocioEducatif = false,
  });

  factory Infrastructure.fromJson(Map<String, dynamic> j) => Infrastructure(
        code: j['code'] as String? ?? '',
        libelleIs: j['libelle_is'] as String? ?? '',
        localite: j['localite'] as String?,
        localiteNom: j['localite_nom'] as String? ?? '',
        typeInfrastructure: j['type_infrastructure'] as String?,
        typeInfrastructureNom: j['type_infrastructure_nom'] as String? ?? '',
        nbPlacesIs: (j['nb_places_is'] as num?)?.toInt() ?? 0,
        etatInfrastructure: j['etat_infrastructure'] as String?,
        photoUrl: j['photo_url'] as String?,
        gpsIs: j['gps_is'] as String?,
        dateCreationIs: j['date_creation_is'] as String?,
        dateInaugurationIs: j['date_inauguration_is'] as String?,
        dureeVieIs: (j['duree_vie_is'] as num?)?.toInt(),
        disciplinesNoms: (j['disciplines_noms'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        disciplinePratiquee: (j['discipline_pratiquee'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        structureGestion: j['structure_gestion'] as String?,
        contactStructureGestion: j['contact_structure_gestion'] as String?,
        estSocioEducatif: j['est_socio_educatif'] as bool? ?? false,
      );
}

class InfrastructureStats {
  final int total;
  final int bon;
  final int horsUsage;
  final int enRehab;
  final int withGps;
  final int socioEducatif;
  final int totalPlaces;

  const InfrastructureStats({
    this.total = 0,
    this.bon = 0,
    this.horsUsage = 0,
    this.enRehab = 0,
    this.withGps = 0,
    this.socioEducatif = 0,
    this.totalPlaces = 0,
  });

  factory InfrastructureStats.fromJson(Map<String, dynamic> j) =>
      InfrastructureStats(
        total: (j['total'] as num?)?.toInt() ?? 0,
        bon: (j['bon'] as num?)?.toInt() ?? 0,
        horsUsage: (j['hors_usage'] as num?)?.toInt() ?? 0,
        enRehab: (j['en_rehab'] as num?)?.toInt() ?? 0,
        withGps: (j['with_gps'] as num?)?.toInt() ?? 0,
        socioEducatif: (j['socio_educatif'] as num?)?.toInt() ?? 0,
        totalPlaces: (j['total_places'] as num?)?.toInt() ?? 0,
      );
}

class InfrastructureFormOptions {
  final List<Map<String, dynamic>> localites;
  final List<Map<String, dynamic>> typesInfrastructure;
  final List<Map<String, dynamic>> disciplines;

  const InfrastructureFormOptions({
    this.localites = const [],
    this.typesInfrastructure = const [],
    this.disciplines = const [],
  });

  factory InfrastructureFormOptions.fromJson(Map<String, dynamic> j) =>
      InfrastructureFormOptions(
        localites: (j['localites'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
        typesInfrastructure: (j['types_infrastructure'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
        disciplines: (j['disciplines'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      );
}

/// Réutilise `PaginatedResponse` depuis territoire_models.dart
typedef PaginatedInfrastructures = PaginatedResponse<Infrastructure>;
