import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;

  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: true,
        logPrint: (o) => debugPrint('[DIO] $o'),
      ));
    }
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }
}
