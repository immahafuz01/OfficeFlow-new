import 'package:dio/dio.dart';
import '../config/api.dart';
import 'auth_service.dart';

double _d(dynamic v) => num.parse(v.toString()).toDouble();

class ReportService {
  static Future<Dio> _client() async {
    final token = await AuthService.getToken();
    return Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {'Authorization': 'Bearer $token'},
    ));
  }

  static Future<Map<String, dynamic>> getProfitLoss(int month, int year) async {
    final dio = await _client();
    final res = await dio.get('/reports/profit-loss',
        queryParameters: {'month': month, 'year': year});
    final d = res.data as Map<String, dynamic>;
    return {
      'income': _d(d['income']),
      'expense': _d(d['expense']),
      'profit': _d(d['profit']),
    };
  }

  static Future<List<Map<String, dynamic>>> getCategories(
      int month, int year) async {
    final dio = await _client();
    final res = await dio.get('/reports/categories',
        queryParameters: {'month': month, 'year': year});
    return (res.data as List)
        .map((e) => {...e as Map<String, dynamic>, 'total': _d(e['total'])})
        .toList();
  }
}
