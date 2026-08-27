import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Manual sales entry screen (TRD §5.1).
class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _revenueController = TextEditingController();
  String _unit = 'pcs';
  final String _category = 'grocery';
  bool _isSubmitting = false;

  final _units = ['pcs', 'kg', 'ltr', 'pkt', 'box', 'dozen'];

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _revenueController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _qtyController.text.isEmpty) return;
    setState(() => _isSubmitting = true);

    final storeId = context.read<AuthProvider>().storeId;
    if (storeId == null) return;

    try {
      await ApiClient.addSalesEntry(storeId, {
        'sku_name': _nameController.text.trim(),
        'sku_category': _category,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'quantity_sold': double.parse(_qtyController.text),
        'revenue': _revenueController.text.isNotEmpty ? double.parse(_revenueController.text) : null,
        'unit': _unit,
        'source': 'manual',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sales entry added successfully!')),
        );
        _nameController.clear();
        _qtyController.clear();
        _revenueController.clear();
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add entry. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: Column(
        children: [
          TerracottaAppHeader(
            title: 'Add Sales Record',
            showBack: true,
            onBack: () => context.pop(),
          ),
          const ToranGarland(height: 12, opacity: 0.8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Record a sale to calibrate accurate forecasting',
                    style: GoogleFonts.hind(fontSize: 13, color: KiranaNapseTheme.juteSoft),
                  ),
                  const SizedBox(height: 20),

                  Text('Item Name', style: GoogleFonts.hind(color: KiranaNapseTheme.jute, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.hind(color: KiranaNapseTheme.jute),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Amul Butter 500g',
                      prefixIcon: Icon(Icons.inventory_2_outlined, color: KiranaNapseTheme.juteMuted, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantity Sold', style: GoogleFonts.hind(color: KiranaNapseTheme.jute, fontSize: 12.5, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _qtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.hind(color: KiranaNapseTheme.jute),
                              decoration: const InputDecoration(hintText: '10'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Unit', style: GoogleFonts.hind(color: KiranaNapseTheme.jute, fontSize: 12.5, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: KiranaNapseTheme.riceCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: KiranaNapseTheme.sandstone),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _unit,
                                  isExpanded: true,
                                  dropdownColor: KiranaNapseTheme.riceCard,
                                  style: GoogleFonts.hind(color: KiranaNapseTheme.jute, fontWeight: FontWeight.w600),
                                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _unit = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text('Total Amount / Revenue (₹) [Optional]', style: GoogleFonts.hind(color: KiranaNapseTheme.jute, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _revenueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.hind(color: KiranaNapseTheme.jute),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 500',
                      prefixIcon: Icon(Icons.currency_rupee_rounded, color: KiranaNapseTheme.juteMuted, size: 20),
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KiranaNapseTheme.turmeric,
                        foregroundColor: const Color(0xFF4A2E0A),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A2E0A)))
                          : Text('Save Sale Entry', style: GoogleFonts.hind(fontSize: 14.5, fontWeight: FontWeight.w700)),
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
