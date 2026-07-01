import 'package:dio/dio.dart';
import 'dio_client.dart';

// Safely coerce a value to double
double _d(dynamic v) => v == null ? 0.0 : num.parse(v.toString()).toDouble();

// Normalize numeric fields from the API
Map<String, dynamic> _norm(Map<String, dynamic> inv) => {
      ...inv,
      'total': _d(inv['total']),
    };

class InvoiceService {
  static Future<Dio> _client() => buildClient();

  /// List invoices. Optionally filter by [status] and/or [partyId].
  static Future<List<Map<String, dynamic>>> getInvoices({
    String? status,
    int? partyId,
  }) async {
    final dio = await _client();
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (partyId != null) params['party_id'] = partyId;
    final res = await dio.get('/invoices', queryParameters: params);
    return (res.data as List)
        .map((e) => _norm(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single invoice by [id].
  static Future<Map<String, dynamic>> getInvoice(int id) async {
    final dio = await _client();
    final res = await dio.get('/invoices/$id');
    return _norm(res.data as Map<String, dynamic>);
  }

  /// Create a new invoice.
  static Future<Map<String, dynamic>> addInvoice({
    required String clientName,
    required List<Map<String, dynamic>> items,
    required double total,
    required String dueDate,
    String status = 'unpaid',
    int? partyId,
  }) async {
    final dio = await _client();
    final res = await dio.post('/invoices', data: {
      'client_name': clientName,
      'items': items,
      'total': total,
      'status': status,
      'due_date': dueDate,
      if (partyId != null) 'party_id': partyId,
    });
    return _norm(res.data as Map<String, dynamic>);
  }

  /// Edit an existing invoice. Only provided fields are updated.
  static Future<Map<String, dynamic>> editInvoice(
    int id, {
    String? clientName,
    List<Map<String, dynamic>>? items,
    double? total,
    String? dueDate,
    String? status,
    int? partyId,
  }) async {
    final dio = await _client();
    final body = <String, dynamic>{};
    if (clientName != null) body['client_name'] = clientName;
    if (items != null) body['items'] = items;
    if (total != null) body['total'] = total;
    if (dueDate != null) body['due_date'] = dueDate;
    if (status != null) body['status'] = status;
    if (partyId != null) body['party_id'] = partyId;
    final res = await dio.patch('/invoices/$id', data: body);
    return _norm(res.data as Map<String, dynamic>);
  }

  /// Quick status-only update.
  static Future<void> updateStatus(int id, String status) async {
    final dio = await _client();
    await dio.patch('/invoices/$id/status', data: {'status': status});
  }

  /// Delete an invoice.
  static Future<void> deleteInvoice(int id) async {
    final dio = await _client();
    await dio.delete('/invoices/$id');
  }
}
