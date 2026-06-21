import 'package:dio/dio.dart';
import '../config/api.dart';
import 'auth_service.dart';

class UserService {
  static Future<Dio> _client() async {
    final token = await AuthService.getToken();
    return Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {'Authorization': 'Bearer $token'},
    ));
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final dio = await _client();
    final res = await dio.get('/users');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  static Future<void> updateRole(int id, String role) async {
    final dio = await _client();
    await dio.patch('/users/$id/role', data: {'role': role});
  }

  static Future<void> deleteUser(int id) async {
    final dio = await _client();
    await dio.delete('/users/$id');
  }
}
