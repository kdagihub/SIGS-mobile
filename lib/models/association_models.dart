import 'territoire_models.dart';

class Association {
  final String code;
  final String sigleAs;
  final String libelleAs;
  final String? localite;
  final String localiteNom;
  final String? federation;
  final String federationNom;
  final String? presidentAs;
  final String? contactAs;
  final bool estAgree;
  final String? logoUrl;

  // Detail-only fields
  final String? siegeSocial;
  final String? adresseAs;
  final String? emailAs;
  final String? sitewebAs;
  final String? dateCreationAs;
  final String? statutJuridiqueAs;
  final String? typeAssociation;
  final String typeAssociationNom;
  final String? recepisseUrl;
  final String? agrementUrl;

  const Association({
    required this.code,
    required this.sigleAs,
    required this.libelleAs,
    this.localite,
    this.localiteNom = '',
    this.federation,
    this.federationNom = '',
    this.presidentAs,
    this.contactAs,
    this.estAgree = false,
    this.logoUrl,
    this.siegeSocial,
    this.adresseAs,
    this.emailAs,
    this.sitewebAs,
    this.dateCreationAs,
    this.statutJuridiqueAs,
    this.typeAssociation,
    this.typeAssociationNom = '',
    this.recepisseUrl,
    this.agrementUrl,
  });

  factory Association.fromJson(Map<String, dynamic> j) => Association(
        code: j['code'] as String? ?? '',
        sigleAs: j['sigle_as'] as String? ?? '',
        libelleAs: j['libelle_as'] as String? ?? '',
        localite: j['localite'] as String?,
        localiteNom: j['localite_nom'] as String? ?? '',
        federation: j['federation'] as String?,
        federationNom: j['federation_nom'] as String? ?? '',
        presidentAs: j['president_as'] as String?,
        contactAs: j['contact_as'] as String?,
        estAgree: j['est_agree'] as bool? ?? false,
        logoUrl: j['logo_url'] as String?,
        siegeSocial: j['siege_social'] as String?,
        adresseAs: j['adresse_as'] as String?,
        emailAs: j['email_as'] as String?,
        sitewebAs: j['siteweb_as'] as String?,
        dateCreationAs: j['date_creation_as'] as String?,
        statutJuridiqueAs: j['statut_juridique_as'] as String?,
        typeAssociation: j['type_association'] as String?,
        typeAssociationNom: j['type_association_nom'] as String? ?? '',
        recepisseUrl: j['recepisse_url'] as String?,
        agrementUrl: j['agrement_url'] as String?,
      );
}

class AssociationStats {
  final int total;
  final int agreees;
  final int nonAgreees;
  final int withFederation;

  const AssociationStats({
    this.total = 0,
    this.agreees = 0,
    this.nonAgreees = 0,
    this.withFederation = 0,
  });

  factory AssociationStats.fromJson(Map<String, dynamic> j) =>
      AssociationStats(
        total: (j['total'] as num?)?.toInt() ?? 0,
        agreees: (j['agreees'] as num?)?.toInt() ?? 0,
        nonAgreees: (j['non_agreees'] as num?)?.toInt() ?? 0,
        withFederation: (j['with_federation'] as num?)?.toInt() ?? 0,
      );
}

class AssociationFormOptions {
  final List<Map<String, dynamic>> localites;
  final List<Map<String, dynamic>> federations;
  final List<Map<String, dynamic>> typesAssociation;

  const AssociationFormOptions({
    this.localites = const [],
    this.federations = const [],
    this.typesAssociation = const [],
  });

  factory AssociationFormOptions.fromJson(Map<String, dynamic> j) =>
      AssociationFormOptions(
        localites: (j['localites'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
        federations: (j['federations'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
        typesAssociation: (j['types_association'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      );
}

typedef PaginatedAssociations = PaginatedResponse<Association>;
