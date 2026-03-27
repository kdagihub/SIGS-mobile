import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/infrastructure_repository.dart';
import '../models/infrastructure_models.dart';

class InfrastructuresState {
  final bool loading;
  final bool statsLoading;
  final List<Infrastructure> records;
  final int totalRecords;
  final InfrastructureStats stats;
  final InfrastructureFormOptions? formOptions;
  final String? error;
  final int page;
  final String searchQuery;
  final String? filterEtat;
  final String? filterLocalite;
  final String? filterType;
  final bool selectionMode;
  final Set<String> selectedCodes;

  const InfrastructuresState({
    this.loading = false,
    this.statsLoading = false,
    this.records = const [],
    this.totalRecords = 0,
    this.stats = const InfrastructureStats(),
    this.formOptions,
    this.error,
    this.page = 1,
    this.searchQuery = '',
    this.filterEtat,
    this.filterLocalite,
    this.filterType,
    this.selectionMode = false,
    this.selectedCodes = const {},
  });

  bool get hasActiveFilters =>
      filterEtat != null || filterLocalite != null || filterType != null;

  InfrastructuresState copyWith({
    bool? loading,
    bool? statsLoading,
    List<Infrastructure>? records,
    int? totalRecords,
    InfrastructureStats? stats,
    InfrastructureFormOptions? formOptions,
    String? error,
    int? page,
    String? searchQuery,
    String? filterEtat,
    String? filterLocalite,
    String? filterType,
    bool clearFilterEtat = false,
    bool clearFilterLocalite = false,
    bool clearFilterType = false,
    bool? selectionMode,
    Set<String>? selectedCodes,
  }) =>
      InfrastructuresState(
        loading: loading ?? this.loading,
        statsLoading: statsLoading ?? this.statsLoading,
        records: records ?? this.records,
        totalRecords: totalRecords ?? this.totalRecords,
        stats: stats ?? this.stats,
        formOptions: formOptions ?? this.formOptions,
        error: error,
        page: page ?? this.page,
        searchQuery: searchQuery ?? this.searchQuery,
        filterEtat:
            clearFilterEtat ? null : (filterEtat ?? this.filterEtat),
        filterLocalite:
            clearFilterLocalite ? null : (filterLocalite ?? this.filterLocalite),
        filterType:
            clearFilterType ? null : (filterType ?? this.filterType),
        selectionMode: selectionMode ?? this.selectionMode,
        selectedCodes: selectedCodes ?? this.selectedCodes,
      );
}

class InfrastructuresNotifier extends StateNotifier<InfrastructuresState> {
  final InfrastructureRepository _repo;
  InfrastructuresNotifier(this._repo) : super(const InfrastructuresState());

  Future<void> load({
    int page = 1,
    String? search,
    String? filterEtat,
    String? filterLocalite,
    String? filterType,
    bool clearFilters = false,
  }) async {
    state = state.copyWith(loading: true, error: null, page: page);
    if (search != null) state = state.copyWith(searchQuery: search);
    if (clearFilters) {
      state = state.copyWith(
        clearFilterEtat: true,
        clearFilterLocalite: true,
        clearFilterType: true,
      );
    } else {
      if (filterEtat != null) state = state.copyWith(filterEtat: filterEtat);
      if (filterLocalite != null) {
        state = state.copyWith(filterLocalite: filterLocalite);
      }
      if (filterType != null) state = state.copyWith(filterType: filterType);
    }
    try {
      final resp = await _repo.fetchInfrastructures(
        page: page,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        etatInfrastructure: state.filterEtat,
        localite: state.filterLocalite,
        typeInfrastructure: state.filterType,
      );
      state = state.copyWith(
        loading: false,
        records: resp.results,
        totalRecords: resp.count,
      );
    } catch (e) {
      debugPrint('[Infrastructures] load error: $e');
      state = state.copyWith(
        loading: false,
        error: 'Impossible de charger les infrastructures.',
      );
    }
  }

  Future<void> loadStats() async {
    state = state.copyWith(statsLoading: true);
    try {
      final stats = await _repo.fetchStats();
      state = state.copyWith(statsLoading: false, stats: stats);
    } catch (e) {
      debugPrint('[Infrastructures] stats error: $e');
      state = state.copyWith(statsLoading: false);
    }
  }

  Future<void> loadFormOptions() async {
    try {
      final opts = await _repo.fetchFormOptions();
      state = state.copyWith(formOptions: opts);
    } catch (e) {
      debugPrint('[Infrastructures] form-options error: $e');
    }
  }

  Future<String?> create(
    Map<String, dynamic> data, {
    String? photoPath,
  }) async {
    try {
      await _repo.create(data, photoPath: photoPath);
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> update(
    String code,
    Map<String, dynamic> data, {
    String? photoPath,
  }) async {
    try {
      await _repo.update(code, data, photoPath: photoPath);
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
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
      await Future.wait(codes.map((c) => _repo.delete(c)));
      state = state.copyWith(selectionMode: false, selectedCodes: {});
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  void clearFilters() {
    load(
      page: 1,
      clearFilters: true,
    );
  }

  String _extractError(Object e) {
    if (e is Exception) return e.toString();
    return 'Erreur inattendue.';
  }
}

final infrastructureRepoProvider = Provider<InfrastructureRepository>((ref) {
  return InfrastructureRepository();
});

final infrastructuresProvider =
    StateNotifierProvider<InfrastructuresNotifier, InfrastructuresState>((ref) {
  return InfrastructuresNotifier(ref.watch(infrastructureRepoProvider));
});
