import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_user.dart';
import '../api_client.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance.dio;
  final SharedPreferences _prefs;

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _userKey = 'auth_user_json';

  AuthRepository(this._prefs);

  /// JWT login via /api/auth/token/
  Future<({AuthUser user, AuthTokens tokens})> login(
    String email,
    String password,
  ) async {
    final response = await _dio.post(
      '/auth/token/',
      data: {'email': email, 'password': password},
    );

    final data = response.data as Map<String, dynamic>;
    final tokens = AuthTokens.fromJson(data);
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);

    await _persistSession(tokens, user);
    _applyAuthHeader(tokens.access);

    return (user: user, tokens: tokens);
  }

  /// Refresh access token
  Future<String> refreshAccessToken() async {
    final refreshToken = _prefs.getString(_refreshKey);
    if (refreshToken == null) throw SessionExpiredException();

    try {
      final response = await _dio.post(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      final newAccess = data['access'] as String;
      final newRefresh = data['refresh'] as String? ?? refreshToken;

      _prefs.setString(_accessKey, newAccess);
      _prefs.setString(_refreshKey, newRefresh);
      _applyAuthHeader(newAccess);

      return newAccess;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearSession();
        throw SessionExpiredException();
      }
      rethrow;
    }
  }

  /// GET /api/auth/me/
  Future<AuthUser> fetchProfile() async {
    final response = await _dio.get('/auth/me/');
    return AuthUser.fromJson(response.data as Map<String, dynamic>);
  }

  /// Restore session from stored tokens (app startup)
  ({AuthUser? user, String? accessToken}) restoreSession() {
    final access = _prefs.getString(_accessKey);
    final userJson = _prefs.getString(_userKey);

    if (access == null || userJson == null) return (user: null, accessToken: null);

    _applyAuthHeader(access);

    try {
      final decoded = Uri.splitQueryString(userJson);
      final user = AuthUser(
        email: decoded['email'] ?? '',
        fullName: decoded['full_name'] ?? '',
        code: decoded['code'],
        group: decoded['group'],
        groupCode: decoded['group_code'],
        isStaff: decoded['is_staff'] == 'true',
        isSuperuser: decoded['is_superuser'] == 'true',
      );
      return (user: user, accessToken: access);
    } catch (_) {
      return (user: null, accessToken: null);
    }
  }

  Future<void> logout() async {
    await clearSession();
  }

  Future<void> clearSession() async {
    _prefs.remove(_accessKey);
    _prefs.remove(_refreshKey);
    _prefs.remove(_userKey);
    _dio.options.headers.remove('Authorization');
  }

  bool get hasStoredTokens => _prefs.getString(_accessKey) != null;

  /// Verify reset credentials for entity users (email + entity_code + pin)
  Future<({String token, int expiresIn})> verifyResetCredentials({
    required String email,
    required String entityCode,
    required String pin,
  }) async {
    final response = await _dio.post(
      '/auth/verify-reset-credentials/',
      data: {
        'email': email,
        'entity_code': entityCode.toUpperCase(),
        'pin': pin,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      expiresIn: (data['expires_in'] as num?)?.toInt() ?? 900,
    );
  }

  /// Verify reset credentials for admin users (email + pin only)
  Future<({String token, int expiresIn})> verifyAdminResetCredentials({
    required String email,
    required String pin,
  }) async {
    final response = await _dio.post(
      '/auth/verify-admin-reset-credentials/',
      data: {'email': email, 'pin': pin},
    );
    final data = response.data as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      expiresIn: (data['expires_in'] as num?)?.toInt() ?? 900,
    );
  }

  /// Reset password with temporary token
  Future<void> resetPasswordWithToken({
    required String token,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _dio.post(
      '/auth/reset-password-with-token/',
      data: {
        'token': token,
        'new_password': newPassword,
        'confirm_new_password': confirmNewPassword,
      },
    );
  }

  Future<void> _persistSession(AuthTokens tokens, AuthUser user) async {
    _prefs.setString(_accessKey, tokens.access);
    _prefs.setString(_refreshKey, tokens.refresh);
    _prefs.setString(_userKey, Uri(queryParameters: {
      'email': user.email,
      'full_name': user.fullName,
      'code': user.code ?? '',
      'group': user.group ?? '',
      'group_code': user.groupCode ?? '',
      'is_staff': user.isStaff.toString(),
      'is_superuser': user.isSuperuser.toString(),
    }).query);
  }

  void _applyAuthHeader(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}

class SessionExpiredException implements Exception {
  @override
  String toString() => 'Session expirée. Veuillez vous reconnecter.';
}

class InvalidCredentialsException implements Exception {
  final String message;
  InvalidCredentialsException([this.message = 'Email ou mot de passe incorrect.']);
  @override
  String toString() => message;
}
