import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository.dart';
import '../models/auth_user.dart';
import 'recent_searches_provider.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final bool sessionExpired;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.sessionExpired = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
    bool? sessionExpired,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _tryRestoreSession();
  }

  void _tryRestoreSession() {
    final session = _repo.restoreSession();
    if (session.user != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
      );
      _refreshInBackground();
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      await _repo.refreshAccessToken();
    } on SessionExpiredException {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        sessionExpired: true,
        errorMessage: 'Votre session a expiré. Veuillez vous reconnecter.',
      );
    } catch (_) {
      // Network error on startup — keep the local session active
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final result = await _repo.login(email, password);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } on DioException catch (e) {
      String message;
      if (e.response?.statusCode == 401) {
        message = 'Email ou mot de passe incorrect.';
      } else if (e.response?.statusCode == 429) {
        message = 'Trop de tentatives. Veuillez patienter.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        message = 'Impossible de joindre le serveur. Vérifiez votre connexion.';
      } else {
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          message = data['detail'].toString();
        } else {
          message = 'Erreur de connexion. Veuillez réessayer.';
        }
      }
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Erreur inattendue. Veuillez réessayer.',
      );
    }
  }

  /// Re-fetch full profile from /auth/me/ and update state
  Future<AuthUser> refreshProfile() async {
    final user = await _repo.fetchProfile();
    state = state.copyWith(user: user);
    return user;
  }

  /// Update personal info (first_name, last_name, email, contact)
  Future<AuthUser> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? contact,
  }) async {
    final user = await _repo.updateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      contact: contact,
    );
    state = state.copyWith(user: user);
    return user;
  }

  /// Update entity info (DR, DD, federation, etc.)
  Future<AuthUser> updateEntityInfo(Map<String, dynamic> entityData) async {
    final user = await _repo.updateEntityInfo(entityData);
    state = state.copyWith(user: user);
    return user;
  }

  /// Get PIN status
  Future<Map<String, dynamic>> getPinStatus() => _repo.getPinStatus();

  /// Create security PIN
  Future<void> createPin({
    required String newPin,
    required String confirmPin,
    required String currentPassword,
  }) => _repo.createPin(
        newPin: newPin,
        confirmPin: confirmPin,
        currentPassword: currentPassword,
      );

  /// Update security PIN
  Future<void> updatePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) => _repo.updatePin(
        currentPin: currentPin,
        newPin: newPin,
        confirmPin: confirmPin,
      );

  /// Change password with PIN
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
    String? pin,
  }) async {
    await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
      pin: pin,
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepository(prefs);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
