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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RecommendationProvider>().loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecommendationProvider>();
    final backendItems = rec.overstockItems;

    final displayItems = backendItems.map((item) {
      final isExpiry = item['type'] == 'expiry_risk';
      final isResolved =
          item['status'] == 'dismissed' || item['status'] == 'resolved';
      return {
        'id': item['id'] ?? item['sku_id'],
        'sku_id': item['sku_id'],
        'name': item['sku_name'] ?? 'Flagged Item',
        'reason':
            item['reason_text'] ??
            (isExpiry
                ? 'Near expiry threshold'
                : 'High inventory days on hand'),
        'tagLabel': isResolved
            ? 'Resolved'
            : (isExpiry ? 'Expiring soon' : 'Slow-moving'),
        'tagType': isResolved
            ? MiniTagType.success
            : (isExpiry ? MiniTagType.danger : MiniTagType.warn),
      };
    }).toList();

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
                  '${displayItems.length} stock alerts',
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
                        ? Icons.spa_outlined
                        : Icons.wifi_off_rounded,
                    title: rec.error == null
                        ? 'No stock alerts'
                        : 'Could not load alerts',
                    message:
                        rec.error ??
                        'Nothing looks overstocked or near expiry right now.',
                    actionLabel: rec.error == null ? null : 'Try again',
                    onAction: rec.error == null
                        ? null
                        : () => rec.loadRecommendations(),
                  ),

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
