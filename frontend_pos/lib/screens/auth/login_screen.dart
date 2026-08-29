import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/owner_dashboard_screen.dart';
import '../dashboard/employee_dashboard_screen.dart';
import 'role_selection_screen.dart';
import 'pending_approval_screen.dart';
import '../../widgets/zenvi_logo_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingSession();
    });
  }

  void _checkExistingSession() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      _routeUser(authProvider);
    }
  }

  void _routeUser(AuthProvider authProvider) {
    final user = authProvider.user;
    if (user == null) return;

    if (user.companyId == null) {
      // Akun baru / belum ada perusahaan
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RoleSelectionScreen()),
      );
    } else if (!user.isApproved) {
      // Karyawan menunggu verifikasi Owner
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
      );
    } else if (user.isOwner) {
      // Owner aktif
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
      );
    } else {
      // Karyawan aktif
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmployeeDashboardScreen()),
      );
    }
  }

  void _showLoginError(String? error) {
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${'login_failed_msg'.tr()}: $error',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Dynamic Abstract Background (Animated Blobs with Blur)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          AnimatedBuilder(
            animation: _blobController,
            builder: (_, child) {
              return Positioned(
                top: -150 + (60 * _blobController.value),
                left: -100 + (40 * _blobController.value),
                child: Container(
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, child) {
              return Positioned(
                bottom: -150 - (50 * _blobController.value),
                right: -100 + (30 * _blobController.value),
                child: Container(
                  width: size.width * 0.9,
                  height: size.width * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: isDark ? 0.15 : 0.1),
                  ),
                ),
              );
            },
          ),
          // Blur Layer to make blobs look like smooth gradients
          Positioned.fill(
            child: IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
                child: const SizedBox(),
              ),
            ),
          ),
          
          // Foreground Content
          SafeArea(
            child: Column(
              children: [
                // Top Action Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Language Switcher
                      TextButton(
                        onPressed: () async {
                          if (context.locale.languageCode == 'en') {
                            await context.setLocale(const Locale('id'));
                          } else {
                            await context.setLocale(const Locale('en'));
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Theme.of(context).cardTheme.color?.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          context.locale.languageCode.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Theme Switcher
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: IconButton(
                          icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                          onPressed: () {
                            themeProvider.toggleTheme();
                          },
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 600.ms).slideY(begin: -0.5, end: 0, curve: Curves.easeOutCubic),
                ),
                
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color?.withValues(alpha: isDark ? 0.3 : 0.6),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo
                                ZenviLogo(size: 68, variant: ZenviLogoVariant.iconOnly)
                                 .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                 .shimmer(duration: 3.seconds, color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
                                
                                const SizedBox(height: 20),
                                Text(
                                  'welcome_to_zenvi'.tr(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                                
                                const SizedBox(height: 8),
                                Text(
                                  'smart_pos_subtitle'.tr(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 13,
                                    color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                                    height: 1.35,
                                  ),
                                ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                                
                                const SizedBox(height: 32),
                                
                                // Tombol Utama: Sign in with Google (Owner)
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: authProvider.isLoading ? null : () async {
                                      final success = await authProvider.loginWithGoogle(bypassRole: 'Owner');
                                      if (!mounted) return;
                                      if (success) {
                                        _routeUser(authProvider);
                                      } else {
                                        _showLoginError(authProvider.lastError);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 3,
                                      shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                    ),
                                    icon: authProvider.isLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                        : const Icon(Icons.storefront_rounded, size: 22),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        authProvider.isLoading ? 'connecting'.tr() : 'sign_in_as_owner'.tr(),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                    ),
                                  ),
                                ).animate().fade(delay: 400.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                                
                                const SizedBox(height: 14),
                                
                                // Divider 'OR'
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                                  ],
                                ).animate().fade(delay: 450.ms),

                                const SizedBox(height: 14),

                                // Tombol Google Sign In Karyawan / Kasir
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: authProvider.isLoading ? null : () async {
                                      final success = await authProvider.loginWithGoogle(bypassRole: 'Employee');
                                      if (!mounted) return;
                                      if (success) {
                                        _routeUser(authProvider);
                                      } else {
                                        _showLoginError(authProvider.lastError);
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                    ),
                                    icon: authProvider.isLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                                        : const Icon(Icons.badge_rounded, size: 22),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        authProvider.isLoading ? 'connecting'.tr() : 'sign_in_as_employee'.tr(),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                    ),
                                  ),
                                ).animate().fade(delay: 500.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),

                                const SizedBox(height: 24),

                                // Footnote
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 15, color: Theme.of(context).primaryColor),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'system_will_automatically_detect_72'.tr(context: context),
                                          style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6), height: 1.35),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fade(delay: 600.ms),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fade().scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
