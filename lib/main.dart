import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'core/router.dart';
import 'providers/recent_searches_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SigsApp(),
    ),
  );
}

class SigsApp extends StatelessWidget {
  const SigsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SIGS Mobile',
      debugShowCheckedModeBanner: false,
      theme: SigsTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
