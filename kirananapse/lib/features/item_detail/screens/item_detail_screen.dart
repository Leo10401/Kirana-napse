import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Item Detail screen — sales history, forecast reason, edit (AppFlow §7 Screen 6).
class ItemDetailScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: Column(
        children: [
          TerracottaAppHeader(
            title: 'Item Detail',
            showBack: true,
            onBack: () => context.pop(),
            trailing: GestureDetector(
              onTap: () => context.push('/feedback/$itemId'),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag_outlined, color: Color(0xFFFBE9DE), size: 18),
              ),
            ),
          ),
          const ToranGarland(height: 12, opacity: 0.8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item header card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KiranaNapseTheme.riceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: KiranaNapseTheme.sandstone, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: KiranaNapseTheme.turmericTint,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, color: KiranaNapseTheme.turmericDark, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Atta (5kg Chakki)',
                                    style: GoogleFonts.baloo2(fontSize: 18, fontWeight: FontWeight.w700, color: KiranaNapseTheme.jute),
                                  ),
                                  Text(
                                    'Grocery / Staples • 5kg pack',
                                    style: GoogleFonts.hind(fontSize: 12, color: KiranaNapseTheme.juteSoft),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: KiranaNapseTheme.sandstone),
                        const SizedBox(height: 10),
                        _detailRow('Suggested Reorder', '15 packs', KiranaNapseTheme.terracottaDark),
                        const SizedBox(height: 8),
                        _detailRow('Current Stock On Hand', '3 packs (Low Stock)', KiranaNapseTheme.chili),
                        const SizedBox(height: 8),
                        _detailRow('Supplier Lead Time', '2 days', KiranaNapseTheme.juteSoft),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Forecast explanation
                  Text(
                    'WHY THIS RECOMMENDATION',
                    style: GoogleFonts.hind(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: KiranaNapseTheme.juteSoft,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KiranaNapseTheme.turmericTint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KiranaNapseTheme.turmeric.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: KiranaNapseTheme.turmericDark, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '40% more sold than usual last week. Upcoming festival demand surge expected with 2 days supplier turnaround.',
                            style: GoogleFonts.hind(fontSize: 12.5, color: KiranaNapseTheme.jute, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action CTA
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KiranaNapseTheme.turmeric,
                        foregroundColor: const Color(0xFF4A2E0A),
                      ),
                      onPressed: () => context.pop(),
                      child: Text('Back to List', style: GoogleFonts.hind(fontSize: 14, fontWeight: FontWeight.w700)),
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

  Widget _detailRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.hind(fontSize: 13, color: KiranaNapseTheme.juteSoft)),
        Text(value, style: GoogleFonts.hind(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
