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
