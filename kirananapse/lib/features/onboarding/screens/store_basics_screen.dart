import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/store_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Onboarding Step 3: Store basics (AppFlow §4.3 Steps 3-4).
class StoreBasicsScreen extends StatefulWidget {
  const StoreBasicsScreen({super.key});

  @override
  State<StoreBasicsScreen> createState() => _StoreBasicsScreenState();
}

class _StoreBasicsScreenState extends State<StoreBasicsScreen> {
  final _storeNameController = TextEditingController();
  final _cityController = TextEditingController();
  String _category = 'general';

  final _categories = [
    {'id': 'general', 'label': 'General Store', 'icon': Icons.store_rounded},
    {
      'id': 'grocery',
      'label': 'Kirana / Grocery',
      'icon': Icons.shopping_basket_rounded,
    },
    {
      'id': 'dairy',
      'label': 'Dairy & Beverages',
      'icon': Icons.local_drink_rounded,
    },
    {'id': 'snacks', 'label': 'Snacks & FMCG', 'icon': Icons.fastfood_rounded},
    {
      'id': 'pharmacy',
      'label': 'Medical / Chemist',
      'icon': Icons.local_pharmacy_rounded,
    },
  ];

  @override
  void dispose() {
    _storeNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: SafeArea(
        child: Column(
          children: [
            const ToranGarland(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepIndicator(3, 5),
                    const SizedBox(height: 24),

                    Text(
                      'About Your Store',
                      style: GoogleFonts.baloo2(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: KiranaNapseTheme.jute,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Helps calibrate festival demand and category benchmarks.',
                      style: GoogleFonts.hind(
                        fontSize: 13.5,
                        color: KiranaNapseTheme.juteSoft,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Store name
                    Text(
                      'Store Name',
                      style: GoogleFonts.hind(
                        color: KiranaNapseTheme.jute,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _storeNameController,
                      style: GoogleFonts.hind(color: KiranaNapseTheme.jute),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Sharma General Store',
                        prefixIcon: Icon(
                          Icons.store_rounded,
                          color: KiranaNapseTheme.juteMuted,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // City
                    Text(
                      'City / Region',
                      style: GoogleFonts.hind(
                        color: KiranaNapseTheme.jute,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cityController,
                      style: GoogleFonts.hind(color: KiranaNapseTheme.jute),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Lucknow, UP',
                        prefixIcon: Icon(
                          Icons.location_on_rounded,
                          color: KiranaNapseTheme.juteMuted,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category
                    Text(
                      'Store Category',
                      style: GoogleFonts.hind(
                        color: KiranaNapseTheme.jute,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _category == cat['id'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _category = cat['id'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? KiranaNapseTheme.turmericTint
                                  : KiranaNapseTheme.riceCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? KiranaNapseTheme.turmeric
                                    : KiranaNapseTheme.sandstone,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat['icon'] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? KiranaNapseTheme.turmericDark
                                      : KiranaNapseTheme.juteSoft,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat['label'] as String,
                                  style: GoogleFonts.hind(
                                    fontSize: 12.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? KiranaNapseTheme.turmericDark
                                        : KiranaNapseTheme.jute,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 36),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KiranaNapseTheme.turmeric,
                          foregroundColor: const Color(0xFF4A2E0A),
                        ),
                        onPressed: () {
                          final name = _storeNameController.text.trim();
                          final city = _cityController.text.trim();
                          if (name.isEmpty || city.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter your store name and city to continue.',
                                ),
                              ),
                            );
                            return;
                          }
                          context
                              .read<StoreProvider>()
                              .setOnboardingStoreBasics(
                                name: name,
                                city: city,
                                category: _category,
                              );
                          context.go('/onboarding/data-source');
                        },
                        child: Text(
                          'Next',
                          style: GoogleFonts.hind(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
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
