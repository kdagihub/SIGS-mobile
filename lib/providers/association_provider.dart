import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/association_repository.dart';
import '../models/association_models.dart';

class AssociationsState {
  final bool loading;
  final bool statsLoading;
  final List<Association> records;
  final int totalRecords;
  final AssociationStats stats;
  final AssociationFormOptions? formOptions;
  final String? error;
  final int page;
  final String searchQuery;
  final String? filterAgree;
  final String? filterFederation;
  final String? filterLocalite;

  final bool selectionMode;
  final Set<String> selectedCodes;

  const AssociationsState({
    this.loading = false,
    this.statsLoading = false,
    this.records = const [],
    this.totalRecords = 0,
    this.stats = const AssociationStats(),
    this.formOptions,
    this.error,
    this.page = 1,
    this.searchQuery = '',
    this.filterAgree,
    this.filterFederation,
    this.filterLocalite,
    this.selectionMode = false,
    this.selectedCodes = const {},
  });

  bool get hasActiveFilters =>
      filterAgree != null ||
      filterFederation != null ||
      filterLocalite != null;

  AssociationsState copyWith({
    bool? loading,
    bool? statsLoading,
    List<Association>? records,
    int? totalRecords,
    AssociationStats? stats,
    AssociationFormOptions? formOptions,
    String? error,
    int? page,
    String? searchQuery,
    String? filterAgree,
    String? filterFederation,
    String? filterLocalite,
    bool clearFilterAgree = false,
    bool clearFilterFederation = false,
    bool clearFilterLocalite = false,
    bool? selectionMode,
    Set<String>? selectedCodes,
  }) =>
      AssociationsState(
        loading: loading ?? this.loading,
        statsLoading: statsLoading ?? this.statsLoading,
        records: records ?? this.records,
        totalRecords: totalRecords ?? this.totalRecords,
        stats: stats ?? this.stats,
        formOptions: formOptions ?? this.formOptions,
        error: error,
        page: page ?? this.page,
        searchQuery: searchQuery ?? this.searchQuery,
        filterAgree:
            clearFilterAgree ? null : (filterAgree ?? this.filterAgree),
        filterFederation: clearFilterFederation
            ? null
            : (filterFederation ?? this.filterFederation),
        filterLocalite: clearFilterLocalite
            ? null
            : (filterLocalite ?? this.filterLocalite),
        selectionMode: selectionMode ?? this.selectionMode,
        selectedCodes: selectedCodes ?? this.selectedCodes,
      );
}

class AssociationsNotifier extends StateNotifier<AssociationsState> {
  final AssociationRepository _repo;
  AssociationsNotifier(this._repo) : super(const AssociationsState());

  Future<void> load({
    int page = 1,
    String? search,
    String? filterAgree,
    String? filterFederation,
    String? filterLocalite,
    bool clearFilters = false,
  }) async {
    state = state.copyWith(loading: true, error: null, page: page);
    if (search != null) state = state.copyWith(searchQuery: search);
    if (clearFilters) {
      state = state.copyWith(
        clearFilterAgree: true,
        clearFilterFederation: true,
        clearFilterLocalite: true,
      );
    } else {
      if (filterAgree != null) {
        state = state.copyWith(filterAgree: filterAgree);
      }
      if (filterFederation != null) {
        state = state.copyWith(filterFederation: filterFederation);
      }
      if (filterLocalite != null) {
        state = state.copyWith(filterLocalite: filterLocalite);
      }
    }
    try {
      final resp = await _repo.fetchAssociations(
        page: page,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        estAgree: state.filterAgree,
        federation: state.filterFederation,
        localite: state.filterLocalite,
      );
      state = state.copyWith(
        loading: false,
        records: resp.results,
        totalRecords: resp.count,
      );
    } catch (e) {
      debugPrint('[Associations] load error: $e');
      state = state.copyWith(
        loading: false,
        error: 'Impossible de charger les associations.',
      );
    }
  }

  Future<void> loadStats() async {
    state = state.copyWith(statsLoading: true);
    try {
      final stats = await _repo.fetchStats();
      state = state.copyWith(statsLoading: false, stats: stats);
    } catch (e) {
      debugPrint('[Associations] stats error: $e');
      state = state.copyWith(statsLoading: false);
    }
  }

  Future<void> loadFormOptions() async {
    try {
      final opts = await _repo.fetchFormOptions();
      state = state.copyWith(formOptions: opts);
    } catch (e) {
      debugPrint('[Associations] form-options error: $e');
    }
  }

  Future<String?> create(
    Map<String, dynamic> data, {
    String? logoPath,
    String? recepisePath,
    String? agrementPath,
  }) async {
    try {
      await _repo.create(data,
          logoPath: logoPath,
          recepisePath: recepisePath,
          agrementPath: agrementPath);
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> update(
    String code,
    Map<String, dynamic> data, {
    String? logoPath,
    String? recepisePath,
    String? agrementPath,
  }) async {
    try {
      await _repo.update(code, data,
          logoPath: logoPath,
          recepisePath: recepisePath,
          agrementPath: agrementPath);
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

  // --------------- Actions groupées ---------------

  Future<String?> bulkSetAgree(bool agree) async {
    final codes = state.selectedCodes.toList();
    if (codes.isEmpty) return 'Aucune sélection';
    try {
      await Future.wait(
        codes.map((c) => _repo.patchField(c, {'est_agree': agree})),
      );
      state = state.copyWith(selectionMode: false, selectedCodes: {});
      await Future.wait([load(page: state.page), loadStats()]);
      return null;
    } catch (e) {
      return _extractError(e);
    }
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
    load(page: 1, clearFilters: true);
  }

  String _extractError(Object e) {
    if (e is Exception) return e.toString();
    return 'Erreur inattendue.';
  }
}

final associationRepoProvider = Provider<AssociationRepository>((ref) {
  return AssociationRepository();
});

final associationsProvider =
    StateNotifierProvider<AssociationsNotifier, AssociationsState>((ref) {
  return AssociationsNotifier(ref.watch(associationRepoProvider));
});
