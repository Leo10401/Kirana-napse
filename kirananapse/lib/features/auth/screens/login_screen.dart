import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '+919876543210');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _phoneController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) {
      if (auth.isOnboarded) {
        context.go('/home');
      } else {
        context.go('/onboarding/language');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: KiranaNapseTheme.rice,
      body: SafeArea(
        child: Column(
          children: [
            const ToranGarland(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Logo badge (Turmeric circle with storefront)
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: KiranaNapseTheme.turmeric,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.storefront_rounded,
                            size: 34,
                            color: Color(0xFF4A2E0A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Center(
                      child: Text(
                        'Kirana-Napse',
                        style: GoogleFonts.baloo2(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: KiranaNapseTheme.terracotta,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Apni dukaan, samajhdaar stock',
                        style: GoogleFonts.hind(
                          fontSize: 13,
                          color: KiranaNapseTheme.juteSoft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    Text(
                      'Welcome Back / नमस्ते',
                      style: GoogleFonts.baloo2(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: KiranaNapseTheme.jute,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter your phone number to continue',
                      style: GoogleFonts.hind(
                        fontSize: 13,
                        color: KiranaNapseTheme.juteSoft,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Phone field
                    Text(
                      'Phone Number',
                      style: GoogleFonts.hind(
                        color: KiranaNapseTheme.jute,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.hind(color: KiranaNapseTheme.jute, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        hintText: '+91 98765 43210',
                        prefixIcon: Icon(Icons.phone_outlined, color: KiranaNapseTheme.juteMuted, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    Text(
                      'Password',
                      style: GoogleFonts.hind(
                        color: KiranaNapseTheme.jute,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.hind(color: KiranaNapseTheme.jute),
                      decoration: InputDecoration(
                        hintText: 'Enter password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: KiranaNapseTheme.juteMuted, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: KiranaNapseTheme.juteMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    if (auth.error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: KiranaNapseTheme.chiliTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: KiranaNapseTheme.chili, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: GoogleFonts.hind(color: KiranaNapseTheme.chili, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Login button
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
                        onPressed: auth.isLoading ? null : _login,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A2E0A)),
                              )
                            : Text(
                                'Sign In',
                                style: GoogleFonts.hind(fontSize: 14.5, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Register link
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/register'),
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: GoogleFonts.hind(color: KiranaNapseTheme.juteSoft, fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Register Store',
                                style: GoogleFonts.hind(
                                  color: KiranaNapseTheme.terracotta,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
