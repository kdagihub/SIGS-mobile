import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/territoire_repository.dart';
import '../models/territoire_models.dart';

// ──────────────────────────────────────────────────────────────
// Départements
// ──────────────────────────────────────────────────────────────

class DepartementsState {
  final bool loading;
  final bool statsLoading;
  final List<Departement> records;
  final int totalRecords;
  final DepartementStats stats;
  final String? error;
  final int page;
  final String searchQuery;

  const DepartementsState({
    this.loading = false,
    this.statsLoading = false,
    this.records = const [],
    this.totalRecords = 0,
    this.stats = const DepartementStats(),
    this.error,
    this.page = 1,
    this.searchQuery = '',
  });

  DepartementsState copyWith({
    bool? loading,
    bool? statsLoading,
    List<Departement>? records,
    int? totalRecords,
    DepartementStats? stats,
    String? error,
    int? page,
    String? searchQuery,
  }) =>
      DepartementsState(
        loading: loading ?? this.loading,
        statsLoading: statsLoading ?? this.statsLoading,
        records: records ?? this.records,
        totalRecords: totalRecords ?? this.totalRecords,
        stats: stats ?? this.stats,
        error: error,
        page: page ?? this.page,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

class DepartementsNotifier extends StateNotifier<DepartementsState> {
  final TerritoireRepository _repo;
  DepartementsNotifier(this._repo) : super(const DepartementsState());

  Future<void> load({int page = 1, String? search}) async {
    state = state.copyWith(loading: true, error: null, page: page);
    if (search != null) state = state.copyWith(searchQuery: search);
    try {
      final resp = await _repo.fetchDepartements(
        page: page,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(
        loading: false,
        records: resp.results,
        totalRecords: resp.count,
      );
    } catch (e) {
      debugPrint('[Departements] load error: $e');
      state = state.copyWith(
          loading: false, error: 'Impossible de charger les départements.');
    }
  }

  Future<void> loadStats() async {
    state = state.copyWith(statsLoading: true);
    try {
      final stats = await _repo.fetchDepartementStats();
      state = state.copyWith(statsLoading: false, stats: stats);
    } catch (e) {
      debugPrint('[Departements] stats error: $e');
      state = state.copyWith(statsLoading: false);
    }
  }

  Future<String?> create(Map<String, dynamic> data) async {
    try {
      await _repo.createDepartement(data);
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> update(String code, Map<String, dynamic> data) async {
    try {
      await _repo.updateDepartement(code, data);
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> toggleActive(Departement dd) async {
    try {
      await _repo.patchDepartement(dd.code, {'is_active': !dd.isActive});
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> delete(String code) async {
    try {
      await _repo.deleteDepartement(code);
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  String _extractError(Object e) {
    if (e is Exception) return e.toString();
    return 'Erreur inattendue.';
  }
}

// ──────────────────────────────────────────────────────────────
// Localités
// ──────────────────────────────────────────────────────────────

class LocalitesState {
  final bool loading;
  final bool statsLoading;
  final List<Localite> records;
  final int totalRecords;
  final LocaliteStats stats;
  final LocaliteFormOptions? formOptions;
  final String? error;
  final int page;
  final String searchQuery;
  final String? filterDd;
  final bool selectionMode;
  final Set<String> selectedCodes;

  const LocalitesState({
    this.loading = false,
    this.statsLoading = false,
    this.records = const [],
    this.totalRecords = 0,
    this.stats = const LocaliteStats(),
    this.formOptions,
    this.error,
    this.page = 1,
    this.searchQuery = '',
    this.filterDd,
    this.selectionMode = false,
    this.selectedCodes = const {},
  });

  LocalitesState copyWith({
    bool? loading,
    bool? statsLoading,
    List<Localite>? records,
    int? totalRecords,
    LocaliteStats? stats,
    LocaliteFormOptions? formOptions,
    String? error,
    int? page,
    String? searchQuery,
    String? filterDd,
    bool clearFilterDd = false,
    bool? selectionMode,
    Set<String>? selectedCodes,
  }) =>
      LocalitesState(
        loading: loading ?? this.loading,
        statsLoading: statsLoading ?? this.statsLoading,
        records: records ?? this.records,
        totalRecords: totalRecords ?? this.totalRecords,
        stats: stats ?? this.stats,
        formOptions: formOptions ?? this.formOptions,
        error: error,
        page: page ?? this.page,
        searchQuery: searchQuery ?? this.searchQuery,
        filterDd: clearFilterDd ? null : (filterDd ?? this.filterDd),
        selectionMode: selectionMode ?? this.selectionMode,
        selectedCodes: selectedCodes ?? this.selectedCodes,
      );
}

class LocalitesNotifier extends StateNotifier<LocalitesState> {
  final TerritoireRepository _repo;
  LocalitesNotifier(this._repo) : super(const LocalitesState());

  Future<void> load({int page = 1, String? search, String? filterDd}) async {
    state = state.copyWith(loading: true, error: null, page: page);
    if (search != null) state = state.copyWith(searchQuery: search);
    if (filterDd != null) state = state.copyWith(filterDd: filterDd);
    try {
      final resp = await _repo.fetchLocalites(
        page: page,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        directionDepartement: state.filterDd,
      );
      state = state.copyWith(
        loading: false,
        records: resp.results,
        totalRecords: resp.count,
      );
    } catch (e) {
      debugPrint('[Localites] load error: $e');
      state = state.copyWith(
          loading: false, error: 'Impossible de charger les localités.');
    }
  }

  Future<void> loadStats() async {
    state = state.copyWith(statsLoading: true);
    try {
      final stats = await _repo.fetchLocaliteStats();
      state = state.copyWith(statsLoading: false, stats: stats);
    } catch (e) {
      debugPrint('[Localites] stats error: $e');
      state = state.copyWith(statsLoading: false);
    }
  }

  Future<void> loadFormOptions() async {
    try {
      final opts = await _repo.fetchLocaliteFormOptions();
      state = state.copyWith(formOptions: opts);
    } catch (e) {
      debugPrint('[Localites] form-options error: $e');
    }
  }

  Future<String?> create(Map<String, dynamic> data) async {
    try {
      await _repo.createLocalite(data);
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> update(String code, Map<String, dynamic> data) async {
    try {
      await _repo.updateLocalite(code, data);
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> delete(String code) async {
    try {
      await _repo.deleteLocalite(code);
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  // --------------- Sélection multiple ---------------

  void toggleSelectionMode() {
    if (state.selectionMode) {
      state = state.copyWith(selectionMode: false, selectedCodes: {});
    } else {
      state = state.copyWith(selectionMode: true);
    }
  }

  void toggleSelect(String code) {
    final s = Set<String>.from(state.selectedCodes);
    if (s.contains(code)) {
      s.remove(code);
    } else {
      s.add(code);
    }
    state = state.copyWith(selectedCodes: s);
  }

  void selectAll() {
    state = state.copyWith(
      selectedCodes: state.records.map((r) => r.code).toSet(),
    );
  }

  void deselectAll() {
    state = state.copyWith(selectedCodes: {});
  }

  Future<String?> bulkDelete() async {
    final codes = state.selectedCodes.toList();
    if (codes.isEmpty) return 'Aucune sélection';
    try {
      await Future.wait(codes.map((c) => _repo.deleteLocalite(c)));
      state = state.copyWith(selectionMode: false, selectedCodes: {});
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  String _extractError(Object e) {
    if (e is Exception) return e.toString();
    return 'Erreur inattendue.';
  }
}

// ──────────────────────────────────────────────────────────────
// Providers
// ──────────────────────────────────────────────────────────────

final territoireRepoProvider = Provider<TerritoireRepository>((ref) {
  return TerritoireRepository();
});

final departementsProvider =
    StateNotifierProvider<DepartementsNotifier, DepartementsState>((ref) {
  return DepartementsNotifier(ref.watch(territoireRepoProvider));
});

final localitesProvider =
    StateNotifierProvider<LocalitesNotifier, LocalitesState>((ref) {
  return LocalitesNotifier(ref.watch(territoireRepoProvider));
});
