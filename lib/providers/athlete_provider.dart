import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/athlete_repository.dart';

enum AthleteSearchStatus { idle, loading, success, error }

class AthleteSearchState {
  final AthleteSearchStatus status;
  final AthletePortailResult? result;
  final String? errorMessage;
  final String? lastSearchedNius;

  const AthleteSearchState({
    this.status = AthleteSearchStatus.idle,
    this.result,
    this.errorMessage,
    this.lastSearchedNius,
  });

  AthleteSearchState copyWith({
    AthleteSearchStatus? status,
    AthletePortailResult? result,
    String? errorMessage,
    String? lastSearchedNius,
  }) {
    return AthleteSearchState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
      lastSearchedNius: lastSearchedNius ?? this.lastSearchedNius,
    );
  }
}

class AthleteNotifier extends StateNotifier<AthleteSearchState> {
  final AthleteRepository _repository;

  AthleteNotifier(this._repository) : super(const AthleteSearchState());

  Future<void> searchByMsNius(String msNius) async {
    final clean = msNius.trim().toUpperCase();
    if (clean.isEmpty) return;

    state = state.copyWith(
      status: AthleteSearchStatus.loading,
      lastSearchedNius: clean,
      errorMessage: null,
    );

    try {
      final result = await _repository.fetchLicences(clean);
      state = AthleteSearchState(
        status: AthleteSearchStatus.success,
        result: result,
        lastSearchedNius: clean,
      );
    } on AthleteNotFoundException {
      state = AthleteSearchState(
        status: AthleteSearchStatus.error,
        errorMessage: 'Aucun athlète trouvé avec ce MS-NIUS. Vérifiez votre matricule.',
        lastSearchedNius: clean,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message;
      if (statusCode == 404) {
        message = 'Aucun athlète trouvé avec ce MS-NIUS. Vérifiez votre matricule.';
      } else if (statusCode == 429) {
        message = 'Trop de requêtes. Veuillez patienter quelques instants.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Délai de connexion dépassé. Vérifiez votre connexion internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Impossible de se connecter au serveur. Vérifiez votre connexion.';
      } else {
        message = 'Erreur de connexion. Veuillez réessayer.';
      }
      state = AthleteSearchState(
        status: AthleteSearchStatus.error,
        errorMessage: message,
        lastSearchedNius: clean,
      );
    } catch (e, stack) {
      debugPrint('[AthleteNotifier] Erreur inattendue: $e\n$stack');
      state = AthleteSearchState(
        status: AthleteSearchStatus.error,
        errorMessage: 'Une erreur inattendue est survenue.',
        lastSearchedNius: clean,
      );
    }
  }

  void reset() {
    state = const AthleteSearchState();
  }
}

final athleteRepositoryProvider = Provider<AthleteRepository>((ref) {
  return AthleteRepository();
});

final athleteProvider =
    StateNotifierProvider<AthleteNotifier, AthleteSearchState>((ref) {
  return AthleteNotifier(ref.read(athleteRepositoryProvider));
});
