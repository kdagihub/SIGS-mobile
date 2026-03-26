class DrddTerritoire {
  final String role;
  final String code;
  final String nom;

  const DrddTerritoire({
    required this.role,
    required this.code,
    required this.nom,
  });

  factory DrddTerritoire.fromJson(Map<String, dynamic> json) {
    return DrddTerritoire(
      role: json['role'] as String? ?? 'admin',
      code: json['code'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
    );
  }

  bool get isDR => role == 'dr';
  bool get isDD => role == 'dd';
  bool get isAdmin => role == 'admin';

  String get roleLabel {
    switch (role) {
      case 'dr':
        return 'Direction Régionale';
      case 'dd':
        return 'Direction Départementale';
      default:
        return 'Administration';
    }
  }
}

class DrddStats {
  final int departements;
  final int localites;
  final int infrastructures;
  final int associations;
  final int evenements;

  const DrddStats({
    this.departements = 0,
    this.localites = 0,
    this.infrastructures = 0,
    this.associations = 0,
    this.evenements = 0,
  });

  factory DrddStats.fromJson(Map<String, dynamic> json) {
    return DrddStats(
      departements: (json['departements'] as num?)?.toInt() ?? 0,
      localites: (json['localites'] as num?)?.toInt() ?? 0,
      infrastructures: (json['infrastructures'] as num?)?.toInt() ?? 0,
      associations: (json['associations'] as num?)?.toInt() ?? 0,
      evenements: (json['evenements'] as num?)?.toInt() ?? 0,
    );
  }
}

class DrddEvenementRecent {
  final String code;
  final String nom;
  final String? typeEvenement;
  final DateTime? dateHeureDebut;
  final String? infrastructureNom;
  final String? disciplineNom;

  const DrddEvenementRecent({
    required this.code,
    required this.nom,
    this.typeEvenement,
    this.dateHeureDebut,
    this.infrastructureNom,
    this.disciplineNom,
  });

  factory DrddEvenementRecent.fromJson(Map<String, dynamic> json) {
    return DrddEvenementRecent(
      code: json['code'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      typeEvenement: json['type_evenement'] as String?,
      dateHeureDebut: json['date_heure_debut'] != null
          ? DateTime.tryParse(json['date_heure_debut'].toString())
          : null,
      infrastructureNom:
          json['infrastructure_utilisee__libelle_is'] as String?,
      disciplineNom: json['discipline__libelle_disc'] as String?,
    );
  }
}

/// Feed mixte d'activites recentes (departements, infras, associations, evenements)
class DrddActiviteRecente {
  final String type;
  final String label;
  final String code;
  final DateTime? date;
  final String? localite;
  final String? discipline;

  const DrddActiviteRecente({
    required this.type,
    required this.label,
    required this.code,
    this.date,
    this.localite,
    this.discipline,
  });

  factory DrddActiviteRecente.fromJson(Map<String, dynamic> json) {
    return DrddActiviteRecente(
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      code: json['code'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      localite: json['localite'] as String?,
      discipline: json['discipline'] as String?,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'departement':
        return 'Département';
      case 'infrastructure':
        return 'Infrastructure';
      case 'association':
        return 'Association';
      case 'evenement':
        return 'Événement';
      default:
        return type;
    }
  }
}
