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
  final String? code;
  final String? group;
  final String? groupCode;
  final List<String> permissions;
  final bool isStaff;
  final bool isSuperuser;
  final EntityInfo? entityInfo;

  const AuthUser({
    required this.email,
    required this.fullName,
    this.code,
    this.group,
    this.groupCode,
    this.permissions = const [],
    this.isStaff = false,
    this.isSuperuser = false,
    this.entityInfo,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      code: json['code'] as String?,
      group: json['group'] as String?,
      groupCode: json['group_code'] as String?,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isStaff: json['is_staff'] as bool? ?? false,
      isSuperuser: json['is_superuser'] as bool? ?? false,
      entityInfo: json['entity_info'] != null
          ? EntityInfo.fromJson(json['entity_info'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'full_name': fullName,
        'code': code,
        'group': group,
        'group_code': groupCode,
        'permissions': permissions,
        'is_staff': isStaff,
        'is_superuser': isSuperuser,
      };
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
