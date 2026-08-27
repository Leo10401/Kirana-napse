import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Settings screen (AppFlow §7 Screen 9).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: Column(
        children: [
          const TerracottaAppHeader(
            title: 'Settings',
            subtitle: 'Sharma General Store',
          ),
          const ToranGarland(height: 12, opacity: 0.8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store profile
                  _sectionTitle('Store Profile'),
                  _settingsTile(Icons.store_rounded, 'Store Name', 'Sharma General Store', onTap: () {}),
                  _settingsTile(Icons.location_on_rounded, 'Location', 'Lucknow, Uttar Pradesh', onTap: () {}),
                  _settingsTile(Icons.category_rounded, 'Category', 'Kirana & FMCG', onTap: () {}),
                  const SizedBox(height: 20),

                  // Preferences
                  _sectionTitle('Preferences'),
                  _settingsTile(Icons.language_rounded, 'Language', 'हिंदी (Hindi)', onTap: () => context.push('/onboarding/language')),
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: KiranaNapseTheme.riceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KiranaNapseTheme.sandstone, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: KiranaNapseTheme.turmericTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.notifications_active_outlined, color: KiranaNapseTheme.turmericDark, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Push Alerts',
                                style: GoogleFonts.hind(fontSize: 13.5, fontWeight: FontWeight.w600, color: KiranaNapseTheme.jute),
                              ),
                              Text(
                                'Daily 7:00 AM stock alerts & reorder reminders',
                                style: GoogleFonts.hind(fontSize: 11, color: KiranaNapseTheme.juteSoft),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: true,
                          onChanged: (_) {},
                          activeTrackColor: KiranaNapseTheme.terracotta,
                          activeThumbColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Data & Privacy
                  _sectionTitle('Data & Privacy'),
                  _settingsTile(Icons.security_rounded, 'Data Privacy', 'Store sales are strictly private', onTap: () {}),
                  _settingsTile(Icons.backup_rounded, 'Offline Sync', 'All data synced with cloud', onTap: () {}),
                  const SizedBox(height: 20),

                  // About
                  _sectionTitle('About'),
                  _settingsTile(Icons.info_outline_rounded, 'Kirana-Napse', 'Version 2.0.0 (Market Edition)', onTap: () {}),
                  _settingsTile(Icons.support_agent_rounded, 'Help & Support', 'Call or WhatsApp Helpline', onTap: () {}),
                  const SizedBox(height: 24),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthProvider>().logout();
                        context.go('/login');
                      },
                      icon: const Icon(Icons.logout_rounded, color: KiranaNapseTheme.chili, size: 18),
                      label: Text(
                        'Logout Store',
                        style: GoogleFonts.hind(color: KiranaNapseTheme.chili, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: KiranaNapseTheme.chili, width: 1.2),
                        backgroundColor: KiranaNapseTheme.chiliTint.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.hind(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: KiranaNapseTheme.juteSoft,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, String? value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: KiranaNapseTheme.riceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KiranaNapseTheme.sandstone, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: KiranaNapseTheme.turmericTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: KiranaNapseTheme.turmericDark, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.hind(fontSize: 13.5, fontWeight: FontWeight.w600, color: KiranaNapseTheme.jute),
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: GoogleFonts.hind(fontSize: 12, color: KiranaNapseTheme.juteSoft),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded, color: KiranaNapseTheme.juteSoft, size: 18),
          ],
        ),
      ),
    );
  }
}
