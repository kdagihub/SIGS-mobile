class EntityInfo {
  final String? code;
  final String? name;
  final String? type;

  const EntityInfo({this.code, this.name, this.type});

  factory EntityInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EntityInfo();
    return EntityInfo(
      code: json['code'] as String?,
      name: json['name'] as String?,
      type: json['type'] as String?,
    );
  }
}

class AuthUser {
  final String email;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String? contact;
  final String? code;
  final String? group;
  final String? groupCode;
  final List<String> permissions;
  final bool isStaff;
  final bool isSuperuser;
  final bool isActive;
  final bool entityAdmin;
  final EntityInfo? entityInfo;

  final Map<String, dynamic>? directionRegionaleInfo;
  final Map<String, dynamic>? directionDepartementaleInfo;
  final Map<String, dynamic>? federationInfo;
  final Map<String, dynamic>? ligueInfo;
  final Map<String, dynamic>? clubInfo;
  final Map<String, dynamic>? associationSportiveInfo;
  final Map<String, dynamic>? userGroupInfo;
  final String? lastLogin;

  const AuthUser({
    required this.email,
    required this.fullName,
    this.firstName,
    this.lastName,
    this.contact,
    this.code,
    this.group,
    this.groupCode,
    this.permissions = const [],
    this.isStaff = false,
    this.isSuperuser = false,
    this.isActive = true,
    this.entityAdmin = false,
    this.entityInfo,
    this.directionRegionaleInfo,
    this.directionDepartementaleInfo,
    this.federationInfo,
    this.ligueInfo,
    this.clubInfo,
    this.associationSportiveInfo,
    this.userGroupInfo,
    this.lastLogin,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final userGroupInfo = json['user_group_info'] as Map<String, dynamic>?;

    final groupCode = json['group_code'] as String?
        ?? userGroupInfo?['code'] as String?;

    final group = json['group'] as String?
        ?? userGroupInfo?['libelle'] as String?;

    final firstName = json['first_name'] as String?;
    final lastName = json['last_name'] as String?;
    final fullName = json['full_name'] as String?
        ?? '${ firstName ?? ''} ${lastName ?? ''}'.trim();

    return AuthUser(
      email: json['email'] as String? ?? '',
      fullName: fullName.isNotEmpty ? fullName : '',
      firstName: firstName,
      lastName: lastName,
      contact: json['contact'] as String?,
      code: json['code'] as String?,
      group: group,
      groupCode: groupCode,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isStaff: json['is_staff'] as bool? ?? false,
      isSuperuser: json['is_superuser'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      entityAdmin: json['entity_admin'] as bool? ?? false,
      entityInfo: json['entity_info'] != null
          ? EntityInfo.fromJson(json['entity_info'] as Map<String, dynamic>)
          : null,
      directionRegionaleInfo:
          json['direction_regionale_info'] as Map<String, dynamic>?,
      directionDepartementaleInfo:
          json['direction_departementale_info'] as Map<String, dynamic>?,
      federationInfo: json['federation_info'] as Map<String, dynamic>?,
      ligueInfo: json['ligue_info'] as Map<String, dynamic>?,
      clubInfo: json['club_info'] as Map<String, dynamic>?,
      associationSportiveInfo:
          json['association_sportive_info'] as Map<String, dynamic>?,
      userGroupInfo: userGroupInfo,
      lastLogin: json['last_login'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'full_name': fullName,
        'first_name': firstName,
        'last_name': lastName,
        'contact': contact,
        'code': code,
        'group': group,
        'group_code': groupCode,
        'permissions': permissions,
        'is_staff': isStaff,
        'is_superuser': isSuperuser,
        'is_active': isActive,
        'entity_admin': entityAdmin,
      };

  String? get entityType {
    if (groupCode == 'GUSER-07') return 'federation';
    if (groupCode == 'GUSER-08') return 'ligue';
    if (groupCode == 'GUSER-09') return 'club';
    if (groupCode == 'GUSER-05') return 'direction_regionale';
    if (groupCode == 'GUSER-06') return 'direction_departementale';
    if (groupCode == 'GUSER-10') return 'association_sportive';
    return null;
  }

  String get entityTypeLabel {
    const labels = {
      'federation': 'Fédération',
      'ligue': 'Ligue',
      'club': 'Club',
      'direction_regionale': 'Direction Régionale',
      'direction_departementale': 'Direction Départementale',
      'association_sportive': 'Association Sportive',
    };
    return labels[entityType] ?? 'Entité';
  }

  Map<String, dynamic>? get currentEntityInfo {
    switch (entityType) {
      case 'federation':
        return federationInfo;
      case 'ligue':
        return ligueInfo;
      case 'club':
        return clubInfo;
      case 'direction_regionale':
        return directionRegionaleInfo;
      case 'direction_departementale':
        return directionDepartementaleInfo;
      case 'association_sportive':
        return associationSportiveInfo;
      default:
        return null;
    }
  }

  String get roleLabel {
    if (entityAdmin) {
      const adminLabels = {
        'federation': 'Administrateur Fédération',
        'ligue': 'Administrateur Ligue',
        'club': 'Administrateur Club',
        'direction_regionale': 'Administrateur Direction Régionale',
        'direction_departementale': 'Administrateur Direction Départementale',
        'association_sportive': 'Administrateur Association Sportive',
      };
      return adminLabels[entityType] ?? 'Administrateur';
    }
    const memberLabels = {
      'federation': 'Membre Fédération',
      'ligue': 'Membre Ligue',
      'club': 'Membre Club',
      'direction_regionale': 'Membre Direction Régionale',
      'direction_departementale': 'Membre Direction Départementale',
      'association_sportive': 'Membre Association Sportive',
    };
    return memberLabels[entityType] ?? 'Membre';
  }
}

class AuthTokens {
  final String access;
  final String refresh;

  const AuthTokens({required this.access, required this.refresh});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
    );
  }
}
