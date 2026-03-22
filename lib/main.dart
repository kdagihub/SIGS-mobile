import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'core/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SigsApp()));
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
