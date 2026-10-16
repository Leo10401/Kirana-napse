import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Distributor Export screen — formatted preview + share (AppFlow §5.3, §7 Screen 7).
class DistributorExportScreen extends StatefulWidget {
  const DistributorExportScreen({super.key});

  @override
  State<DistributorExportScreen> createState() =>
      _DistributorExportScreenState();
}

class _DistributorExportScreenState extends State<DistributorExportScreen> {
  Map<String, dynamic>? _exportData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExport();
  }

  Future<void> _loadExport() async {
    final storeId = context.read<AuthProvider>().storeId;
    if (storeId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Sign in to load your order list.';
      });
      return;
    }
    try {
      final data = await ApiClient.getDistributorList(storeId);
      if (!mounted) return;
      setState(() {
        _exportData = data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      final message = switch (e) {
        DioException(response: final response)
            when response?.statusCode == 401 =>
          'Your session expired. Sign in again to load the order list.',
        DioException(response: final response)
            when response?.statusCode == 403 =>
          'This order list belongs to another store account.',
        DioException(response: final response)
            when response?.statusCode == 500 =>
          'The server could not prepare the order list. Try again.',
        DioException(response: null) =>
          'Cannot reach the server. Check your connection and try again.',
        _ => 'Could not load the order list. Try again.',
      };
      setState(() {
        _isLoading = false;
        _error = message;
      });
    }
  }

  void _shareViaWhatsApp() {
    final storeName = _exportData?['store_name'] ?? 'Your store';
    final items = _exportData?['items'] as List? ?? [];
    if (items.isEmpty) return;
    final buffer = StringBuffer();
    buffer.writeln('🛒 *Order List — $storeName*');
    buffer.writeln(
      '📅 Date: ${DateTime.now().toLocal().toString().substring(0, 10)}\n',
    );
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final name = item['sku_name'] ?? 'Item';
      final qty = item['quantity'] ?? item['suggested_qty'] ?? 1;
      final unit = item['unit'] ?? 'pcs';
      buffer.writeln('${i + 1}. $name — $qty $unit');
    }
    buffer.writeln('\n_Generated via Kirana-Napse_');
    Share.share(buffer.toString(), subject: 'Kirana Order List');
  }

  @override
  Widget build(BuildContext context) {
    final items = _exportData?['items'] as List? ?? [];
    final storeName = _exportData?['store_name'] ?? 'Your store';

    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: Column(
        children: [
          // Terracotta Header with Back button
          TerracottaAppHeader(
            title: 'Export Order List',
            showBack: true,
            onBack: () => context.pop(),
          ),

          // Toran Garland
          const ToranGarland(height: 12, opacity: 0.8),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: KiranaNapseTheme.terracotta,
                    ),
                  )
                : _error != null || items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: KiranaEmptyState(
                        icon: _error == null
                            ? Icons.receipt_long_outlined
                            : Icons.wifi_off_rounded,
                        title: _error == null
                            ? 'Order list is empty'
                            : 'Could not load your order list',
                        message:
                            _error ??
                            'Reorder suggestions will appear here when they are ready to share.',
                        actionLabel: _error == null ? null : 'Try again',
                        onAction: _error == null
                            ? null
                            : () {
                                setState(() => _isLoading = true);
                                _loadExport();
                              },
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Bill/Receipt Preview Box
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: KiranaNapseTheme.riceCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: KiranaNapseTheme.sandstone,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.receipt_long_rounded,
                                    color: KiranaNapseTheme.terracotta,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      storeName,
                                      style: GoogleFonts.baloo2(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: KiranaNapseTheme.jute,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${items.length} items • ${DateTime.now().toLocal().toString().substring(0, 10)}',
                                style: GoogleFonts.hind(
                                  fontSize: 12,
                                  color: KiranaNapseTheme.juteSoft,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Divider(color: KiranaNapseTheme.sandstone),
                              const SizedBox(height: 10),

                              ...items.asMap().entries.map((entry) {
                                final i = entry.key;
                                final item = entry.value;
                                final qty =
                                    item['quantity'] ??
                                    item['suggested_qty'] ??
                                    1;
                                final unit = item['unit'] ?? 'pcs';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        child: Text(
                                          '${i + 1}.',
                                          style: GoogleFonts.hind(
                                            fontSize: 12.5,
                                            color: KiranaNapseTheme.juteSoft,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          item['sku_name'] ?? '',
                                          style: GoogleFonts.hind(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                            color: KiranaNapseTheme.jute,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$qty $unit',
                                        style: GoogleFonts.hind(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              KiranaNapseTheme.terracottaDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KiranaNapseTheme.turmeric,
                              foregroundColor: const Color(0xFF4A2E0A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _shareViaWhatsApp,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.share_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Share on WhatsApp / SMS',
                                  style: GoogleFonts.hind(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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
