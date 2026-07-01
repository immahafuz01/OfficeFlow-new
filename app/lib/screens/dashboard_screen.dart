import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/transaction_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _summary;
  bool _loading = true;
  bool _slowLoad = false;   // shows "waking up" hint after 5s
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _slowLoad = false; });

    // After 5 seconds still loading → show the "server is waking up" hint
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _loading) setState(() => _slowLoad = true);
    });

    try {
      final data = await TransactionService.getSummary();
      setState(() => _summary = data);
    } catch (e) {
      setState(() => _error = 'Could not reach the server.\nTap Retry — it may need a moment to wake up.');
    } finally {
      setState(() { _loading = false; _slowLoad = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          if (_slowLoad) ...[
            const SizedBox(height: 20),
            const Text(
              'Server is waking up…\nThis takes up to 60s on first load.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ]),
      );
    }
    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ));
    }

    final today = _summary!['today'] as Map<String, dynamic>;
    final balance = (_summary!['balance'] as double);
    final monthly = _summary!['monthly'] as List<dynamic>;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Balance card
          _BalanceCard(balance: balance),
          const SizedBox(height: 16),
          // Today row
          Row(children: [
            Expanded(child: _SummaryCard(
              label: "Today's Income",
              amount: today['income'] as double,
              color: Colors.green,
              icon: Icons.arrow_downward,
            )),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(
              label: "Today's Expense",
              amount: today['expense'] as double,
              color: Colors.red,
              icon: Icons.arrow_upward,
            )),
          ]),
          const SizedBox(height: 24),
          const Text('Cash Flow (Last 6 Months)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _CashFlowChart(monthly: monthly),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total Balance',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('৳ ${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _SummaryCard({required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          ]),
          const SizedBox(height: 6),
          Text('৳ ${amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ]),
      ),
    );
  }
}

class _CashFlowChart extends StatelessWidget {
  final List<dynamic> monthly;
  const _CashFlowChart({required this.monthly});

  @override
  Widget build(BuildContext context) {
    // Build a map: month -> {income, expense}
    final Map<String, Map<String, double>> data = {};
    for (final row in monthly) {
      final m = row['month'] as String;
      data.putIfAbsent(m, () => {'income': 0, 'expense': 0});
      data[m]![row['type'] as String] = row['total'] as double;
    }

    final months = data.keys.toList()..sort();
    if (months.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No data yet', style: TextStyle(color: Colors.grey))),
      );
    }

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (int i = 0; i < months.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), data[months[i]]!['income']!));
      expenseSpots.add(FlSpot(i.toDouble(), data[months[i]]!['expense']!));
    }

    return SizedBox(
      height: 200,
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= months.length) return const SizedBox();
                return Text(months[idx].substring(5),
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.1),
            ),
          ),
        ],
      )),
    );
  }
}
