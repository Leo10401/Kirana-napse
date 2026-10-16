import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/recommendation_provider.dart';
import '../../../core/providers/store_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Daily overview for the store owner.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationProvider>().loadRecommendations();
      context.read<StoreProvider>().loadStore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecommendationProvider>();
    final store = context.watch<StoreProvider>().store;
    final reorders = rec.reorderItems;
    final overstocks = rec.overstockItems;
    final priorities = [...rec.recommendations]
      ..sort((a, b) {
        const rank = {
          'low_stock': 0,
          'expiry_risk': 1,
          'reorder': 2,
          'overstock': 3,
        };
        return (rank[a['type']] ?? 4).compareTo(rank[b['type']] ?? 4);
      });

    final int reorderCount = reorders.length;
    final int overstockCount = overstocks.length;

    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: Column(
        children: [
          TerracottaAppHeader(
            title: 'Today',
            subtitle: store?['store_name'] ?? 'Your store',
            trailing: IconButton.filledTonal(
              tooltip: 'Add a sale',
              onPressed: () => context.push('/sales/add'),
              style: IconButton.styleFrom(
                backgroundColor: KiranaNapseTheme.turmeric,
                foregroundColor: KiranaNapseTheme.jute,
                minimumSize: const Size(44, 44),
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ),

          // Scrollable priority feed
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => rec.loadRecommendations(),
              color: KiranaNapseTheme.terracotta,
              backgroundColor: KiranaNapseTheme.riceCard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  Text(
                    'Your stock at a glance',
                    style: GoogleFonts.baloo2(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: KiranaNapseTheme.jute,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start with the items that need attention.',
                    style: GoogleFonts.hind(
                      fontSize: 13,
                      color: KiranaNapseTheme.juteSoft,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      KiranaSummaryCard(
                        count: '$reorderCount',
                        label: 'To reorder',
                        variant: SummaryCardVariant.gold,
                        onTap: () => context.go('/reorder'),
                      ),
                      const SizedBox(width: 14),
                      KiranaSummaryCard(
                        count: '$overstockCount',
                        label: 'Stock alerts',
                        variant: SummaryCardVariant.amber,
                        onTap: () => context.push('/overstock'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/sales/add'),
                      style: FilledButton.styleFrom(
                        backgroundColor: KiranaNapseTheme.terracottaDark,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Add a sale'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 12),
                    child: Text(
                      'Needs your attention',
                      style: GoogleFonts.baloo2(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: KiranaNapseTheme.jute,
                      ),
                    ),
                  ),

                  if (priorities.isNotEmpty) ...[
                    ...priorities.map((item) {
                      final type = item['type'] ?? 'reorder';
                      final isUrgent = type == 'low_stock' || type == 'urgent';
                      final isOverstock =
                          type == 'overstock' || type == 'expiry_risk';
                      final qty =
                          item['owner_edited_qty'] ??
                          item['suggested_qty'] ??
                          0;
                      final formattedQty =
                          qty is num && qty == qty.roundToDouble()
                          ? qty.toInt().toString()
                          : qty.toString();
                      final unit = item['sku_unit'] ?? 'pcs';

                      String qtyText;
                      Color qtyColor;
                      KiranaCardIndicator indicator;

                      if (isOverstock) {
                        qtyText = type == 'expiry_risk'
                            ? 'Expiry risk'
                            : 'Overstock';
                        qtyColor = KiranaNapseTheme.marigold;
                        indicator = KiranaCardIndicator.watch;
                      } else if (isUrgent) {
                        qtyText = '+$formattedQty $unit';
                        qtyColor = KiranaNapseTheme.chili;
                        indicator = KiranaCardIndicator.urgent;
                      } else {
                        qtyText = '+$formattedQty $unit';
                        qtyColor = KiranaNapseTheme.betel;
                        indicator = KiranaCardIndicator.ok;
                      }

                      final rawReason =
                          (item['reason_text'] ??
                                  'Stock optimization required.')
                              as String;
                      String? urgentPrefix;
                      String reasonBody = rawReason;

                      if (isUrgent && rawReason.startsWith('Urgent:')) {
                        final dotIndex = rawReason.indexOf('.');
                        if (dotIndex != -1) {
                          urgentPrefix = rawReason.substring(0, dotIndex + 1);
                          reasonBody = rawReason.substring(dotIndex + 1).trim();
                        } else {
                          urgentPrefix = 'Urgent: Stockout risk in 1 days.';
                        }
                      }

                      return KiranaItemCard(
                        name: item['sku_name'] ?? 'Inventory Item',
                        tag: MiniTag(
                          label: type == 'low_stock'
                              ? 'Low stock'
                              : type == 'expiry_risk'
                              ? 'Expiring soon'
                              : type == 'overstock'
                              ? 'Overstock'
                              : 'Reorder',
                          type: isUrgent
                              ? MiniTagType.danger
                              : isOverstock
                              ? MiniTagType.warn
                              : MiniTagType.success,
                        ),
                        qtyText: qtyText,
                        qtyColor: qtyColor,
                        urgentPrefix: urgentPrefix,
                        reason: reasonBody,
                        indicator: indicator,
                        onTap: () {
                          if (item['sku_id'] != null) {
                            context.push('/item/${item['sku_id']}');
                          }
                        },
                      );
                    }),
                  ] else if (rec.isLoading) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ] else ...[
                    KiranaEmptyState(
                      icon: rec.error == null
                          ? Icons.inventory_2_outlined
                          : Icons.wifi_off_rounded,
                      title: rec.error == null
                          ? 'All clear for now'
                          : 'Could not load your stock',
                      message:
                          rec.error ??
                          'No alerts are ready yet. Add sales and stock details to build your store history.',
                      actionLabel: rec.error == null ? null : 'Try again',
                      onAction: rec.error == null
                          ? null
                          : () => rec.loadRecommendations(),
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
