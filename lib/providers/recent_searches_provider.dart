import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kRecentSearchesKey = 'recent_ms_nius_searches';
const _kMaxRecent = 8;

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

class RecentSearchEntry {
  final String msNius;
  final String? athleteName;
  final DateTime searchedAt;

  const RecentSearchEntry({
    required this.msNius,
    this.athleteName,
    required this.searchedAt,
  });

  Map<String, dynamic> toJson() => {
        'msNius': msNius,
        'athleteName': athleteName,
        'searchedAt': searchedAt.toIso8601String(),
      };

  factory RecentSearchEntry.fromJson(Map<String, dynamic> json) {
    return RecentSearchEntry(
      msNius: json['msNius'] as String,
      athleteName: json['athleteName'] as String?,
      searchedAt: DateTime.parse(json['searchedAt'] as String),
    );
  }
}

class RecentSearchesNotifier extends StateNotifier<List<RecentSearchEntry>> {
  final SharedPreferences _prefs;

  RecentSearchesNotifier(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final raw = _prefs.getStringList(_kRecentSearchesKey);
    if (raw == null || raw.isEmpty) return;

    final entries = raw
        .map((s) {
          try {
            return RecentSearchEntry.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<RecentSearchEntry>()
        .toList();

    entries.sort((a, b) => b.searchedAt.compareTo(a.searchedAt));
    state = entries.take(_kMaxRecent).toList();
  }

  void addSearch(String msNius, {String? athleteName}) {
    final clean = msNius.trim().toUpperCase();
    if (clean.isEmpty) return;

    final existing = state.where((e) => e.msNius != clean).toList();
    final updated = [
      RecentSearchEntry(
        msNius: clean,
        athleteName: athleteName,
        searchedAt: DateTime.now(),
      ),
      ...existing,
    ].take(_kMaxRecent).toList();

    state = updated;
    _persist(updated);
  }

  void removeSearch(String msNius) {
    final updated = state.where((e) => e.msNius != msNius).toList();
    state = updated;
    _persist(updated);
  }

  void clearAll() {
    state = [];
    _prefs.remove(_kRecentSearchesKey);
  }

  void _persist(List<RecentSearchEntry> entries) {
    final raw = entries.map((e) => jsonEncode(e.toJson())).toList();
    _prefs.setStringList(_kRecentSearchesKey, raw);
  }
}

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<RecentSearchEntry>>(
        (ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RecentSearchesNotifier(prefs);
});
