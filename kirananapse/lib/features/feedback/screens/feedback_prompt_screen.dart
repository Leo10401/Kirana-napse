import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../core/services/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Feedback Prompt screen — reason-code selector + free text (AppFlow §6, §7 Screen 8).
class FeedbackPromptScreen extends StatefulWidget {
  final String recommendationId;

  const FeedbackPromptScreen({super.key, required this.recommendationId});

  @override
  State<FeedbackPromptScreen> createState() => _FeedbackPromptScreenState();
}

class _FeedbackPromptScreenState extends State<FeedbackPromptScreen> {
  String? _selectedReason;
  final _freeTextController = TextEditingController();
  bool _isSubmitting = false;

  final _reasons = [
    {'code': 'festival_event', 'label': 'Festival / Local Event', 'icon': Icons.celebration_rounded, 'color': KiranaNapseTheme.turmericDark},
    {'code': 'bulk_buyer', 'label': 'One-Off Bulk Buyer', 'icon': Icons.groups_rounded, 'color': KiranaNapseTheme.terracotta},
    {'code': 'weather', 'label': 'Weather / Seasonal Change', 'icon': Icons.cloud_rounded, 'color': KiranaNapseTheme.betel},
    {'code': 'competitor_price', 'label': 'Competitor Pricing Discount', 'icon': Icons.storefront_rounded, 'color': KiranaNapseTheme.chili},
    {'code': 'other', 'label': 'Other / Custom Reason', 'icon': Icons.more_horiz_rounded, 'color': KiranaNapseTheme.juteSoft},
  ];

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiClient.flagRecommendation(widget.recommendationId, {
        'reason_code': _selectedReason,
        if (_freeTextController.text.isNotEmpty) 'free_text': _freeTextController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks! This helps calibrate your future forecasts.')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: Column(
        children: [
          TerracottaAppHeader(
            title: 'Forecast Feedback',
            showBack: true,
            onBack: () => context.pop(),
          ),
          const ToranGarland(height: 12, opacity: 0.8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Was this recommendation off?',
                    style: GoogleFonts.baloo2(fontSize: 22, fontWeight: FontWeight.w700, color: KiranaNapseTheme.jute),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Let us know why — this feedback loops back to improve AI demand predictions.',
                    style: GoogleFonts.hind(fontSize: 13, color: KiranaNapseTheme.juteSoft),
                  ),
                  const SizedBox(height: 20),

                  Text('What caused the difference?', style: GoogleFonts.hind(fontSize: 13.5, fontWeight: FontWeight.w600, color: KiranaNapseTheme.jute)),
                  const SizedBox(height: 10),

                  ...(_reasons.map((r) {
                    final isSelected = _selectedReason == r['code'];
                    final color = r['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedReason = r['code'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? KiranaNapseTheme.turmericTint : KiranaNapseTheme.riceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? KiranaNapseTheme.turmeric : KiranaNapseTheme.sandstone,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(r['icon'] as IconData, color: color, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                r['label'] as String,
                                style: GoogleFonts.hind(
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? KiranaNapseTheme.turmericDark : KiranaNapseTheme.jute,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: KiranaNapseTheme.turmericDark, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  })),

                  const SizedBox(height: 16),

                  Text('Additional Notes (Optional)', style: GoogleFonts.hind(fontSize: 13, fontWeight: FontWeight.w600, color: KiranaNapseTheme.jute)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _freeTextController,
                    maxLines: 3,
                    style: GoogleFonts.hind(color: KiranaNapseTheme.jute),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Wedding season bulk purchase in neighborhood',
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KiranaNapseTheme.turmeric,
                        foregroundColor: const Color(0xFF4A2E0A),
                      ),
                      onPressed: _selectedReason != null && !_isSubmitting ? _submit : null,
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A2E0A)))
                          : Text('Submit Feedback', style: GoogleFonts.hind(fontSize: 14.5, fontWeight: FontWeight.w700)),
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
}
