import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../dashboard/employee_dashboard_screen.dart';
import 'role_selection_screen.dart';
import 'login_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus({bool showFeedback = true}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.fetchUserData();

    if (!mounted) return;
    setState(() => _isChecking = false);

    final user = authProvider.user;
    if (user != null) {
      if (user.companyId == null) {
        // Employee was rejected / removed by owner
        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('permohonan_anda_ditolak_atau_20'.tr(context: context)),
              backgroundColor: AppColors.warningFill,
            ),
          );
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => RoleSelectionScreen()),
          (route) => false,
        );
      } else if (user.isApproved) {
        // Approved by Owner!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat! Akun Anda telah disetujui oleh Owner ${user.company?['name'] ?? ''}.'),
            backgroundColor: AppColors.successFill,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeDashboardScreen()),
          (route) => false,
        );
      } else {
        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('status_masih_menunggu_persetujuan_21'.tr(context: context)),
              backgroundColor: AppColors.neutralText,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleCancelJoin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('batalkan_pendaftaran_22'.tr(context: context)),
        content: Text('apakah_anda_yakin_ingin_23'.tr(context: context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('kembali_24'.tr(context: context)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerFill, foregroundColor: Colors.white),
            child: Text('ya_batalkan_25'.tr(context: context)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.cancelJoinCompany();
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('pendaftaran_dibatalkan_26'.tr(context: context)),
            backgroundColor: AppColors.neutralText,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => RoleSelectionScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('gagal_membatalkan_permohonan_silakan_27'.tr(context: context)),
            backgroundColor: AppColors.dangerFill,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final user = authProvider.user;
    final companyName = user?.company?['name']?.toString() ?? 'toko_4'.tr(context: context);
    final branchName = user?.branch?['name']?.toString() ?? 'utama_5'.tr(context: context);

    return Scaffold(
      appBar: AppBar(
        title: Text('status_pendaftaran_28'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'keluar_akun_11'.tr(context: context),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Animated Clock / Hourglass Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warningFill.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.warningFill.withValues(alpha: 0.4), width: 3),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 52,
                      color: AppColors.warningFill,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1500.ms),

                  const SizedBox(height: 28),

                  Text(
                    'menunggu_verifikasi_owner_25'.tr(context: context),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fade().slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 10),

                  Text(
                    'permohonan_anda_sedang_ditinjau_101'.tr(context: context),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ).animate().fade(delay: 150.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 32),

                  // Detail Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceAlt : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.person_outline_rounded,
                          label: 'nama_karyawan_13'.tr(context: context),
                          value: user?.name ?? '-',
                          isDark: isDark,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.storefront_rounded,
                          label: 'toko_perusahaan_17'.tr(context: context),
                          value: companyName,
                          isDark: isDark,
                          highlightValue: true,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.location_on_outlined,
                          label: 'cabang_penempatan_17'.tr(context: context),
                          value: branchName,
                          isDark: isDark,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.info_outline_rounded,
                          label: 'status_akun_11'.tr(context: context),
                          value: 'menunggu_persetujuan_20'.tr(context: context),
                          isDark: isDark,
                          statusColor: AppColors.warningText,
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 250.ms).scale(begin: const Offset(0.95, 0.95)),

                  const SizedBox(height: 36),

                  // Refresh Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : () => _checkStatus(showFeedback: true),
                      icon: _isChecking 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded),
                      label: Text(
                        _isChecking ? 'memeriksa_12'.tr(context: context) : 'cek_status_persetujuan_22'.tr(context: context),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ).animate().fade(delay: 350.ms),

                  SizedBox(height: 14),

                  // Cancel / Change Store Button
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: authProvider.isLoading ? null : _handleCancelJoin,
                      icon: Icon(Icons.close_rounded, size: 18),
                      label: Text(
                        'batalkan_pendaftaran_ganti_toko_33'.tr(context: context),
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dangerText,
                        side: BorderSide(color: AppColors.dangerFill.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ).animate().fade(delay: 450.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool highlightValue = false,
    Color? statusColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: statusColor ?? (isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: highlightValue || statusColor != null ? FontWeight.bold : FontWeight.w600,
            color: statusColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}
