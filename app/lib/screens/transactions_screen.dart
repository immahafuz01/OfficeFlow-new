import 'package:flutter/material.dart';
import '../services/transaction_service.dart';

const _incomeCategories = ['Sales', 'Service', 'Investment', 'Loan', 'Other'];
const _expenseCategories = ['Rent', 'Salary', 'Utilities', 'Supplies', 'Transport', 'Marketing', 'Other'];

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<dynamic> _transactions = [];
  bool _loading = true;
  String? _filter; // null = all, 'income', 'expense'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await TransactionService.getTransactions(type: _filter);
      setState(() => _transactions = data);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    await TransactionService.deleteTransaction(id);
    _load();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddTransactionSheet(onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [
              _chip('All', null),
              const SizedBox(width: 8),
              _chip('Income', 'income'),
              const SizedBox(width: 8),
              _chip('Expense', 'expense'),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? const Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _transactions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) => _TransactionTile(
                            tx: _transactions[i],
                            onDelete: () => _delete(_transactions[i]['id']),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _filter = value);
        _load();
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final VoidCallback onDelete;
  const _TransactionTile({required this.tx, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx['type'] == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final date = (tx['date'] as String).substring(0, 10);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
      ),
      title: Text(tx['category'] ?? 'Uncategorized',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${tx['account'] ?? 'cash'} · $date${tx['party'] != null ? ' · ${tx['party']}' : ''}',
          style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isIncome ? '+' : '-'}৳${(tx['amount'] as num).toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddTransactionSheet({required this.onSaved});

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'income';
  String? _category;
  String _account = 'cash';
  final _amountCtrl = TextEditingController();
  final _partyCtrl  = TextEditingController();
  final _noteCtrl   = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  List<String> get _categories =>
      _type == 'income' ? _incomeCategories : _expenseCategories;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await TransactionService.addTransaction(
        type: _type,
        amount: double.parse(_amountCtrl.text),
        category: _category ?? _categories.first,
        account: _account,
        party: _partyCtrl.text.isEmpty ? null : _partyCtrl.text,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        date: _date.toIso8601String().split('T').first,
      );
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Add Transaction',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            // Type toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'income',  label: Text('Income'),  icon: Icon(Icons.arrow_downward)),
                ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() { _type = s.first; _category = null; }),
            ),
            const SizedBox(height: 12),
            // Amount
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Amount (৳)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid amount' : null,
            ),
            const SizedBox(height: 12),
            // Category
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Select a category' : null,
            ),
            const SizedBox(height: 12),
            // Account
            DropdownButtonFormField<String>(
              initialValue: _account,
              decoration: const InputDecoration(labelText: 'Account', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'bank', child: Text('Bank')),
              ],
              onChanged: (v) => setState(() => _account = v!),
            ),
            const SizedBox(height: 12),
            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date: ${_date.toIso8601String().split('T').first}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            const Divider(),
            TextFormField(
              controller: _partyCtrl,
              decoration: const InputDecoration(labelText: 'Party / Customer (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Transaction'),
            ),
          ]),
        ),
      ),
    );
  }
}
