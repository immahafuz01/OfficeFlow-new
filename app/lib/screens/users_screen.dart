import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'dart:convert';

const _roles = ['admin', 'accountant', 'viewer'];

const _roleColors = {
  'admin': Colors.blue,
  'accountant': Colors.teal,
  'viewer': Colors.grey,
};

/// Decodes the JWT payload to get the current user's id.
int? _currentUserId(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])));
    return (jsonDecode(payload) as Map<String, dynamic>)['id'] as int?;
  } catch (_) {
    return null;
  }
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  int? _myId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await AuthService.getToken();
    if (token != null) _myId = _currentUserId(token);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await UserService.getUsers();
      setState(() => _users = data);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(int id, String role) async {
    await UserService.updateRole(id, role);
    _load();
  }

  Future<void> _delete(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Remove ${user['name']}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await UserService.deleteUser(user['id'] as int);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot delete this user.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _users.isEmpty
                  ? const Center(child: Text('No users found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final u = _users[i];
                        final isMe = u['id'] == _myId;
                        final role = u['role'] as String;
                        final color = _roleColors[role] ?? Colors.grey;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Text(
                              (u['name'] as String)[0].toUpperCase(),
                              style: TextStyle(color: color, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            '${u['name'] as String}${isMe ? ' (you)' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(u['email'] as String,
                              style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<String>(
                                value: role,
                                underline: const SizedBox(),
                                isDense: true,
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                                items: _roles
                                    .map((r) => DropdownMenuItem(
                                        value: r, child: Text(r)))
                                    .toList(),
                                onChanged: isMe
                                    ? null
                                    : (v) {
                                        if (v != null && v != role) {
                                          _changeRole(u['id'] as int, v);
                                        }
                                      },
                              ),
                              if (!isMe)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.grey),
                                  onPressed: () => _delete(u),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
