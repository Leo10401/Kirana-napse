import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/recommendation_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Shows the recommendation selected from the current dashboard or list.
class ItemDetailScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? item;
    for (final candidate
        in context.watch<RecommendationProvider>().recommendations) {
      if (candidate['sku_id'] == itemId) {
        item = candidate;
        break;
      }
    }

    final name = item?['sku_name']?.toString() ?? 'Item';
    final type = item?['type']?.toString() ?? '';
    final isReorder = type == 'reorder' || type == 'low_stock';
    final quantity = item?['owner_edited_qty'] ?? item?['suggested_qty'] ?? 0;
    final unit = item?['sku_unit']?.toString() ?? 'pcs';

    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: Column(
        children: [
          TerracottaAppHeader(
            title: 'Item Detail',
            showBack: true,
            onBack: () => context.pop(),
            trailing: item == null
                ? null
                : IconButton(
                    tooltip: 'Flag this recommendation',
                    onPressed: () => context.push('/feedback/${item!['id']}'),
                    icon: const Icon(Icons.flag_outlined, color: Colors.white),
                  ),
          ),
          const ToranGarland(height: 12, opacity: 0.8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: item == null
                  ? Text(
                      'This recommendation is no longer available.',
                      style: GoogleFonts.hind(
                        fontSize: 14,
                        color: KiranaNapseTheme.juteSoft,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: KiranaNapseTheme.riceCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: KiranaNapseTheme.sandstone,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.baloo2(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: KiranaNapseTheme.jute,
                                ),
                              ),
                              Text(
                                item['sku_category']?.toString() ??
                                    'Inventory item',
                                style: GoogleFonts.hind(
                                  fontSize: 12,
                                  color: KiranaNapseTheme.juteSoft,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isReorder
                                    ? 'Suggested order: $quantity $unit'
                                    : type == 'expiry_risk'
                                    ? 'Expiry risk'
                                    : 'Overstock alert',
                                style: GoogleFonts.hind(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: KiranaNapseTheme.terracottaDark,
                                ),
                              ),
                              if (item['cold_start'] == true)
                                Text(
                                  'Early estimate based on limited sales history',
                                  style: GoogleFonts.hind(
                                    fontSize: 12,
                                    color: KiranaNapseTheme.juteSoft,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'WHY THIS RECOMMENDATION',
                          style: GoogleFonts.hind(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: KiranaNapseTheme.juteSoft,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: KiranaNapseTheme.turmericTint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item['reason_text']?.toString() ??
                                'No explanation available.',
                            style: GoogleFonts.hind(
                              fontSize: 13,
                              color: KiranaNapseTheme.jute,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.pop(),
                            child: const Text('Back to List'),
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
