import 'package:dio/dio.dart';
import '../config/api.dart';
import 'auth_service.dart';

double _d(dynamic v) => num.parse(v.toString()).toDouble();

Map<String, dynamic> _norm(Map<String, dynamic> inv) => {
      ...inv,
      'total': _d(inv['total']),
    };

class InvoiceService {
  static Future<Dio> _client() async {
    final token = await AuthService.getToken();
    return Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {'Authorization': 'Bearer $token'},
    ));
  }

  static Future<List<Map<String, dynamic>>> getInvoices() async {
    final dio = await _client();
    final res = await dio.get('/invoices');
    return (res.data as List).map((e) => _norm(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> addInvoice({
    required String clientName,
    required List<Map<String, dynamic>> items,
    required double total,
    required String dueDate,
    String status = 'unpaid',
  }) async {
    final dio = await _client();
    final res = await dio.post('/invoices', data: {
      'client_name': clientName,
      'items': items,
      'total': total,
      'status': status,
      'due_date': dueDate,
    });
    return _norm(res.data as Map<String, dynamic>);
  }

  static Future<void> updateStatus(int id, String status) async {
    final dio = await _client();
    await dio.patch('/invoices/$id/status', data: {'status': status});
  }

  static Future<void> deleteInvoice(int id) async {
    final dio = await _client();
    await dio.delete('/invoices/$id');
  }
}
