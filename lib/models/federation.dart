import '../core/constants.dart';

class Federation {
  final String? code;
  final String? sigle;
  final String? libelle;
  final String? logo;

  const Federation({this.code, this.sigle, this.libelle, this.logo});

  factory Federation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Federation();
    return Federation(
      code: json['code'] as String?,
      sigle: json['sigle'] as String?,
      libelle: json['libelle'] as String?,
      logo: AppConstants.toAbsoluteUrl(json['logo'] as String?),
    );
  }

  String get displayName => sigle ?? libelle ?? code ?? '';
}
