import 'package:flutter/material.dart';
import '../services/party_service.dart';

class PartyDetailScreen extends StatefulWidget {
  final int partyId;
  const PartyDetailScreen({super.key, required this.partyId});

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await PartyService.getLedger(widget.partyId);
      setState(() => _data = data);
    } catch (e) {
      setState(() => _error = 'Failed to load ledger');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        )),
      );
    }

    final party = _data!['party'] as Map<String, dynamic>;
    final txs = _data!['transactions'] as List<Map<String, dynamic>>;
    final balance = _data!['balance'] as double;
    final isCustomer = party['type'] == 'customer';
    final balanceColor = balance >= 0 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(party['name'] as String),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '৳${balance.toStringAsFixed(2)}',
                style: TextStyle(
                    color: balanceColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Party info card
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor:
                        (isCustomer ? Colors.blue : Colors.orange).withValues(alpha: 0.15),
                    child: Icon(
                      isCustomer ? Icons.person_outline : Icons.store_outlined,
                      color: isCustomer ? Colors.blue : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isCustomer ? 'Customer' : 'Vendor',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      if (party['phone'] != null)
                        Text(party['phone'] as String,
                            style: const TextStyle(fontSize: 13)),
                      if (party['notes'] != null)
                        Text(party['notes'] as String,
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('Balance', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('৳${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: balanceColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ]),
                ]),
              ),
            ),
          ),
          // Ledger header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              const Expanded(child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
              const SizedBox(width: 8),
              const Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
              const SizedBox(width: 8),
              const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              const Text('Balance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
            ]),
          ),
          const Divider(height: 1),
          // Opening balance row
          if (party['opening_balance'] != 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Expanded(child: Text('—', style: TextStyle(fontSize: 12))),
                const SizedBox(width: 8),
                const Expanded(flex: 2, child: Text('Opening Balance', style: TextStyle(fontSize: 12, color: Colors.grey))),
                const SizedBox(width: 8),
                const Text('—', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Text('৳${(party['opening_balance'] as double).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ),
            const Divider(height: 1),
          ],
          // Transactions
          Expanded(
            child: txs.isEmpty
                ? const Center(
                    child: Text('No transactions linked to this party.',
                        style: TextStyle(color: Colors.grey)))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: txs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final tx = txs[i];
                        final isIncome = tx['type'] == 'income';
                        final color = isIncome ? Colors.green : Colors.red;
                        final rb = tx['running_balance'] as double;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(children: [
                            Expanded(
                              child: Text(
                                (tx['date'] as String).substring(5), // MM-DD
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tx['category'] ?? '—',
                                      style: const TextStyle(fontSize: 12)),
                                  if (tx['note'] != null)
                                    Text(tx['note'] as String,
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${isIncome ? '+' : '-'}৳${(tx['amount'] as double).toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '৳${rb.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: rb >= 0 ? Colors.green : Colors.red),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
