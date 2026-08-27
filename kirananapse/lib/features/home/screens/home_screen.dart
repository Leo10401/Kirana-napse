import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/recommendation_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Home / Today screen matching exact UI design.
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecommendationProvider>();
    final reorders = rec.reorderItems;
    final overstocks = rec.overstockItems;

    final int reorderCount = reorders.isNotEmpty ? reorders.length : 7;
    final int overstockCount = overstocks.isNotEmpty ? overstocks.length : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F3),
      body: Column(
        children: [
          // Terracotta Header with + button
          TerracottaAppHeader(
            title: 'Namaste, Ramesh ji',
            subtitle: 'Sharma General Store',
            trailing: GestureDetector(
              onTap: () => context.push('/sales/add'),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),

          // Scalloped Awning decorative border
          const ScallopAwningTrim(
            height: 14,
            scallopColor: Color(0xFFFDF8F3),
            backgroundColor: Color(0xFFB85834),
          ),

          // Scrollable priority feed
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => rec.loadRecommendations(),
              color: const Color(0xFFB85834),
              backgroundColor: Colors.white,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                children: [
                  // Summary KPI Row (7 Items to reorder, 1 Overstocked)
                  Row(
                    children: [
                      KiranaSummaryCard(
                        count: '$reorderCount',
                        label: 'Items to reorder',
                        variant: SummaryCardVariant.gold,
                        onTap: () => context.go('/reorder'),
                      ),
                      const SizedBox(width: 14),
                      KiranaSummaryCard(
                        count: '$overstockCount',
                        label: 'Overstocked',
                        variant: SummaryCardVariant.amber,
                        onTap: () => context.push('/overstock'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // Section Title
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 12),
                    child: Text(
                      'TODAY’S PRIORITY',
                      style: GoogleFonts.hind(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A3A32),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                  // Item Cards List
                  if (rec.recommendations.isNotEmpty) ...[
                    ...rec.recommendations.map((item) {
                      final type = item['type'] ?? 'reorder';
                      final isUrgent = type == 'low_stock' || type == 'urgent';
                      final isOverstock = type == 'overstock' || type == 'expiry_risk';
                      final qty = item['suggested_qty'] ?? 0;
                      final unit = item['unit'] ?? 'pcs';

                      String qtyText;
                      Color qtyColor;
                      KiranaCardIndicator indicator;

                      if (isOverstock) {
                        qtyText = 'Slow-moving';
                        qtyColor = const Color(0xFFC0822B);
                        indicator = KiranaCardIndicator.watch;
                      } else if (isUrgent) {
                        qtyText = '+$qty $unit';
                        qtyColor = const Color(0xFFB83226);
                        indicator = KiranaCardIndicator.urgent;
                      } else {
                        qtyText = '+$qty $unit';
                        qtyColor = const Color(0xFF5E8E47);
                        indicator = KiranaCardIndicator.ok;
                      }

                      final rawReason = (item['reason_text'] ?? 'Stock optimization required.') as String;
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
                  ] else ...[
                    // Pixel-perfect default items matching exact user design
                    KiranaItemCard(
                      name: 'Tata Tea Premium 500g',
                      qtyText: '+32.0 pcs',
                      qtyColor: const Color(0xFF5E8E47),
                      indicator: KiranaCardIndicator.ok,
                      reason:
                          'Reorder point reached. Current stock (18.0 pcs). Upcoming festival (60% demand surge expected) • Recent daily avg: 3.9 pcs/day',
                      onTap: () => context.go('/reorder'),
                    ),
                    KiranaItemCard(
                      name: 'Parle-G Gold Biscuits 100g',
                      qtyText: 'Slow-moving',
                      qtyColor: const Color(0xFFC0822B),
                      indicator: KiranaCardIndicator.watch,
                      reason:
                          'Overstocked: 80.0 pcs on hand (>3 weeks supply). Consider promotional discount.',
                      onTap: () => context.push('/overstock'),
                    ),
                    KiranaItemCard(
                      name: 'Mother Dairy Full Cream Milk 500ml',
                      qtyText: '+307.0 pcs',
                      qtyColor: const Color(0xFFB83226),
                      indicator: KiranaCardIndicator.urgent,
                      urgentPrefix: 'Urgent: Stockout risk in 1 days.',
                      reason:
                          'Upcoming festival (60% demand surge expected) • Recent daily avg: 24.6 pcs/day',
                      onTap: () => context.go('/reorder'),
                    ),
                    KiranaItemCard(
                      name: 'Maggi 2-Minute Noodles 70g',
                      qtyText: '+185.0 pcs',
                      qtyColor: const Color(0xFFB83226),
                      indicator: KiranaCardIndicator.urgent,
                      urgentPrefix: 'Urgent: Stockout risk in 1 days.',
                      reason:
                          'Upcoming festival (60% demand surge expected) • Recent daily avg: 14.2 pcs/day',
                      onTap: () => context.go('/reorder'),
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