import 'package:flutter/foundation.dart';

class ApiConfig {
  static const _prod = 'https://officeflow-backend-nebe.onrender.com/api/v1';
  static const _localWeb = 'http://localhost:3000/api/v1';
  static const _localAndroid = 'http://10.0.2.2:3000/api/v1';

  static String get baseUrl {
    if (!kDebugMode) return _prod;
    if (kIsWeb) return _localWeb;
    return _localAndroid;
  }

  /// Render free tier can take up to 60s to cold-start.
  /// Use generous timeouts so the first request after inactivity succeeds.
  static const connectTimeout = Duration(seconds: 90);
  static const receiveTimeout = Duration(seconds: 90);
  static const sendTimeout    = Duration(seconds: 30);
}
