import 'territoire_models.dart';

class Evenement {
  final String code;
  final String nom;
  final String typeEvenement;
  final String? discipline;
  final String disciplineNom;
  final String dateHeureDebut;
  final String dateHeureFin;
  final String? infrastructureUtilisee;
  final String infrastructureNom;
  final String? organisateur;
  final int? nombreParticipants;
  final String? imageUrl;
  // Detail-only
  final String? federation;
  final String federationNom;
  final String? partenaires;
  final String? billetterie;
  final double? budget;
  final String? anneeSportive;
  final String? documentAnnexeUrl;

  const Evenement({
    required this.code,
    required this.nom,
    required this.typeEvenement,
    this.discipline,
    this.disciplineNom = '',
    required this.dateHeureDebut,
    required this.dateHeureFin,
    this.infrastructureUtilisee,
    this.infrastructureNom = '',
    this.organisateur,
    this.nombreParticipants,
    this.imageUrl,
    this.federation,
    this.federationNom = '',
    this.partenaires,
    this.billetterie,
    this.budget,
    this.anneeSportive,
    this.documentAnnexeUrl,
  });

  factory Evenement.fromJson(Map<String, dynamic> j) => Evenement(
        code: j['code'] as String? ?? '',
        nom: j['nom'] as String? ?? '',
        typeEvenement: j['type_evenement'] as String? ?? '',
        discipline: j['discipline'] as String?,
        disciplineNom: j['discipline_nom'] as String? ?? '',
        dateHeureDebut: j['date_heure_debut'] as String? ?? '',
        dateHeureFin: j['date_heure_fin'] as String? ?? '',
        infrastructureUtilisee: j['infrastructure_utilisee'] as String?,
        infrastructureNom: j['infrastructure_nom'] as String? ?? '',
        organisateur: j['organisateur'] as String?,
        nombreParticipants: (j['nombre_participants'] as num?)?.toInt(),
        imageUrl: j['image_url'] as String?,
        federation: j['federation'] as String?,
        federationNom: j['federation_nom'] as String? ?? '',
        partenaires: j['partenaires'] as String?,
        billetterie: j['billetterie'] as String?,
        budget: (j['budget'] as num?)?.toDouble(),
        anneeSportive: j['annee_sportive'] as String?,
        documentAnnexeUrl: j['document_annexe_url'] as String?,
      );
}

class EvenementStats {
  final int total;
  final int withFederation;
  final int withInfra;
  final int totalParticipants;
  final List<Map<String, dynamic>> byType;
  final List<Map<String, dynamic>> byDiscipline;

  const EvenementStats({
    this.total = 0,
    this.withFederation = 0,
    this.withInfra = 0,
    this.totalParticipants = 0,
    this.byType = const [],
    this.byDiscipline = const [],
  });

  factory EvenementStats.fromJson(Map<String, dynamic> j) => EvenementStats(
        total: (j['total'] as num?)?.toInt() ?? 0,
        withFederation: (j['with_federation'] as num?)?.toInt() ?? 0,
        withInfra: (j['with_infra'] as num?)?.toInt() ?? 0,
        totalParticipants: (j['total_participants'] as num?)?.toInt() ?? 0,
        byType: (j['by_type'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        byDiscipline:
            (j['by_discipline'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      );
}

class EvenementFormOptions {
  final List<Map<String, dynamic>> infrastructures;
  final List<Map<String, dynamic>> disciplines;
  final List<Map<String, dynamic>> federations;
  final List<Map<String, dynamic>> anneesSportives;
  final List<Map<String, dynamic>> typesEvenement;

  const EvenementFormOptions({
    this.infrastructures = const [],
    this.disciplines = const [],
    this.federations = const [],
    this.anneesSportives = const [],
    this.typesEvenement = const [],
  });

  factory EvenementFormOptions.fromJson(Map<String, dynamic> j) =>
      EvenementFormOptions(
        infrastructures: (j['infrastructures'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
        disciplines:
            (j['disciplines'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        federations:
            (j['federations'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        anneesSportives: (j['annees_sportives'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
        typesEvenement: (j['types_evenement'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      );
}

typedef PaginatedEvenements = PaginatedResponse<Evenement>;
