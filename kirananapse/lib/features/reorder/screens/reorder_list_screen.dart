import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/recommendation_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Reorder List Screen — Screen 3.
class ReorderListScreen extends StatefulWidget {
  const ReorderListScreen({super.key});

  @override
  State<ReorderListScreen> createState() => _ReorderListScreenState();
}

class _ReorderListScreenState extends State<ReorderListScreen> {
  // Local state for interactive ordered/quantity changes
  final Set<String> _orderedIds = {};
  final Map<String, String> _customQtys = {};

  final List<Map<String, dynamic>> _fallbackItems = [
    {
      'id': 'rec_1',
      'sku_id': 'sku_1',
      'name': 'Atta (5kg)',
      'qty': '15 kg',
      'reason': '40% more sold than usual last week',
      'urgent': true,
    },
    {
      'id': 'rec_2',
      'sku_id': 'sku_2',
      'name': 'Maggi noodles',
      'qty': '3 box',
      'reason': 'Stock runs out in 2 days',
      'urgent': true,
    },
    {
      'id': 'rec_3',
      'sku_id': 'sku_3',
      'name': 'Sugar (1kg)',
      'qty': '10 pkt',
      'reason': 'Steady weekly demand',
      'urgent': false,
    },
    {
      'id': 'rec_4',
      'sku_id': 'sku_4',
      'name': 'Fortune Sunlite Oil 1L',
      'qty': '12 ltr',
      'reason': 'Upcoming festival surge • 2 days lead time',
      'urgent': true,
    },
    {
      'id': 'rec_5',
      'sku_id': 'sku_5',
      'name': 'Tata Salt 1kg',
      'qty': '24 pkt',
      'reason': 'Fast turnover staple • Safety stock reorder',
      'urgent': false,
    },
  ];

  void _showEditQtyDialog(String id, String currentQty, String itemName) {
    final controller = TextEditingController(text: currentQty);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KiranaNapseTheme.riceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KiranaNapseTheme.sandstone),
        ),
        title: Text(
          'Edit Quantity: $itemName',
          style: GoogleFonts.baloo2(fontSize: 18, fontWeight: FontWeight.w700, color: KiranaNapseTheme.jute),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. 20 kg or 4 box',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.hind(color: KiranaNapseTheme.juteSoft, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KiranaNapseTheme.turmeric,
              foregroundColor: const Color(0xFF4A2E0A),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _customQtys[id] = controller.text.trim();
                });
              }
              Navigator.of(ctx).pop();
            },
            child: Text('Save', style: GoogleFonts.hind(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecommendationProvider>();
    final backendItems = rec.reorderItems;

    final displayItems = backendItems.isNotEmpty
        ? backendItems.map((item) {
            final id = item['id'] ?? item['sku_id'] ?? 'item';
            final name = item['sku_name'] ?? 'Item';
            final qty = _customQtys[id] ?? '${item['owner_edited_qty'] ?? item['suggested_qty'] ?? 1} ${item['unit'] ?? 'pcs'}';
            final reason = item['reason_text'] ?? 'Low stock alert';
            final isUrgent = item['type'] == 'low_stock';
            return {
              'id': id,
              'sku_id': item['sku_id'],
              'name': name,
              'qty': qty,
              'reason': reason,
              'urgent': isUrgent,
            };
          }).toList()
        : _fallbackItems;

    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: Stack(
        children: [
          Column(
            children: [
              // Terracotta Header with Back button
              TerracottaAppHeader(
                title: 'Reorder list',
                showBack: true,
                onBack: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/home');
                  }
                },
                trailing: GestureDetector(
                  onTap: () => context.push('/export'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.share_rounded, color: Color(0xFFFBE9DE), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Export',
                          style: GoogleFonts.hind(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFBE9DE),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Toran Garland Accent
              const ToranGarland(height: 12, opacity: 0.8),

              // Item list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Text(
                      '${displayItems.length} ITEMS',
                      style: GoogleFonts.hind(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: KiranaNapseTheme.juteSoft,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...displayItems.map((item) {
                      final id = item['id'] as String;
                      final isOrdered = _orderedIds.contains(id);
                      final currentQty = _customQtys[id] ?? item['qty'] as String;

                      return KiranaItemCard(
                        name: item['name'] as String,
                        qtyText: currentQty,
                        reason: item['reason'] as String,
                        indicator: isOrdered
                            ? KiranaCardIndicator.ok
                            : ((item['urgent'] as bool)
                                ? KiranaCardIndicator.urgent
                                : KiranaCardIndicator.ok),
                        actions: [
                          MiniButton(
                            label: 'Edit qty',
                            filled: false,
                            onTap: () => _showEditQtyDialog(id, currentQty, item['name'] as String),
                          ),
                          MiniButton(
                            label: isOrdered ? 'Ordered ✓' : 'Mark ordered',
                            filled: true,
                            onTap: () {
                              setState(() {
                                if (isOrdered) {
                                  _orderedIds.remove(id);
                                } else {
                                  _orderedIds.add(id);
                                }
                              });
                              if (item['id'] != null) {
                                rec.updateRecommendation(id, isOrdered ? 'pending' : 'ordered');
                              }
                            },
                          ),
                        ],
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

          // Floating CTA Bar with gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: const BoxDecoration(
                gradient: KiranaNapseTheme.bottomCtaFade,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KiranaNapseTheme.terracotta,
                    foregroundColor: const Color(0xFFFBE9DE),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push('/export'),
                  child: Text(
                    'Share with distributor',
                    style: GoogleFonts.hind(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
