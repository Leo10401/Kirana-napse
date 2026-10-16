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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RecommendationProvider>().loadRecommendations();
    });
  }

  Future<void> _showEditQtyDialog(
    String id,
    num currentQty,
    String unit,
    String itemName,
  ) async {
    final controller = TextEditingController(text: currentQty.toString());
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KiranaNapseTheme.riceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KiranaNapseTheme.sandstone),
        ),
        title: Text(
          'Edit Quantity: $itemName',
          style: GoogleFonts.baloo2(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: KiranaNapseTheme.jute,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(hintText: 'Quantity', suffixText: unit),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.hind(
                color: KiranaNapseTheme.juteSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KiranaNapseTheme.turmeric,
              foregroundColor: const Color(0xFF4A2E0A),
            ),
            onPressed: () async {
              final quantity = double.tryParse(controller.text.trim());
              if (quantity == null || quantity < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid quantity.')),
                );
                return;
              }
              final saved = await context
                  .read<RecommendationProvider>()
                  .updateRecommendation(id, 'edited', editedQty: quantity);
              if (!mounted || !ctx.mounted) return;
              if (saved) {
                Navigator.of(ctx).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not save the quantity. Try again.'),
                  ),
                );
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.hind(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecommendationProvider>();
    final backendItems = rec.reorderItems;

    final displayItems = backendItems.map((item) {
      final id = item['id'] ?? item['sku_id'] ?? 'item';
      final name = item['sku_name'] ?? 'Item';
      final qty =
          (item['owner_edited_qty'] ?? item['suggested_qty'] ?? 1) as num;
      final unit = item['sku_unit'] ?? 'pcs';
      final reason = item['reason_text'] ?? 'Low stock alert';
      final isUrgent = item['type'] == 'low_stock';
      return {
        'id': id,
        'sku_id': item['sku_id'],
        'name': name,
        'qty': qty,
        'unit': unit,
        'reason': reason,
        'urgent': isUrgent,
        'status': item['status'] ?? 'pending',
      };
    }).toList();

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.share_rounded,
                          color: Color(0xFFFBE9DE),
                          size: 14,
                        ),
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
                      '${displayItems.length} items to reorder',
                      style: GoogleFonts.hind(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: KiranaNapseTheme.juteSoft,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (rec.isLoading && displayItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (displayItems.isEmpty)
                      KiranaEmptyState(
                        icon: rec.error == null
                            ? Icons.check_circle_outline_rounded
                            : Icons.wifi_off_rounded,
                        title: rec.error == null
                            ? 'No reorders right now'
                            : 'Could not load reorders',
                        message:
                            rec.error ??
                            'Add sales and stock details to see what your store needs next.',
                        actionLabel: rec.error == null ? null : 'Try again',
                        onAction: rec.error == null
                            ? null
                            : () => rec.loadRecommendations(),
                      ),

                    ...displayItems.map((item) {
                      final id = item['id'] as String;
                      final isOrdered = item['status'] == 'ordered';
                      final currentQty = item['qty'] as num;
                      final unit = item['unit'] as String;

                      return KiranaItemCard(
                        name: item['name'] as String,
                        qtyText: '$currentQty $unit',
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
                            onTap: () => _showEditQtyDialog(
                              id,
                              currentQty,
                              unit,
                              item['name'] as String,
                            ),
                          ),
                          MiniButton(
                            label: isOrdered ? 'Ordered ✓' : 'Mark ordered',
                            filled: true,
                            onTap: () async {
                              final saved = await rec.updateRecommendation(
                                id,
                                isOrdered ? 'pending' : 'ordered',
                              );
                              if (!saved && mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not update this item. Try again.',
                                    ),
                                  ),
                                );
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
                  onPressed: displayItems.isEmpty
                      ? rec.error == null
                            ? () => context.push('/sales/add')
                            : () => rec.loadRecommendations()
                      : () => context.push('/export'),
                  child: Text(
                    displayItems.isEmpty
                        ? rec.error == null
                              ? 'Add a sale'
                              : 'Try again'
                        : 'Share with distributor',
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
