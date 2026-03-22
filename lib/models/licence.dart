import 'federation.dart';
import 'club.dart';

class LicenceSegments {
  final String? prefixe;
  final String? categorie;
  final String? annee;
  final String? sequentiel;
  final String? verification;

  const LicenceSegments({
    this.prefixe,
    this.categorie,
    this.annee,
    this.sequentiel,
    this.verification,
  });

  factory LicenceSegments.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LicenceSegments();
    return LicenceSegments(
      prefixe: json['prefixe']?.toString(),
      categorie: json['categorie']?.toString(),
      annee: json['annee']?.toString(),
      sequentiel: json['sequentiel']?.toString(),
      verification: json['verification']?.toString(),
    );
  }
}

class CodeLibelle {
  final String? code;
  final String? libelle;

  const CodeLibelle({this.code, this.libelle});

  factory CodeLibelle.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CodeLibelle();
    return CodeLibelle(
      code: json['code'] as String?,
      libelle: json['libelle'] as String?,
    );
  }
}

class Licence {
  final String code;
  final String? numero;
  final LicenceSegments segments;
  final String statut;
  final String? statutDisplay;
  final bool estActive;
  final bool estExpiree;
  final String? formatLicence;
  final String? formatDisplay;
  final bool aCarteNumerique;
  final CodeLibelle typeLicence;
  final CodeLibelle categorie;
  final CodeLibelle anneeSportive;
  final Federation federation;
  final Club? club;
  final String? dateDelivrance;
  final String? dateExpiration;

  const Licence({
    required this.code,
    this.numero,
    this.segments = const LicenceSegments(),
    this.statut = '',
    this.statutDisplay,
    this.estActive = false,
    this.estExpiree = false,
    this.formatLicence,
    this.formatDisplay,
    this.aCarteNumerique = false,
    this.typeLicence = const CodeLibelle(),
    this.categorie = const CodeLibelle(),
    this.anneeSportive = const CodeLibelle(),
    this.federation = const Federation(),
    this.club,
    this.dateDelivrance,
    this.dateExpiration,
  });

  factory Licence.fromJson(Map<String, dynamic> json) {
    return Licence(
      code: json['code'] as String? ?? '',
      numero: json['numero'] as String?,
      segments: LicenceSegments.fromJson(
        json['segments'] as Map<String, dynamic>?,
      ),
      statut: json['statut'] as String? ?? '',
      statutDisplay: json['statut_display'] as String?,
      estActive: json['est_active'] as bool? ?? false,
      estExpiree: json['est_expiree'] as bool? ?? false,
      formatLicence: json['format_licence'] as String?,
      formatDisplay: json['format_display'] as String?,
      aCarteNumerique: json['a_carte_numerique'] as bool? ?? false,
      typeLicence: CodeLibelle.fromJson(
        json['type_licence'] as Map<String, dynamic>?,
      ),
      categorie: CodeLibelle.fromJson(
        json['categorie'] as Map<String, dynamic>?,
      ),
      anneeSportive: CodeLibelle.fromJson(
        json['annee_sportive'] as Map<String, dynamic>?,
      ),
      federation: Federation.fromJson(
        json['federation'] as Map<String, dynamic>?,
      ),
      club: json['club'] != null
          ? Club.fromJson(json['club'] as Map<String, dynamic>)
          : null,
      dateDelivrance: json['date_delivrance'] as String?,
      dateExpiration: json['date_expiration'] as String?,
    );
  }

  String get typeLicenceDisplay => typeLicence.libelle ?? typeLicence.code ?? '';
  String get categorieDisplay => categorie.libelle ?? categorie.code ?? '';
  String get anneeSportiveDisplay =>
      anneeSportive.libelle ?? anneeSportive.code ?? '';
}
