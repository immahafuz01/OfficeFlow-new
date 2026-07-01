import 'package:dio/dio.dart';
import 'dio_client.dart';

// Coerce any value that should be a double (pg may send it as a String).
double _d(dynamic v) => num.parse(v.toString()).toDouble();

// Normalise a raw transaction map so all numeric fields are proper doubles.
Map<String, dynamic> _normTx(Map<String, dynamic> tx) => {
      ...tx,
      'amount': _d(tx['amount']),
    };

class TransactionService {
  static Future<Dio> _client() => buildClient();

  static Future<Map<String, dynamic>> getSummary() async {
    final dio = await _client();
    final res = await dio.get('/reports/summary');
    final d = res.data as Map<String, dynamic>;
    final today = d['today'] as Map<String, dynamic>;
    final monthly = (d['monthly'] as List<dynamic>).map((r) {
      final row = r as Map<String, dynamic>;
      return {...row, 'total': _d(row['total'])};
    }).toList();
    return {
      'today': {'income': _d(today['income']), 'expense': _d(today['expense'])},
      'balance': _d(d['balance']),
      'monthly': monthly,
    };
  }

  static Future<List<Map<String, dynamic>>> getTransactions(
      {String? type, int limit = 20}) async {
    final dio = await _client();
    final res = await dio.get('/transactions', queryParameters: {
      'type': type,
      'limit': limit,
    });
    return (res.data as List<dynamic>)
        .map((e) => _normTx(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> addTransaction({
    required String type,
    required double amount,
    required String category,
    required String date,
    String account = 'cash',
    String? party,
    int? partyId,
    String? note,
  }) async {
    final dio = await _client();
    final res = await dio.post('/transactions', data: {
      'type': type,
      'amount': amount,
      'category': category,
      'account': account,
      'party': party,
      'party_id': partyId,
      'note': note,
      'date': date,
    });
    return _normTx(res.data as Map<String, dynamic>);
  }

  static Future<void> deleteTransaction(int id) async {
    final dio = await _client();
    await dio.delete('/transactions/$id');
  }
}
