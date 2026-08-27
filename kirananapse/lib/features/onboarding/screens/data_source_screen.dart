import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Onboarding Step 4: How do you currently track sales? (AppFlow §4.4).
class DataSourceScreen extends StatefulWidget {
  const DataSourceScreen({super.key});

  @override
  State<DataSourceScreen> createState() => _DataSourceScreenState();
}

class _DataSourceScreenState extends State<DataSourceScreen> {
  String? _selectedMethod;

  final _methods = [
    {
      'id': 'nothing',
      'title': 'Memory & gut feeling',
      'subtitle': "We'll bootstrap store forecasts with category benchmarks",
      'icon': Icons.psychology_outlined,
      'color': KiranaNapseTheme.turmericDark,
    },
    {
      'id': 'paper_register',
      'title': 'Paper register / Khata notebook',
      'subtitle': 'You can photograph invoices or enter daily totals',
      'icon': Icons.menu_book_outlined,
      'color': KiranaNapseTheme.terracotta,
    },
    {
      'id': 'billing_app',
      'title': 'Billing app / POS machine',
      'subtitle': 'Import or export stock lists directly',
      'icon': Icons.point_of_sale_rounded,
      'color': KiranaNapseTheme.betel,
    },
  ];

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepIndicator(4, 5),
                    const SizedBox(height: 24),

                    Text(
                      'How Do You Track\nSales Today?',
                      style: GoogleFonts.baloo2(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: KiranaNapseTheme.jute,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Helps determine initial data onboarding mode.',
                      style: GoogleFonts.hind(fontSize: 13.5, color: KiranaNapseTheme.juteSoft),
                    ),
                    const SizedBox(height: 24),

                    ..._methods.map((method) {
                      final isSelected = _selectedMethod == method['id'];
                      final color = method['color'] as Color;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMethod = method['id'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? KiranaNapseTheme.turmericTint
                                  : KiranaNapseTheme.riceCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? KiranaNapseTheme.turmeric
                                    : KiranaNapseTheme.sandstone,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(method['icon'] as IconData, color: color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        method['title'] as String,
                                        style: GoogleFonts.hind(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: KiranaNapseTheme.jute,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        method['subtitle'] as String,
                                        style: GoogleFonts.hind(
                                          fontSize: 11.5,
                                          color: KiranaNapseTheme.juteSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: KiranaNapseTheme.turmericDark, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KiranaNapseTheme.turmeric,
                          foregroundColor: const Color(0xFF4A2E0A),
                        ),
                        onPressed: _selectedMethod != null ? () => context.go('/onboarding/done') : null,
                        child: Text(
                          'Continue',
                          style: GoogleFonts.hind(fontSize: 14.5, fontWeight: FontWeight.w700),
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
