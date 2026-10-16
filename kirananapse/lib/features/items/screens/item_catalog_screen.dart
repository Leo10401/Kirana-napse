import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

class ItemCatalogScreen extends StatefulWidget {
  const ItemCatalogScreen({super.key});

  @override
  State<ItemCatalogScreen> createState() => _ItemCatalogScreenState();
}

class _ItemCatalogScreenState extends State<ItemCatalogScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _failed = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storeId = context.read<AuthProvider>().storeId;
    if (storeId == null) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await ApiClient.getItems(storeId);
      if (mounted) {
        setState(() {
          _items = result
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _addItem() async {
    final created = await context.push<Map<String, dynamic>>('/items/add');
    if (created != null && mounted) await _load();
  }

  Future<void> _setStock(Map<String, dynamic> item) async {
    final controller = TextEditingController(
      text: item['quantity_on_hand']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final quantity = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Set stock · ${item['name']}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Current stock (${item['unit']})',
            ),
            validator: (value) {
              final amount = double.tryParse(value?.trim() ?? '');
              return amount == null || amount < 0
                  ? 'Enter zero or a positive number'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  dialogContext,
                  double.parse(controller.text.trim()),
                );
              }
            },
            child: const Text('Save stock'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (quantity == null || !mounted) return;
    try {
      final storeId = context.read<AuthProvider>().storeId!;
      await ApiClient.updateStock(storeId, item['id'] as String, quantity);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update stock. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items
        .where(
          (item) => (item['name'] as String).toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: Column(
        children: [
          TerracottaAppHeader(
            title: 'Items',
            subtitle: '${_items.length} products in your store',
            trailing: IconButton.filledTonal(
              tooltip: 'Add item',
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                children: [
                  Text(
                    'Your item records',
                    style: GoogleFonts.baloo2(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: KiranaNapseTheme.jute,
                    ),
                  ),
                  Text(
                    'Add each product once. Record sales against it as they happen.',
                    style: GoogleFonts.hind(
                      fontSize: 13,
                      color: KiranaNapseTheme.juteSoft,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search items',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_failed)
                    KiranaEmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Could not load items',
                      message: 'Check your connection and try again.',
                      actionLabel: 'Try again',
                      onAction: _load,
                    )
                  else if (_items.isEmpty)
                    KiranaEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No items yet',
                      message:
                          'Add your first product to start recording its sales and stock.',
                      actionLabel: 'Add first item',
                      onAction: _addItem,
                    )
                  else if (visible.isEmpty)
                    const KiranaEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matching items',
                      message: 'Try another name.',
                    )
                  else
                    ...visible.map((item) {
                      final stock = item['quantity_on_hand'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: KiranaNapseTheme.riceCard,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => _setStock(item),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: KiranaNapseTheme.sandstone,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.inventory_2_outlined,
                                    color: KiranaNapseTheme.terracottaDark,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] as String,
                                          style: GoogleFonts.hind(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: KiranaNapseTheme.jute,
                                          ),
                                        ),
                                        Text(
                                          '${item['category'] ?? 'Other'} · ${item['unit']} · ${item['supplier_lead_time_days']} day lead',
                                          style: GoogleFonts.hind(
                                            fontSize: 12,
                                            color: KiranaNapseTheme.juteSoft,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        stock == null
                                            ? 'Set stock'
                                            : '$stock ${item['unit']}',
                                        style: GoogleFonts.hind(
                                          fontWeight: FontWeight.w700,
                                          color:
                                              KiranaNapseTheme.terracottaDark,
                                        ),
                                      ),
                                      Text(
                                        'current',
                                        style: GoogleFonts.hind(
                                          fontSize: 11,
                                          color: KiranaNapseTheme.juteSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  if (!_loading && !_failed && _items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add another item'),
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
