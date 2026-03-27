import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/evenement_repository.dart';
import '../models/evenement_models.dart';

class EvenementsState {
  final bool loading;
  final bool statsLoading;
  final List<Evenement> records;
  final int totalRecords;
  final EvenementStats stats;
  final EvenementFormOptions? formOptions;
  final String? error;
  final int page;
  final String searchQuery;
  final String? filterType;
  final String? filterDiscipline;
  final String? filterFederation;
  // Multi-select
  final Set<String> selectedCodes;
  final bool selectionMode;

  const EvenementsState({
    this.loading = false,
    this.statsLoading = false,
    this.records = const [],
    this.totalRecords = 0,
    this.stats = const EvenementStats(),
    this.formOptions,
    this.error,
    this.page = 1,
    this.searchQuery = '',
    this.filterType,
    this.filterDiscipline,
    this.filterFederation,
    this.selectedCodes = const {},
    this.selectionMode = false,
  });

  bool get hasActiveFilters =>
      filterType != null || filterDiscipline != null || filterFederation != null;

  EvenementsState copyWith({
    bool? loading,
    bool? statsLoading,
    List<Evenement>? records,
    int? totalRecords,
    EvenementStats? stats,
    EvenementFormOptions? formOptions,
    String? error,
    int? page,
    String? searchQuery,
    String? filterType,
    String? filterDiscipline,
    String? filterFederation,
    Set<String>? selectedCodes,
    bool? selectionMode,
    bool clearFilterType = false,
    bool clearFilterDiscipline = false,
    bool clearFilterFederation = false,
  }) =>
      EvenementsState(
        loading: loading ?? this.loading,
        statsLoading: statsLoading ?? this.statsLoading,
        records: records ?? this.records,
        totalRecords: totalRecords ?? this.totalRecords,
        stats: stats ?? this.stats,
        formOptions: formOptions ?? this.formOptions,
        error: error,
        page: page ?? this.page,
        searchQuery: searchQuery ?? this.searchQuery,
        filterType: clearFilterType ? null : (filterType ?? this.filterType),
        filterDiscipline: clearFilterDiscipline
            ? null
            : (filterDiscipline ?? this.filterDiscipline),
        filterFederation: clearFilterFederation
            ? null
            : (filterFederation ?? this.filterFederation),
        selectedCodes: selectedCodes ?? this.selectedCodes,
        selectionMode: selectionMode ?? this.selectionMode,
      );
}

class EvenementsNotifier extends StateNotifier<EvenementsState> {
  final EvenementRepository _repo;
  EvenementsNotifier(this._repo) : super(const EvenementsState());

  Future<void> load({
    int page = 1,
    String? search,
    String? filterType,
    String? filterDiscipline,
    String? filterFederation,
    bool clearFilters = false,
  }) async {
    state = state.copyWith(loading: true, error: null, page: page);
    if (search != null) state = state.copyWith(searchQuery: search);
    if (clearFilters) {
      state = state.copyWith(
        clearFilterType: true,
        clearFilterDiscipline: true,
        clearFilterFederation: true,
      );
    } else {
      if (filterType != null) state = state.copyWith(filterType: filterType);
      if (filterDiscipline != null) {
        state = state.copyWith(filterDiscipline: filterDiscipline);
      }
      if (filterFederation != null) {
        state = state.copyWith(filterFederation: filterFederation);
      }
    }
    try {
      final resp = await _repo.fetchEvenements(
        page: page,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        typeEvenement: state.filterType,
        discipline: state.filterDiscipline,
        federation: state.filterFederation,
      );
      state = state.copyWith(
        loading: false,
        records: resp.results,
        totalRecords: resp.count,
      );
    } catch (e) {
      debugPrint('[Evenements] load error: $e');
      state = state.copyWith(
        loading: false,
        error: 'Impossible de charger les événements.',
      );
    }
  }

  Future<void> loadStats() async {
    state = state.copyWith(statsLoading: true);
    try {
      final stats = await _repo.fetchStats();
      state = state.copyWith(statsLoading: false, stats: stats);
    } catch (e) {
      debugPrint('[Evenements] stats error: $e');
      state = state.copyWith(statsLoading: false);
    }
  }

  Future<void> loadFormOptions() async {
    try {
      final opts = await _repo.fetchFormOptions();
      state = state.copyWith(formOptions: opts);
    } catch (e) {
      debugPrint('[Evenements] form-options error: $e');
    }
  }

  Future<String?> create(
    Map<String, dynamic> data, {
    String? imagePath,
    String? documentPath,
  }) async {
    try {
      await _repo.create(data,
          imagePath: imagePath, documentPath: documentPath);
    } catch (e) {
      return _extractError(e);
    }
    await Future.wait([load(page: state.page), loadStats()]);
    return null;
  }

  Future<String?> update(
    String code,
    Map<String, dynamic> data, {
    String? imagePath,
    String? documentPath,
  }) async {
    try {
      await _repo.update(code, data,
          imagePath: imagePath, documentPath: documentPath);
    } catch (e) {
      return _extractError(e);
    }
    await Future.wait([load(page: state.page), loadStats()]);
    return null;
  }

  Future<String?> delete(String code) async {
    try {
      await _repo.delete(code);
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<({int deleted, int failed})> bulkDelete() async {
    final codes = state.selectedCodes.toList();
    if (codes.isEmpty) return (deleted: 0, failed: 0);
    final errors = await _repo.bulkDelete(codes);
    exitSelectionMode();
    await Future.wait([load(page: state.page), loadStats()]);
    return (deleted: codes.length - errors.length, failed: errors.length);
  }

  // ── Selection ──

  void toggleSelectionMode() {
    if (state.selectionMode) {
      state = state.copyWith(selectionMode: false, selectedCodes: {});
    } else {
      state = state.copyWith(selectionMode: true, selectedCodes: {});
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
      selectedCodes: state.records.map((e) => e.code).toSet(),
    );
  }

  void deselectAll() {
    state = state.copyWith(selectedCodes: {});
  }

  void exitSelectionMode() {
    state = state.copyWith(selectionMode: false, selectedCodes: {});
  }

  void clearFilters() {
    load(page: 1, clearFilters: true);
  }

  String _extractError(Object e) {
    if (e is Exception) return e.toString();
    return 'Erreur inattendue.';
  }
}

final evenementRepoProvider = Provider<EvenementRepository>((ref) {
  return EvenementRepository();
});

final evenementsProvider =
    StateNotifierProvider<EvenementsNotifier, EvenementsState>((ref) {
  return EvenementsNotifier(ref.watch(evenementRepoProvider));
});
