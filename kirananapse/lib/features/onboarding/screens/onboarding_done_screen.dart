import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Onboarding Step 5: Done — confirmation screen (AppFlow §4.3 Step 5).
class OnboardingDoneScreen extends StatelessWidget {
  const OnboardingDoneScreen({super.key});

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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    _buildStepIndicator(5, 5),
                    const Spacer(),

                    // Success badge
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: KiranaNapseTheme.betel,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, size: 44, color: Color(0xFFEFF4E7)),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      "You're All Set! 🎉",
                      style: GoogleFonts.baloo2(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: KiranaNapseTheme.jute,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your initial benchmark forecasts are generated and ready for review on your dashboard.',
                      style: GoogleFonts.hind(
                        fontSize: 13.5,
                        color: KiranaNapseTheme.juteSoft,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // What to expect box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: KiranaNapseTheme.riceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: KiranaNapseTheme.sandstone, width: 1),
                      ),
                      child: Column(
                        children: [
                          _expectationRow(
                            Icons.notifications_active_outlined,
                            'Daily Restocking Reminders',
                            'Receive actionable items to reorder every morning',
                            KiranaNapseTheme.turmericDark,
                          ),
                          const SizedBox(height: 12),
                          _expectationRow(
                            Icons.insights_rounded,
                            'Demand & Festival Surges',
                            'Automated predictions factoring in local calendar events',
                            KiranaNapseTheme.terracotta,
                          ),
                          const SizedBox(height: 12),
                          _expectationRow(
                            Icons.share_rounded,
                            'One-Tap WhatsApp Export',
                            'Instantly share order list with distributors',
                            KiranaNapseTheme.betel,
                          ),
                        ],
                      ),
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
                          context.read<AuthProvider>().setOnboarded(true);
                          context.go('/home');
                        },
                        child: Text(
                          'Go to Dashboard →',
                          style: GoogleFonts.hind(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expectationRow(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.hind(fontSize: 13, fontWeight: FontWeight.w700, color: KiranaNapseTheme.jute),
              ),
              Text(
                subtitle,
                style: GoogleFonts.hind(fontSize: 11.5, color: KiranaNapseTheme.juteSoft),
              ),
            ],
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
              color: isActive ? KiranaNapseTheme.terracotta : KiranaNapseTheme.sandstone,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
