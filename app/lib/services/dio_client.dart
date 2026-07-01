import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../config/api.dart';
import 'auth_service.dart';

// Navigating to login without a BuildContext requires a global key.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Returns a Dio instance pre-configured with:
///  - auth bearer token
///  - Render-friendly timeouts (90s connect/receive)
///  - 401 interceptor → clears token and redirects to login
Future<Dio> buildClient() async {
  final token = await AuthService.getToken();
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    sendTimeout: ApiConfig.sendTimeout,
    headers: {'Authorization': 'Bearer $token'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onError: (DioException err, ErrorInterceptorHandler handler) async {
      if (err.response?.statusCode == 401) {
        // Token expired or invalid — log out and go to login
        await AuthService.logout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
      }
      handler.next(err);
    },
  ));

  return dio;
}
