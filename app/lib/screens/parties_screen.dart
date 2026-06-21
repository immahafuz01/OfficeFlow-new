import 'package:flutter/material.dart';
import '../services/party_service.dart';
import 'party_detail_screen.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  List<Map<String, dynamic>> _parties = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await PartyService.getParties();
      setState(() => _parties = data);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    await PartyService.deleteParty(id);
    _load();
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddPartySheet(onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _parties.isEmpty
              ? const Center(
                  child: Text('No parties yet.', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _parties.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = _parties[i];
                      final balance = p['balance'] as double? ?? 0.0;
                      final isCustomer = p['type'] == 'customer';
                      final balanceColor = balance >= 0 ? Colors.green : Colors.red;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              (isCustomer ? Colors.blue : Colors.orange)
                                  .withValues(alpha: 0.15),
                          child: Icon(
                            isCustomer ? Icons.person_outline : Icons.store_outlined,
                            color: isCustomer ? Colors.blue : Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(p['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${isCustomer ? 'Customer' : 'Vendor'}${p['phone'] != null ? ' · ${p['phone']}' : ''}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '৳${balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: balanceColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.grey),
                              onPressed: () => _delete(p['id'] as int),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PartyDetailScreen(partyId: p['id'] as int)),
                        ).then((_) => _load()),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Party'),
      ),
    );
  }
}

class _AddPartySheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddPartySheet({required this.onSaved});

  @override
  State<_AddPartySheet> createState() => _AddPartySheetState();
}

class _AddPartySheetState extends State<_AddPartySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  String _type = 'customer';
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await PartyService.addParty(
        name: _nameCtrl.text,
        phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
        type: _type,
        openingBalance: double.tryParse(_balanceCtrl.text) ?? 0,
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
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
            const Text('Add Party',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'customer', label: Text('Customer'), icon: Icon(Icons.person_outline)),
                ButtonSegment(value: 'vendor', label: Text('Vendor'), icon: Icon(Icons.store_outlined)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone (optional)', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _balanceCtrl,
              decoration: const InputDecoration(
                  labelText: 'Opening Balance (৳)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Party'),
            ),
          ]),
        ),
      ),
    );
  }
}
