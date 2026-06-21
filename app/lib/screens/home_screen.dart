import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'invoices_screen.dart';
import 'reports_screen.dart';
import 'parties_screen.dart';
import 'users_screen.dart';
import 'login_screen.dart';

String? _roleFromToken(String token) {
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1])));
    return (jsonDecode(payload) as Map<String, dynamic>)['role'] as String?;
  } catch (_) {
    return null;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final token = await AuthService.getToken();
    if (token != null && _roleFromToken(token) == 'admin') {
      setState(() => _isAdmin = true);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Transactions', 'Invoices', 'Reports', 'Parties', if (_isAdmin) 'Users'];
    final screens = [
      const DashboardScreen(),
      const TransactionsScreen(),
      const InvoicesScreen(),
      const ReportsScreen(),
      const PartiesScreen(),
      if (_isAdmin) const UsersScreen(),
    ];
    final destinations = [
      const NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      const NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Transactions'),
      const NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Invoices'),
      const NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
      const NavigationDestination(icon: Icon(Icons.people_outline), label: 'Parties'),
      if (_isAdmin)
        const NavigationDestination(icon: Icon(Icons.manage_accounts_outlined), label: 'Users'),
    ];

    // Clamp tab index in case admin status changes
    final safeTab = _tab.clamp(0, screens.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[safeTab]),
        actions: [
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Logout', onPressed: _logout),
        ],
      ),
      body: IndexedStack(index: safeTab, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeTab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: destinations,
      ),
    );
  }
}
