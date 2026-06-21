import 'package:flutter/foundation.dart';

class ApiConfig {
  // Web/desktop: localhost; Android emulator: 10.0.2.2 (maps to host localhost)
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    return 'http://10.0.2.2:3000/api/v1';
  }
}
