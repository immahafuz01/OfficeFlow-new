import 'package:flutter/material.dart';
import '../services/invoice_service.dart';
import '../services/party_service.dart';

const _statusColors = {
  'paid': Colors.green,
  'unpaid': Colors.orange,
  'overdue': Colors.red,
};

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  Map<String, dynamic>? _invoice;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final inv = await InvoiceService.getInvoice(widget.invoiceId);
      setState(() => _invoice = inv);
    } catch (e) {
      setState(() => _error = 'Failed to load invoice');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text(
            'This will permanently delete the invoice. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await InvoiceService.deleteInvoice(widget.invoiceId);
    if (mounted) Navigator.pop(context, 'deleted');
  }

  Future<void> _updateStatus(String status) async {
    await InvoiceService.updateStatus(widget.invoiceId, status);
    _load();
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EditInvoiceSheet(
        invoice: _invoice!,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    }

    final inv = _invoice!;
    final status = inv['status'] as String;
    final statusColor = _statusColors[status] ?? Colors.grey;
    final items = (inv['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final total = inv['total'] as double;
    final due = (inv['due_date'] as String?)?.substring(0, 10) ?? '—';
    final created = (inv['created_at'] as String?)?.substring(0, 10) ?? '—';
    final invoiceNum = inv['invoice_number'] as String? ?? '—';
    final partyName = inv['party_name'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(invoiceNum),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: _openEditSheet),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: _delete),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            inv['client_name'] as String,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          _StatusChip(
                              status: status,
                              color: statusColor,
                              onChanged: _updateStatus),
                        ],
                      ),
                      if (partyName != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.people_outline,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(partyName,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ]),
                      ],
                      const Divider(height: 24),
                      _InfoRow(label: 'Invoice #', value: invoiceNum),
                      _InfoRow(label: 'Issued', value: created),
                      _InfoRow(label: 'Due', value: due),
                    ]),
              ),
            ),
            const SizedBox(height: 12),

            // Line items card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Items',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      // Header row
                      const Row(children: [
                        Expanded(
                            flex: 4,
                            child: Text('Description',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600))),
                        Expanded(
                            child: Text('Qty',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600))),
                        Expanded(
                            flex: 2,
                            child: Text('Price',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600))),
                        Expanded(
                            flex: 2,
                            child: Text('Total',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600))),
                      ]),
                      const Divider(),
                      if (items.isEmpty)
                        const Text('No items',
                            style: TextStyle(color: Colors.grey))
                      else
                        ...items.map((item) {
                          final qty =
                              num.tryParse(item['qty']?.toString() ?? '1')
                                      ?.toDouble() ??
                                  1.0;
                          final price =
                              num.tryParse(item['price']?.toString() ?? '0')
                                      ?.toDouble() ??
                                  0.0;
                          final lineTotal = qty * price;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(children: [
                              Expanded(
                                  flex: 4,
                                  child: Text(item['name']?.toString() ?? '—',
                                      style:
                                          const TextStyle(fontSize: 13))),
                              Expanded(
                                  child: Text(qty.toStringAsFixed(0),
                                      textAlign: TextAlign.center,
                                      style:
                                          const TextStyle(fontSize: 13))),
                              Expanded(
                                  flex: 2,
                                  child: Text(
                                      '৳${price.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style:
                                          const TextStyle(fontSize: 13))),
                              Expanded(
                                  flex: 2,
                                  child: Text(
                                      '৳${lineTotal.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600))),
                            ]),
                          );
                        }),
                      const Divider(),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text('৳${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ]),
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status chip with dropdown ───────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  final ValueChanged<String> onChanged;
  const _StatusChip(
      {required this.status,
      required this.color,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'unpaid', child: Text('Unpaid')),
        PopupMenuItem(value: 'paid', child: Text('Paid')),
        PopupMenuItem(value: 'overdue', child: Text('Overdue')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(status,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, color: color, size: 18),
        ]),
      ),
    );
  }
}

// ─── Info row helper ─────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Edit Invoice Sheet ───────────────────────────────────────────────────────

class _EditInvoiceSheet extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onSaved;
  const _EditInvoiceSheet({required this.invoice, required this.onSaved});

  @override
  State<_EditInvoiceSheet> createState() => _EditInvoiceSheetState();
}

class _EditInvoiceSheetState extends State<_EditInvoiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clientCtrl;
  late DateTime _dueDate;
  late List<_ItemRow> _items;
  List<Map<String, dynamic>> _parties = [];
  int? _selectedPartyId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _clientCtrl = TextEditingController(
        text: widget.invoice['client_name'] as String);
    final rawDate = widget.invoice['due_date'] as String?;
    _dueDate = rawDate != null
        ? DateTime.tryParse(rawDate) ?? DateTime.now().add(const Duration(days: 7))
        : DateTime.now().add(const Duration(days: 7));
    _selectedPartyId = widget.invoice['party_id'] as int?;

    // Pre-fill items
    final rawItems =
        (widget.invoice['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    _items = rawItems.isNotEmpty
        ? rawItems
            .map((e) => _ItemRow(
                  nameCtrl: TextEditingController(
                      text: e['name']?.toString() ?? ''),
                  qtyCtrl: TextEditingController(
                      text: (e['qty'] ?? 1).toString()),
                  priceCtrl: TextEditingController(
                      text: (e['price'] ?? 0).toString()),
                ))
            .toList()
        : [_ItemRow.empty()];

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
      await InvoiceService.editInvoice(
        widget.invoice['id'] as int,
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Edit Invoice',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientCtrl,
              decoration: const InputDecoration(
                  labelText: 'Client Name', border: OutlineInputBorder()),
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
                onChanged: (v) => setState(() => _selectedPartyId = v),
              ),
            const SizedBox(height: 12),
            // Items
            const Text('Items',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._items.asMap().entries.map((e) => _ItemRowWidget(
                  row: e.value,
                  canRemove: _items.length > 1,
                  onRemove: () => setState(() => _items.removeAt(e.key)),
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
            // Due date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  'Due: ${_dueDate.toIso8601String().split('T').first}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
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
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Changes'),
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
