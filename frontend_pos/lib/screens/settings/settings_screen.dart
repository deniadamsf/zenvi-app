import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../auth/login_screen.dart';
import '../subscription/plan_screen.dart';
import 'employee_settings_screen.dart';
import 'store_settings_screen.dart';
import 'payment_settings_screen.dart';
import '../../widgets/zenvi_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          ZenviHeader.sliver(
            title: 'settings'.tr(context: context),
            subtitle: user?.name ?? 'profile_subtitle'.tr(context: context),
            actions: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.settings_rounded, color: theme.colorScheme.primary, size: 20),
              ),
            ],
          ),
            SliverPadding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 120.0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800), // Responsive constraints
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (authProvider.isOwner) ...[
                          _buildMenuSection(theme, 'main_menu'.tr(context: context)),
                          const SizedBox(height: 16),
                          _buildSettingsCard(
                            theme: theme,
                            title: 'store_services'.tr(context: context),
                            subtitle: 'store_services_desc'.tr(context: context),
                            icon: Icons.storefront_rounded,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreSettingsScreen())),
                          ),
                          const SizedBox(height: 16),
                          _buildSettingsCard(
                            theme: theme,
                            title: 'employee_access'.tr(context: context),
                            subtitle: 'employee_access_desc'.tr(context: context),
                            icon: Icons.people_alt_rounded,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeSettingsScreen())),
                          ),
                          const SizedBox(height: 16),
                          _buildSettingsCard(
                            theme: theme,
                            title: 'payment_methods'.tr(context: context),
                            subtitle: 'payment_methods_desc'.tr(context: context),
                            icon: Icons.payments_rounded,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentSettingsScreen())),
                          ),
                          const SizedBox(height: 16),
                          _buildSettingsCard(
                            theme: theme,
                            title: 'subscription_title'.tr(context: context),
                            subtitle: 'subscription_menu_desc'.tr(context: context),
                            icon: Icons.workspace_premium_rounded,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanScreen())),
                          ),
                          const SizedBox(height: 32),
                        ],
                        
                        _buildMenuSection(theme, 'account_app'.tr(context: context)),
                        const SizedBox(height: 16),
                        
                        // Theme Toggle
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: theme.shadowColor.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => themeProvider.toggleTheme(),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: Icon(themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: theme.colorScheme.primary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('dark_mode'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                          Text('toggle_theme'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: themeProvider.isDarkMode,
                                      onChanged: (val) => themeProvider.toggleTheme(),
                                      activeThumbColor: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().fade(delay: 100.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 16),
                        
                        // Language
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: theme.shadowColor.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: Icon(Icons.language_rounded, color: theme.colorScheme.primary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('language'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                          Text('language_desc'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: _buildLanguageOption(context, theme, 'id', 'indonesia_9'.tr(context: context), '🇮🇩', context.locale.languageCode == 'id')),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildLanguageOption(context, theme, 'en', 'english_7'.tr(context: context), '🇬🇧', context.locale.languageCode == 'en')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate().fade(delay: 150.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 16),
                        
                        // Privacy Policy
                        _buildSettingsCard(
                          theme: theme,
                          title: 'privacy_policy_title'.tr(context: context),
                          subtitle: 'privacy_policy_subtitle'.tr(context: context),
                          icon: Icons.shield_outlined,
                          onTap: () async {
                            final lang = context.locale.languageCode;
                            final uri = Uri.parse('https://zenvi.cellanoma.my.id/privacy-policy?lang=$lang');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ).animate().fade(delay: 180.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 32),
                        
                        // Logout
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('logout_confirm_title'.tr(context: context)),
                                    content: Text('logout_confirm_desc'.tr(context: context)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr(context: context))),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: Colors.white),
                                        child: Text('logout'.tr(context: context)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await authProvider.logout();
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                                  }
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('logout_account'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
                                          Text('logout_desc'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildMenuSection(ThemeData theme, String title) {
    return Text(
      title,
      style: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    ).animate().fade().slideX(begin: -0.1, end: 0);
  }

  Widget _buildSettingsCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }

  Widget _buildLanguageOption(BuildContext context, ThemeData theme, String code, String name, String flag, bool isSelected) {
    return InkWell(
      onTap: () async {
        await context.setLocale(Locale(code));
        if (context.mounted) {
          setState(() {});
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

