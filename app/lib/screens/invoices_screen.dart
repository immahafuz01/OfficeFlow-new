import 'package:flutter/material.dart';
import '../services/invoice_service.dart';
import '../services/party_service.dart';
import 'invoice_detail_screen.dart';

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

class _InvoicesScreenState extends State<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _invoices = [];
  bool _loading = true;
  String? _filterStatus; // null = all

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        final statuses = [null, 'unpaid', 'paid', 'overdue'];
        setState(() => _filterStatus = statuses[_tabs.index]);
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data =
          await InvoiceService.getInvoices(status: _filterStatus);
      setState(() => _invoices = data);
    } finally {
      setState(() => _loading = false);
    }
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

  void _openDetail(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(invoiceId: id)),
    );
    if (result == 'deleted' || result == null) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Status filter tabs
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Unpaid'),
              Tab(text: 'Paid'),
              Tab(text: 'Overdue'),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _invoices.isEmpty
                    ? const Center(
                        child: Text('No invoices.',
                            style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _invoices.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) => _InvoiceTile(
                            invoice: _invoices[i],
                            onTap: () =>
                                _openDetail(_invoices[i]['id'] as int),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }
}

// ─── Invoice tile ─────────────────────────────────────────────────────────────

class _InvoiceTile extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onTap;

  const _InvoiceTile({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = invoice['status'] as String;
    final color = _statusColors[status] ?? Colors.grey;
    final due = (invoice['due_date'] as String?)?.substring(0, 10) ?? '—';
    final total = invoice['total'] as double;
    final invoiceNum = invoice['invoice_number'] as String? ?? '—';
    final partyName = invoice['party_name'] as String?;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(Icons.description_outlined, color: color, size: 18),
      ),
      title: Row(children: [
        Expanded(
          child: Text(invoice['client_name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Text('৳${total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(invoiceNum,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 8),
            if (partyName != null)
              Row(children: [
                const Icon(Icons.people_outline,
                    size: 11, color: Colors.grey),
                const SizedBox(width: 2),
                Text(partyName,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ]),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Due: $due',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}

// ─── Add Invoice Sheet ────────────────────────────────────────────────────────

class _AddInvoiceSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddInvoiceSheet({required this.onSaved});

  @override
  State<_AddInvoiceSheet> createState() => _AddInvoiceSheetState();
}

class _AddInvoiceSheetState extends State<_AddInvoiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _clientCtrl = TextEditingController();
  final List<_ItemRow> _items = [_ItemRow.empty()];
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  List<Map<String, dynamic>> _parties = [];
  int? _selectedPartyId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  Future<void> _loadParties() async {
    try {
      final list = await PartyService.getParties();
      if (mounted) setState(() => _parties = list);
    } catch (_) {}
  }

  double get _total => _items.fold(0.0, (sum, row) {
        final qty = double.tryParse(row.qtyCtrl.text) ?? 0;
        final price = double.tryParse(row.priceCtrl.text) ?? 0;
        return sum + qty * price;
      });

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final items = _items
          .map((r) => {
                'name': r.nameCtrl.text,
                'qty': double.tryParse(r.qtyCtrl.text) ?? 1,
                'price': double.tryParse(r.priceCtrl.text) ?? 0,
              })
          .toList();
      await InvoiceService.addInvoice(
        clientName: _clientCtrl.text,
        items: items,
        total: _total,
        dueDate: _dueDate.toIso8601String().split('T').first,
        partyId: _selectedPartyId,
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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('New Invoice',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clientCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Client Name',
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                // Party dropdown
                if (_parties.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    value: _selectedPartyId,
                    decoration: const InputDecoration(
                        labelText: 'Linked Party (optional)',
                        border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('— None —')),
                      ..._parties.map((p) => DropdownMenuItem<int?>(
                            value: p['id'] as int,
                            child: Text(p['name'] as String),
                          )),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedPartyId = v),
                  ),
                const SizedBox(height: 12),
                // Items
                const Text('Items',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._items.asMap().entries.map((e) => _ItemRowWidget(
                      row: e.value,
                      canRemove: _items.length > 1,
                      onRemove: () =>
                          setState(() => _items.removeAt(e.key)),
                      onChanged: () => setState(() {}),
                    )),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _items.add(_ItemRow.empty())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Item'),
                ),
                const SizedBox(height: 4),
                Text('Total: ৳${_total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      'Due: ${_dueDate.toIso8601String().split('T').first}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 730)),
                    );
                    if (d != null) setState(() => _dueDate = d);
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14)),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : const Text('Create Invoice'),
                ),
              ]),
        ),
      ),
    );
  }
}

// ─── Item row model & widget ──────────────────────────────────────────────────

class _ItemRow {
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  _ItemRow(
      {required this.nameCtrl,
      required this.qtyCtrl,
      required this.priceCtrl});

  factory _ItemRow.empty() => _ItemRow(
        nameCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(text: '1'),
        priceCtrl: TextEditingController(),
      );
}

class _ItemRowWidget extends StatelessWidget {
  final _ItemRow row;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ItemRowWidget(
      {required this.row,
      required this.canRemove,
      required this.onRemove,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 4,
          child: TextFormField(
            controller: row.nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                isDense: true),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextFormField(
            controller: row.qtyCtrl,
            decoration: const InputDecoration(
                labelText: 'Qty',
                border: OutlineInputBorder(),
                isDense: true),
            keyboardType: TextInputType.number,
            validator: (v) =>
                double.tryParse(v ?? '') == null ? 'Invalid' : null,
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: row.priceCtrl,
            decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                isDense: true),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            validator: (v) =>
                double.tryParse(v ?? '') == null ? 'Invalid' : null,
            onChanged: (_) => onChanged(),
          ),
        ),
        if (canRemove)
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: Colors.red, size: 20),
            onPressed: onRemove,
            padding: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(),
          )
        else
          const SizedBox(width: 32),
      ]),
    );
  }
}
