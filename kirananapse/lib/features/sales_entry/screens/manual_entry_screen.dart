import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _revenue = TextEditingController();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _selected;
  bool _loading = true;
  bool _loadFailed = false;
  bool _saving = false;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _qty.dispose();
    _revenue.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadItems({String? selectId}) async {
    final storeId = context.read<AuthProvider>().storeId;
    if (storeId == null) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final items = await ApiClient.getItems(storeId);
      if (!mounted) return;
      setState(() {
        _items = items
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        if (selectId != null) {
          for (final item in _items) {
            if (item['id'] == selectId) _selected = item;
          }
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _addItem() async {
    final created = await context.push<Map<String, dynamic>>('/items/add');
    if (created != null && mounted) {
      await _loadItems(selectId: created['id'] as String);
    }
  }

  Future<void> _pickItem() async {
    _search.clear();
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: KiranaNapseTheme.riceCard,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final visible = _items
              .where(
                (item) => (item['name'] as String).toLowerCase().contains(
                  _search.text.toLowerCase(),
                ),
              )
              .toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                0,
                18,
                MediaQuery.of(sheetContext).viewInsets.bottom + 18,
              ),
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.68,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose an item',
                      style: GoogleFonts.baloo2(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: KiranaNapseTheme.jute,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _search,
                      autofocus: true,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search your items',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final item = visible[index];
                          return ListTile(
                            title: Text(item['name'] as String),
                            subtitle: Text(
                              '${item['category'] ?? 'Other'} · ${item['unit']}',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.pop(sheetContext, item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (picked != null && mounted) setState(() => _selected = picked);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  Future<void> _save() async {
    if (_selected == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose an item first.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final storeId = context.read<AuthProvider>().storeId;
    if (storeId == null) return;
    setState(() => _saving = true);
    try {
      await ApiClient.addSalesEntry(storeId, {
        'sku_id': _selected!['id'],
        'date':
            '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        'quantity_sold': double.parse(_qty.text.trim()),
        'revenue': _revenue.text.trim().isEmpty
            ? null
            : double.parse(_revenue.text.trim()),
        'source': 'manual',
      });
      if (!mounted) return;
      _qty.clear();
      _revenue.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sale saved for ${_selected!['name']}')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save sale. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: Column(
        children: [
          TerracottaAppHeader(
            title: 'Record a sale',
            showBack: true,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    'Select a saved item, then enter what sold.',
                    style: GoogleFonts.hind(
                      fontSize: 14,
                      color: KiranaNapseTheme.juteSoft,
                    ),
                  ),
            Text(
              'Current stock is managed in Items.',
              style: GoogleFonts.hind(
                fontSize: 12,
                color: KiranaNapseTheme.juteSoft,
              ),
            ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_loadFailed)
                    KiranaEmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Could not load items',
                      message: 'Check your connection and try again.',
                      actionLabel: 'Try again',
                      onAction: _loadItems,
                    )
                  else if (_items.isEmpty)
                    KiranaEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Add an item first',
                      message:
                          'An item is the product record. Once it is saved, you can record each sale against it.',
                      actionLabel: 'Add item',
                      onAction: _addItem,
                    )
                  else ...[
                    Text(
                      'Item',
                      style: GoogleFonts.hind(
                        fontWeight: FontWeight.w700,
                        color: KiranaNapseTheme.jute,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: _pickItem,
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _selected == null
                              ? 'Choose from your items'
                              : '${_selected!['name']} · ${_selected!['unit']}',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New product? Add item'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sale date',
                      style: GoogleFonts.hind(
                        fontWeight: FontWeight.w700,
                        color: KiranaNapseTheme.jute,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('${_date.day}/${_date.month}/${_date.year}'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _qty,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            'Quantity sold${_selected == null ? '' : ' (${_selected!['unit']})'}',
                        hintText: 'e.g. 10',
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value?.trim() ?? '');
                        return amount == null || amount <= 0
                            ? 'Enter a quantity above zero'
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _revenue,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Total amount (₹, optional)',
                        hintText: 'e.g. 500',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final amount = double.tryParse(value.trim());
                        return amount == null || amount < 0
                            ? 'Enter zero or a positive amount'
                            : null;
                      },
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: KiranaNapseTheme.terracottaDark,
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save sale',
                                style: GoogleFonts.hind(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
