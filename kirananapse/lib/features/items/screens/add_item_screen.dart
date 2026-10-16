import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _category = TextEditingController(text: 'grocery');
  final _stock = TextEditingController();
  final _leadDays = TextEditingController(text: '2');
  String _unit = 'pcs';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _stock.dispose();
    _leadDays.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final storeId = context.read<AuthProvider>().storeId;
    if (storeId == null) return;
    setState(() => _saving = true);
    try {
      final item = await ApiClient.createItem(storeId, {
        'name': _name.text.trim(),
        'category': _category.text.trim(),
        'unit': _unit,
        if (_stock.text.trim().isNotEmpty)
          'quantity_on_hand': double.parse(_stock.text.trim()),
        'supplier_lead_time_days': int.parse(_leadDays.text.trim()),
      });
      if (mounted) context.pop(item);
    } on DioException catch (error) {
      if (!mounted) return;
      final duplicate = error.response?.statusCode == 409;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            duplicate
                ? 'This item already exists. Choose it from your item list.'
                : 'Could not save the item. Try again.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the item. Try again.')),
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
            title: 'Add item',
            subtitle: 'Save a product once, then use it for every sale',
            showBack: true,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const KiranaEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Item record',
                    message:
                        'This is the product in your store. Enter its current stock here; each sale will refer to this item.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Item name',
                      hintText: 'e.g. Amul Butter 500g',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter an item name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _category,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      hintText: 'e.g. Dairy',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a category'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Selling unit',
                    ),
                    items: const ['pcs', 'kg', 'ltr', 'pkt', 'box', 'dozen']
                        .map(
                          (unit) =>
                              DropdownMenuItem(value: unit, child: Text(unit)),
                        )
                        .toList(),
                    onChanged: (unit) => setState(() => _unit = unit ?? 'pcs'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _stock,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Current stock (optional)',
                      hintText: 'e.g. 24',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final amount = double.tryParse(value.trim());
                      return amount == null || amount < 0
                          ? 'Enter zero or a positive number'
                          : null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _leadDays,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Supplier lead time (days)',
                    ),
                    validator: (value) {
                      final days = int.tryParse(value?.trim() ?? '');
                      return days == null || days < 1 || days > 365
                          ? 'Enter 1 to 365 days'
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
                              'Save item',
                              style: GoogleFonts.hind(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
