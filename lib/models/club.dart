class Club {
  final String? code;
  final String? sigle;
  final String? libelle;

  const Club({this.code, this.sigle, this.libelle});

  factory Club.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Club();
    return Club(
      code: json['code'] as String?,
      sigle: json['sigle'] as String?,
      libelle: json['libelle'] as String?,
    );
  }

  String get displayName => sigle ?? libelle ?? code ?? '';
}
