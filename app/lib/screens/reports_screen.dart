import 'package:flutter/material.dart';
import '../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late int _month;
  late int _year;

  Map<String, dynamic>? _pl;
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ReportService.getProfitLoss(_month, _year),
        ReportService.getCategories(_month, _year),
      ]);
      setState(() {
        _pl = results[0] as Map<String, dynamic>;
        _categories = results[1] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      setState(() => _error = 'Failed to load reports');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) { _month = 12; _year--; }
      else { _month--; }
    });
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_year == now.year && _month == now.month) return;
    setState(() {
      if (_month == 12) { _month = 1; _year++; }
      else { _month++; }
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = '${_monthName(_month)} $_year';
    return Scaffold(
      body: Column(
        children: [
          // Month navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                Text(monthLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _PLCard(pl: _pl!),
                            const SizedBox(height: 20),
                            const Text('Category Breakdown',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            if (_categories.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                    child: Text('No data for this month.',
                                        style: TextStyle(color: Colors.grey))),
                              )
                            else
                              ..._categories.map((c) => _CategoryRow(cat: c)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

class _PLCard extends StatelessWidget {
  final Map<String, dynamic> pl;
  const _PLCard({required this.pl});

  @override
  Widget build(BuildContext context) {
    final profit = pl['profit'] as double;
    final isPositive = profit >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('Profit & Loss',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Divider(height: 20),
          _PLRow('Income', pl['income'] as double, Colors.green),
          const SizedBox(height: 8),
          _PLRow('Expense', pl['expense'] as double, Colors.red),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Net Profit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                '${isPositive ? '+' : ''}৳${profit.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

class _PLRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _PLRow(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text('৳${amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Map<String, dynamic> cat;
  const _CategoryRow({required this.cat});

  @override
  Widget build(BuildContext context) {
    final isIncome = cat['type'] == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(cat['category'] ?? 'Uncategorized',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(
            '${isIncome ? '+' : '-'}৳${(cat['total'] as double).toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
