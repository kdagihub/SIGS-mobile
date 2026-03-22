import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../providers/athlete_provider.dart';
import '../../../providers/recent_searches_provider.dart';
import '../widgets/search_form.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(athleteProvider);
    final recentSearches = ref.watch(recentSearchesProvider);

    ref.listen<AthleteSearchState>(athleteProvider, (previous, next) {
      if (next.status == AthleteSearchStatus.success && next.result != null) {
        final notifier = ref.read(recentSearchesProvider.notifier);
        notifier.addSearch(
          next.lastSearchedNius ?? '',
          athleteName: next.result!.athlete.fullName,
        );
        Future.microtask(() {
          if (context.mounted) context.go('/result');
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Image.asset(
                  'assets/images/logo_sigs.png',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  'Portail Athlète',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SigsTheme.primaryBlue,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consultez vos licences sportives',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 32),
                SearchForm(
                  isLoading: state.status == AthleteSearchStatus.loading,
                  errorMessage: state.status == AthleteSearchStatus.error
                      ? state.errorMessage
                      : null,
                  recentSearches: recentSearches,
                  onSearch: (msNius) {
                    ref.read(athleteProvider.notifier).searchByMsNius(msNius);
                  },
                  onRemoveRecent: (msNius) {
                    ref
                        .read(recentSearchesProvider.notifier)
                        .removeSearch(msNius);
                  },
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Ministère des Sports — Direction des Systèmes d\'Information',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
