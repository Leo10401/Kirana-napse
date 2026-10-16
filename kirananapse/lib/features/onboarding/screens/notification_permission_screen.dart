import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/store_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Onboarding Step 2: Notification permission (AppFlow §4.3 Step 2).
class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: SafeArea(
        child: Column(
          children: [
            const ToranGarland(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepIndicator(2, 5),
                    const SizedBox(height: 24),

                    Text(
                      'Stay Updated\nEvery Morning',
                      style: GoogleFonts.baloo2(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: KiranaNapseTheme.jute,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Receive daily 7:00 AM restocking alerts with low-stock risks and overstock suggestions.',
                      style: GoogleFonts.hind(
                        fontSize: 13.5,
                        color: KiranaNapseTheme.juteSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Notification preview card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: KiranaNapseTheme.riceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: KiranaNapseTheme.sandstone,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: KiranaNapseTheme.turmericTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: KiranaNapseTheme.turmericDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kirana-Napse Alert',
                                  style: GoogleFonts.hind(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: KiranaNapseTheme.jute,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '12 items to reorder • 4 overstocked items',
                                  style: GoogleFonts.hind(
                                    fontSize: 11.5,
                                    color: KiranaNapseTheme.juteSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '7:00 AM',
                            style: GoogleFonts.hind(
                              fontSize: 10.5,
                              color: KiranaNapseTheme.juteMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Benefits list
                    _buildBenefit(
                      Icons.local_shipping_outlined,
                      'Never run out of fast-selling staples',
                      KiranaNapseTheme.terracotta,
                    ),
                    const SizedBox(height: 12),
                    _buildBenefit(
                      Icons.trending_down_rounded,
                      'Identify dead stock before expiry',
                      KiranaNapseTheme.chili,
                    ),
                    const SizedBox(height: 12),
                    _buildBenefit(
                      Icons.share_rounded,
                      'Export distributor list directly to WhatsApp',
                      KiranaNapseTheme.betel,
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KiranaNapseTheme.turmeric,
                          foregroundColor: const Color(0xFF4A2E0A),
                        ),
                        onPressed: () {
                          context
                              .read<StoreProvider>()
                              .setOnboardingNotifications(true);
                          context.go('/onboarding/store-basics');
                        },
                        child: Text(
                          'Save reminder preference',
                          style: GoogleFonts.hind(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: KiranaNapseTheme.sandstone,
                          ),
                        ),
                        onPressed: () {
                          context
                              .read<StoreProvider>()
                              .setOnboardingNotifications(false);
                          context.go('/onboarding/store-basics');
                        },
                        child: Text(
                          'Maybe Later',
                          style: GoogleFonts.hind(
                            fontSize: 13.5,
                            color: KiranaNapseTheme.juteSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.hind(
              fontSize: 13,
              color: KiranaNapseTheme.jute,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int current, int total) {
    return Row(
      children: List.generate(total, (i) {
        final isActive = i < current;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: isActive
                  ? KiranaNapseTheme.terracotta
                  : KiranaNapseTheme.sandstone,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
