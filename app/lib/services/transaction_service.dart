import 'package:dio/dio.dart';
import '../config/api.dart';
import 'auth_service.dart';

class TransactionService {
  static Future<Dio> _client() async {
    final token = await AuthService.getToken();
    return Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {'Authorization': 'Bearer $token'},
    ));
  }

  static Future<Map<String, dynamic>> getSummary() async {
    final dio = await _client();
    final res = await dio.get('/reports/summary');
    return res.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getTransactions({String? type, int limit = 20}) async {
    final dio = await _client();
    final res = await dio.get('/transactions', queryParameters: {
      'type': type,
      'limit': limit,
    });
    return res.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> addTransaction({
    required String type,
    required double amount,
    required String category,
    required String date,
    String account = 'cash',
    String? party,
    String? note,
  }) async {
    final dio = await _client();
    final res = await dio.post('/transactions', data: {
      'type': type,
      'amount': amount,
      'category': category,
      'account': account,
      'party': party,
      'note': note,
      'date': date,
    });
    return res.data as Map<String, dynamic>;
  }

  static Future<void> deleteTransaction(int id) async {
    final dio = await _client();
    await dio.delete('/transactions/$id');
  }
}
