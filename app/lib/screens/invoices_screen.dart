import 'package:flutter/material.dart';
import '../services/invoice_service.dart';

const _statusColors = {
  'paid': Colors.green,
  'unpaid': Colors.orange,
  'overdue': Colors.red,
};

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await InvoiceService.getInvoices();
      setState(() => _invoices = data);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    await InvoiceService.deleteInvoice(id);
    _load();
  }

  Future<void> _cycleStatus(int id, String current) async {
    const order = ['unpaid', 'paid', 'overdue'];
    final next = order[(order.indexOf(current) + 1) % order.length];
    await InvoiceService.updateStatus(id, next);
    _load();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddInvoiceSheet(onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? const Center(
                  child: Text('No invoices yet.', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _invoices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _InvoiceTile(
                      invoice: _invoices[i],
                      onDelete: () => _delete(_invoices[i]['id']),
                      onStatusTap: () =>
                          _cycleStatus(_invoices[i]['id'], _invoices[i]['status']),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onDelete;
  final VoidCallback onStatusTap;
  const _InvoiceTile(
      {required this.invoice, required this.onDelete, required this.onStatusTap});

  @override
  Widget build(BuildContext context) {
    final status = invoice['status'] as String;
    final color = _statusColors[status] ?? Colors.grey;
    final due = (invoice['due_date'] as String?)?.substring(0, 10) ?? '—';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(Icons.description_outlined, color: color, size: 18),
      ),
      title: Text(invoice['client_name'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Due: $due',
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('৳${(invoice['total'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: onStatusTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
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

class _AddInvoiceSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddInvoiceSheet({required this.onSaved});

  @override
  State<_AddInvoiceSheet> createState() => _AddInvoiceSheetState();
}

class _AddInvoiceSheetState extends State<_AddInvoiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _clientCtrl = TextEditingController();
  // Single line-item for simplicity; user can expand later
  final _itemNameCtrl = TextEditingController();
  final _itemQtyCtrl = TextEditingController(text: '1');
  final _itemPriceCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  double get _total {
    final qty = double.tryParse(_itemQtyCtrl.text) ?? 1;
    final price = double.tryParse(_itemPriceCtrl.text) ?? 0;
    return qty * price;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await InvoiceService.addInvoice(
        clientName: _clientCtrl.text,
        items: [
          {
            'name': _itemNameCtrl.text,
            'qty': double.parse(_itemQtyCtrl.text),
            'price': double.parse(_itemPriceCtrl.text),
          }
        ],
        total: _total,
        dueDate: _dueDate.toIso8601String().split('T').first,
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
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('New Invoice',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientCtrl,
              decoration: const InputDecoration(
                  labelText: 'Client Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            const Text('Item', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _itemNameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _itemQtyCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Qty', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Invalid' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _itemPriceCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Unit Price (৳)', border: OutlineInputBorder()),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Invalid' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text('Total: ৳${_total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  'Due Date: ${_dueDate.toIso8601String().split('T').first}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _dueDate = d);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Invoice'),
            ),
          ]),
        ),
      ),
    );
  }
}
