import 'package:flutter/foundation.dart';

class ApiConfig {
  static const _prod = 'https://officeflow-backend-nebe.onrender.com/api/v1';
  static const _localWeb = 'http://localhost:3000/api/v1';
  static const _localAndroid = 'http://10.0.2.2:3000/api/v1';

  static String get baseUrl {
    // Always use prod when running as a release build
    if (!kDebugMode) return _prod;
    // Debug: web uses localhost, Android emulator uses 10.0.2.2
    if (kIsWeb) return _localWeb;
    return _localAndroid;
  }
}
