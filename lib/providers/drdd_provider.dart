import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/drdd_repository.dart';
import '../models/drdd_models.dart';

class DrddDashboardState {
  final bool loading;
  final DrddTerritoire? territoire;
  final DrddStats? stats;
  final List<DrddEvenementRecent> evenementsRecents;
  final List<DrddActiviteRecente> activitesRecentes;
  final String? error;

  const DrddDashboardState({
    this.loading = false,
    this.territoire,
    this.stats,
    this.evenementsRecents = const [],
    this.activitesRecentes = const [],
    this.error,
  });

  bool get isDR => territoire?.isDR ?? false;
  bool get isDD => territoire?.isDD ?? false;

  DrddDashboardState copyWith({
    bool? loading,
    DrddTerritoire? territoire,
    DrddStats? stats,
    List<DrddEvenementRecent>? evenementsRecents,
    List<DrddActiviteRecente>? activitesRecentes,
    String? error,
  }) {
    return DrddDashboardState(
      loading: loading ?? this.loading,
      territoire: territoire ?? this.territoire,
      stats: stats ?? this.stats,
      evenementsRecents: evenementsRecents ?? this.evenementsRecents,
      activitesRecentes: activitesRecentes ?? this.activitesRecentes,
      error: error,
    );
  }
}

class DrddDashboardNotifier extends StateNotifier<DrddDashboardState> {
  final DrddRepository _repo;

  DrddDashboardNotifier(this._repo) : super(const DrddDashboardState());

  Future<void> fetchDashboard() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final data = await _repo.fetchDashboard();
      debugPrint('[DRDD] fetch OK — '
          'stats=${data.stats.evenements}, '
          'activités=${data.activitesRecentes.length}, '
          'events=${data.evenementsRecents.length}');
      state = DrddDashboardState(
        territoire: data.territoire,
        stats: data.stats,
        evenementsRecents: data.evenementsRecents,
        activitesRecentes: data.activitesRecentes,
      );
    } catch (e, st) {
      debugPrint('[DRDD] fetch ERREUR: $e\n$st');
      state = state.copyWith(
        loading: false,
        error: 'Impossible de charger le tableau de bord.',
      );
    }
  }

  void reset() {
    state = const DrddDashboardState();
  }
}

final drddRepositoryProvider = Provider<DrddRepository>((ref) {
  return DrddRepository();
});

final drddDashboardProvider =
    StateNotifierProvider<DrddDashboardNotifier, DrddDashboardState>((ref) {
  final repo = ref.watch(drddRepositoryProvider);
  return DrddDashboardNotifier(repo);
});
