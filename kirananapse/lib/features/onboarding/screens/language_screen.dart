import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Onboarding Step 1: Language selection screen matching the market-rooted design.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedCode = 'hi';

  final List<Map<String, String>> _languages = [
    {'code': 'hi', 'label': 'हिंदी', 'labelEn': 'Hindi'},
    {'code': 'en', 'label': 'English', 'labelEn': ''},
    {'code': 'mr', 'label': 'मराठी', 'labelEn': 'Marathi'},
    {'code': 'gu', 'label': 'ગુજરાતી', 'labelEn': 'Gujarati'},
    {'code': 'ta', 'label': 'தமிழ்', 'labelEn': 'Tamil'},
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // Logo badge (Turmeric circular badge with shop icon)
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: KiranaNapseTheme.turmeric,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFF4A2E0A),
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // App Title
                    Text(
                      'Kirana-Napse',
                      style: GoogleFonts.baloo2(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: KiranaNapseTheme.terracotta,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // App Tagline
                    Text(
                      'Apni dukaan, samajhdaar stock',
                      style: GoogleFonts.hind(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: KiranaNapseTheme.juteSoft,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Question
                    Text(
                      'Choose your language',
                      style: GoogleFonts.hind(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: KiranaNapseTheme.jute,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Language Pills
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _languages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final lang = _languages[index];
                          final isSelected = _selectedCode == lang['code'];
                          final display = lang['labelEn']!.isNotEmpty
                              ? '${lang['label']}   ${lang['labelEn']}'
                              : lang['label']!;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedCode = lang['code']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? KiranaNapseTheme.turmericTint
                                    : KiranaNapseTheme.riceCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? KiranaNapseTheme.turmeric
                                      : KiranaNapseTheme.sandstone,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  display,
                                  style: GoogleFonts.hind(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected
                                        ? KiranaNapseTheme.turmericDark
                                        : KiranaNapseTheme.jute,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Onboarding CTA
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KiranaNapseTheme.turmeric,
                          foregroundColor: const Color(0xFF4A2E0A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => context.go('/onboarding/notifications'),
                        child: Text(
                          'Continue',
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
}
