import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/dio_client.dart' show navigatorKey;
import 'config/api.dart';

void main() {
  _warmUpServer(); // fire-and-forget — wakes Render before user taps anything
  runApp(const OfficeFlowApp());
}

/// Silently pings the backend root so Render starts booting immediately.
void _warmUpServer() {
  Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 90),
  )).get('/').catchError((_) => Response(requestOptions: RequestOptions()));
}

class OfficeFlowApp extends StatelessWidget {
  const OfficeFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OfficeFlow',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      // Named routes used by the 401 interceptor
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home':  (_) => const HomeScreen(),
      },
      home: const _AuthGate(),
    );
  }
}

/// Checks for a stored token and routes to Home or Login accordingly.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data != null
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}
