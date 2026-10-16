import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/app_config.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Settings screen (AppFlow §7 Screen 9).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

                  // Server & Environment (Dynamic Local & Deployed)
                  _sectionTitle('Server & Environment'),
                  _settingsTile(
                    Icons.cloud_sync_rounded,
                    'Backend Server',
                    AppConfig.currentEnv == ApiEnvironment.local
                        ? 'Local (Testing)'
                        : AppConfig.currentEnv == ApiEnvironment.deployed
                            ? 'Render Cloud'
                            : 'Custom URL',
                    subtitle: AppConfig.baseUrl,
                    onTap: () => _showEnvironmentDialog(context),
                  ),
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

  Widget _settingsTile(
    IconData icon,
    String title,
    String? value, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.hind(fontSize: 13.5, fontWeight: FontWeight.w600, color: KiranaNapseTheme.jute),
                  ),
                  if (subtitle != null) ...[
                    Text(
                      subtitle,
                      style: GoogleFonts.hind(fontSize: 11, color: KiranaNapseTheme.juteSoft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: GoogleFonts.hind(fontSize: 12, fontWeight: FontWeight.w600, color: KiranaNapseTheme.terracotta),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded, color: KiranaNapseTheme.juteSoft, size: 18),
          ],
        ),
      ),
    );
  }

  void _showEnvironmentDialog(BuildContext context) {
    ApiEnvironment tempEnv = AppConfig.currentEnv;
    final TextEditingController customController = TextEditingController(text: AppConfig.customUrl);
    String? testResult;
    bool isTesting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dns_rounded, color: KiranaNapseTheme.terracotta),
                        const SizedBox(width: 8),
                        Text(
                          'Backend Server Environment',
                          style: GoogleFonts.hind(fontSize: 16, fontWeight: FontWeight.w700, color: KiranaNapseTheme.jute),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose where the app sends API requests. First local is default for testing.',
                      style: GoogleFonts.hind(fontSize: 12, color: KiranaNapseTheme.juteSoft),
                    ),
                    const Divider(height: 24),

                    // Option 1: Local Testing (Default)
                    _envOptionCard(
                      title: 'Local Development (Default Testing)',
                      subtitle: AppConfig.defaultLocalUrl,
                      value: ApiEnvironment.local,
                      groupValue: tempEnv,
                      onTap: () {
                        setModalState(() {
                          tempEnv = ApiEnvironment.local;
                          testResult = null;
                        });
                      },
                    ),

                    // Option 2: Render Cloud Deployed
                    _envOptionCard(
                      title: 'Render Cloud (Production)',
                      subtitle: AppConfig.deployedUrl,
                      value: ApiEnvironment.deployed,
                      groupValue: tempEnv,
                      onTap: () {
                        setModalState(() {
                          tempEnv = ApiEnvironment.deployed;
                          testResult = null;
                        });
                      },
                    ),

                    // Option 3: Custom URL
                    _envOptionCard(
                      title: 'Custom IP / Localhost',
                      subtitle: 'For physical device testing via local WiFi IP',
                      value: ApiEnvironment.custom,
                      groupValue: tempEnv,
                      onTap: () {
                        setModalState(() {
                          tempEnv = ApiEnvironment.custom;
                          testResult = null;
                        });
                      },
                    ),

                    if (tempEnv == ApiEnvironment.custom) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customController,
                        decoration: InputDecoration(
                          hintText: 'e.g. http://192.168.1.100:8000/api/v1',
                          labelText: 'Custom Base API URL',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: GoogleFonts.hind(fontSize: 13),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Test connection button & status
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: isTesting
                              ? null
                              : () async {
                                  setModalState(() {
                                    isTesting = true;
                                    testResult = null;
                                  });

                                  String targetUrl;
                                  if (tempEnv == ApiEnvironment.deployed) {
                                    targetUrl = AppConfig.deployedUrl;
                                  } else if (tempEnv == ApiEnvironment.custom) {
                                    targetUrl = customController.text.trim();
                                  } else {
                                    targetUrl = AppConfig.defaultLocalUrl;
                                  }

                                  try {
                                    final res = await ApiClient.testHealthConnection(targetUrl);
                                    setModalState(() {
                                      isTesting = false;
                                      testResult = 'Online (${res['status'] ?? 'ok'})';
                                    });
                                  } catch (e) {
                                    setModalState(() {
                                      isTesting = false;
                                      testResult = 'Offline / Unreachable';
                                    });
                                  }
                                },
                          icon: isTesting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.wifi_tethering_rounded, size: 16),
                          label: Text(
                            'Test Connection',
                            style: GoogleFonts.hind(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (testResult != null)
                          Expanded(
                            child: Text(
                              testResult!,
                              style: GoogleFonts.hind(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: testResult!.contains('Online') ? Colors.green.shade700 : KiranaNapseTheme.chili,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Auto-fallback toggle card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: KiranaNapseTheme.riceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: KiranaNapseTheme.sandstone),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto-Fallback to Render Cloud',
                                  style: GoogleFonts.hind(fontSize: 12.5, fontWeight: FontWeight.w600, color: KiranaNapseTheme.jute),
                                ),
                                Text(
                                  'If local server is offline, requests auto-route to Render',
                                  style: GoogleFonts.hind(fontSize: 10.5, color: KiranaNapseTheme.juteSoft),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: AppConfig.autoFallback,
                            onChanged: (val) async {
                              await AppConfig.setAutoFallback(val);
                              setModalState(() {});
                            },
                            activeTrackColor: KiranaNapseTheme.terracotta,
                            activeThumbColor: Colors.white,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: Text('Cancel', style: GoogleFonts.hind(color: KiranaNapseTheme.juteSoft)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await AppConfig.setEnvironment(
                                tempEnv,
                                customUrl: customController.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.pop(dialogCtx);
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Server set to: ${AppConfig.baseUrl}'),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: KiranaNapseTheme.terracotta,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KiranaNapseTheme.terracotta,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Save & Switch',
                              style: GoogleFonts.hind(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _envOptionCard({
    required String title,
    required String subtitle,
    required ApiEnvironment value,
    required ApiEnvironment groupValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? KiranaNapseTheme.turmericTint.withValues(alpha: 0.3) : KiranaNapseTheme.riceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? KiranaNapseTheme.terracotta : KiranaNapseTheme.sandstone,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? KiranaNapseTheme.terracotta : KiranaNapseTheme.juteSoft,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.hind(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: KiranaNapseTheme.jute,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.hind(
                      fontSize: 11.5,
                      color: isSelected ? KiranaNapseTheme.terracotta : KiranaNapseTheme.juteSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
