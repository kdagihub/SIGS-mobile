import 'federation.dart';
import 'club.dart';

class Athlete {
  final String msNius;
  final String nom;
  final String prenoms;
  final String? photo;
  final String? dateNaissance;
  final String? sexe;
  final String? nationalite;
  final String? discipline;
  final Federation federation;
  final Club? club;

  const Athlete({
    required this.msNius,
    required this.nom,
    required this.prenoms,
    this.photo,
    this.dateNaissance,
    this.sexe,
    this.nationalite,
    this.discipline,
    this.federation = const Federation(),
    this.club,
  });

  factory Athlete.fromJson(Map<String, dynamic> json) {
    return Athlete(
      msNius: json['ms_nius'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenoms: json['prenoms'] as String? ?? '',
      photo: json['photo'] as String?,
      dateNaissance: json['date_naissance'] as String?,
      sexe: json['sexe'] as String?,
      nationalite: json['nationalite'] as String?,
      discipline: json['discipline'] as String?,
      federation: Federation.fromJson(
        json['federation'] as Map<String, dynamic>?,
      ),
      club: json['club'] != null
          ? Club.fromJson(json['club'] as Map<String, dynamic>)
          : null,
    );
  }

  String get fullName => '$prenoms $nom'.trim();

  String get initials {
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
