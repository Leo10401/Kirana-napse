import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/recommendation_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Overstock & Expiry screen — Screen 4.
class OverstockScreen extends StatefulWidget {
  const OverstockScreen({super.key});

  @override
  State<OverstockScreen> createState() => _OverstockScreenState();
}

class _OverstockScreenState extends State<OverstockScreen> {
  final List<Map<String, dynamic>> _fallbackItems = [
    {
      'id': 'ov_1',
      'sku_id': 'sku_cold_cream',
      'name': 'Cold cream',
      'reason': 'No sale in 3 weeks — discount suggested',
      'tagLabel': 'Slow-moving',
      'tagType': MiniTagType.warn,
    },
    {
      'id': 'ov_2',
      'sku_id': 'sku_milk',
      'name': 'Milk packets (500ml)',
      'reason': '2 days to expiry — return to distributor or discount',
      'tagLabel': 'Expiring soon',
      'tagType': MiniTagType.danger,
    },
    {
      'id': 'ov_3',
      'sku_id': 'sku_biscuits',
      'name': 'Imported butter cookies',
      'reason': 'Stop reordering until sales pick up',
      'tagLabel': 'Slow-moving',
      'tagType': MiniTagType.warn,
    },
    {
      'id': 'ov_4',
      'sku_id': 'sku_detergent',
      'name': 'Detergent bar 250g',
      'reason': 'Discount applied — sales recovering',
      'tagLabel': 'Resolved',
      'tagType': MiniTagType.success,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecommendationProvider>();
    final backendItems = rec.overstockItems;

    final displayItems = backendItems.isNotEmpty
        ? backendItems.map((item) {
            final isExpiry = item['type'] == 'expiry_risk';
            final isResolved = item['status'] == 'dismissed' || item['status'] == 'resolved';
            return {
              'id': item['id'] ?? item['sku_id'],
              'sku_id': item['sku_id'],
              'name': item['sku_name'] ?? 'Flagged Item',
              'reason': item['reason_text'] ?? (isExpiry ? 'Near expiry threshold' : 'High inventory days on hand'),
              'tagLabel': isResolved ? 'Resolved' : (isExpiry ? 'Expiring soon' : 'Slow-moving'),
              'tagType': isResolved ? MiniTagType.success : (isExpiry ? MiniTagType.danger : MiniTagType.warn),
            };
          }).toList()
        : _fallbackItems;

    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: Column(
        children: [
          // Terracotta Header with Back button
          TerracottaAppHeader(
            title: 'Overstock & expiry',
            showBack: true,
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/home');
              }
            },
          ),

          // Toran Garland Accent
          const ToranGarland(height: 12, opacity: 0.8),

          // List body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                Text(
                  '${displayItems.length} ITEMS FLAGGED',
                  style: GoogleFonts.hind(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: KiranaNapseTheme.juteSoft,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                ...displayItems.map((item) {
                  return KiranaItemCard(
                    name: item['name'] as String,
                    reason: item['reason'] as String,
                    indicator: KiranaCardIndicator.watch,
                    tag: MiniTag(
                      label: item['tagLabel'] as String,
                      type: item['tagType'] as MiniTagType,
                    ),
                    onTap: () {
                      if (item['sku_id'] != null) {
                        context.push('/item/${item['sku_id']}');
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
