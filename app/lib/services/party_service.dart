import 'package:dio/dio.dart';
import '../config/api.dart';
import 'auth_service.dart';

double _d(dynamic v) => num.parse(v.toString()).toDouble();

Map<String, dynamic> _normParty(Map<String, dynamic> p) => {
      ...p,
      'opening_balance': _d(p['opening_balance']),
      'balance': p['balance'] != null ? _d(p['balance']) : null,
    };

class PartyService {
  static Future<Dio> _client() async {
    final token = await AuthService.getToken();
    return Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {'Authorization': 'Bearer $token'},
    ));
  }

  static Future<List<Map<String, dynamic>>> getParties() async {
    final dio = await _client();
    final res = await dio.get('/parties');
    return (res.data as List).map((e) => _normParty(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> addParty({
    required String name,
    String? phone,
    String type = 'customer',
    double openingBalance = 0,
    String? notes,
  }) async {
    final dio = await _client();
    final res = await dio.post('/parties', data: {
      'name': name,
      'phone': phone,
      'type': type,
      'opening_balance': openingBalance,
      'notes': notes,
    });
    return _normParty(res.data as Map<String, dynamic>);
  }

  static Future<void> deleteParty(int id) async {
    final dio = await _client();
    await dio.delete('/parties/$id');
  }

  static Future<Map<String, dynamic>> getLedger(int partyId) async {
    final dio = await _client();
    final res = await dio.get('/parties/$partyId/ledger');
    final d = res.data as Map<String, dynamic>;
    final txList = (d['transactions'] as List).map((e) {
      final tx = e as Map<String, dynamic>;
      return {
        ...tx,
        'amount': _d(tx['amount']),
        'running_balance': _d(tx['running_balance']),
      };
    }).toList();
    return {
      'party': _normParty(d['party'] as Map<String, dynamic>),
      'transactions': txList,
      'balance': _d(d['balance']),
    };
  }
}
