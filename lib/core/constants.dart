import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static String get apiBaseUrl {
    if (kReleaseMode) return 'https://ms-sigs.org/api';
    if (kIsWeb) return 'http://localhost:8000/api';
    // Android emulator uses 10.0.2.2 to reach host localhost
    return 'http://10.0.2.2:8000/api';
  }

  static const String appName = 'SIGS';
  static const String appFullName = 'Système d\'Information et de Gestion du Sport';
  static const String appTagline =
      'Ministère des Sports — Direction des Systèmes d\'Information';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
