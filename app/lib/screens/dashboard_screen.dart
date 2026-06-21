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
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await TransactionService.getSummary();
      setState(() => _summary = data);
    } catch (e) {
      setState(() => _error = 'Failed to load data');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ));
    }

    final today = _summary!['today'] as Map<String, dynamic>;
    final balance = (_summary!['balance'] as num).toDouble();
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
              amount: (today['income'] as num).toDouble(),
              color: Colors.green,
              icon: Icons.arrow_downward,
            )),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(
              label: "Today's Expense",
              amount: (today['expense'] as num).toDouble(),
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
      data[m]![row['type'] as String] = (row['total'] as num).toDouble();
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
