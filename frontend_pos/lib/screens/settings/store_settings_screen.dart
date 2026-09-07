import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../reservation/reservation_list_screen.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/zenvi_header.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val == 1 || val == true || val == '1' || val == 'true') return true;
    return false;
  }

  String _getStorePortalUrl(Map<String, dynamic>? company) {
    final customSlug = company?['slug'];
    if (customSlug != null && customSlug.toString().isNotEmpty) {
      return 'https://zenvi.cellanoma.my.id/menu/$customSlug';
    }
    final companyName = company?['name'] ?? 'toko';
    final slug = companyName.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return 'https://zenvi.cellanoma.my.id/menu/$slug';
  }

  void _showQrCodeDialog(BuildContext context, ThemeData theme, Map<String, dynamic>? company) {
    final url = _getStorePortalUrl(company);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.qr_code_2_rounded, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'qr_code_portal_toko'.tr(context: context),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Kode QR harus gelap di atas putih supaya tetap terpindai; ini
                // sengaja tidak mengikuti tema.
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    tooltip: 'salin_tautan'.tr(context: context),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('tautan_web_toko_berhasil'.tr(context: context)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('tutup_modal'.tr(context: context)),
          ),
        ],
      ),
    );
  }

  void _showEditQrMenuDialog(BuildContext context, ThemeData theme, AuthProvider auth) {
    final company = auth.user?.company;
    final slugCtrl = TextEditingController(text: company?['slug'] ?? '');
    final descCtrl = TextEditingController(text: company?['qr_menu_description'] ?? '');
    String selectedLanguage = company?['default_language'] ?? 'id';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'pengaturan_web_menu'.tr(context: context),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('custom_url_slug'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: slugCtrl,
                    decoration: InputDecoration(
                      hintText: 'contoh_slug_hint'.tr(context: context),
                      prefixText: 'zenvi.cellanoma.my.id/menu/',
                      prefixStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('deskripsi_toko'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'deskripsi_toko_hint'.tr(context: context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('bahasa_bawaan'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedLanguage == 'en' ? 'en' : 'id',
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: [
                      DropdownMenuItem(value: 'id', child: Text('indonesia_9'.tr(context: context))),
                      DropdownMenuItem(value: 'en', child: Text('english_7'.tr(context: context))),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedLanguage = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: Text('batal_5'.tr(context: context)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setModalState(() => isSubmitting = true);
                        final success = await auth.updateCompanySetting(
                          slug: slugCtrl.text.trim(),
                          qrMenuDescription: descCtrl.text.trim(),
                          defaultLanguage: selectedLanguage,
                        );
                        if (!ctx.mounted) return;
                        setModalState(() => isSubmitting = false);
                        if (success) {
                          Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('pengaturan_berhasil_disimpan'.tr(context: context))),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('gagal_menyimpan_pengaturan'.tr(context: context)),
                              backgroundColor: AppColors.dangerFill,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('save'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditMembershipDialog(BuildContext context, ThemeData theme, AuthProvider auth) {
    final discountCtrl = TextEditingController(
      text: (auth.defaultMemberDiscountPercent).toStringAsFixed(0),
    );
    final earningAmountCtrl = TextEditingController(
      text: (auth.pointEarningAmount).toStringAsFixed(0),
    );
    final redeemRateCtrl = TextEditingController(
      text: (auth.pointRedeemRate).toStringAsFixed(auth.pointRedeemRate % 1 == 0 ? 0 : 2),
    );
    bool isPointsEnabled = auth.isPointsEnabled;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentEarning = double.tryParse(earningAmountCtrl.text) ?? 1000.0;
          final currentRedeemRate = double.tryParse(redeemRateCtrl.text) ?? 1.0;
          final examplePoints = currentEarning > 0 ? (100000 / currentEarning).floor() : 0;
          final exampleRedeemDiscount = (1000 * currentRedeemRate).floor();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 14, bottom: 6),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 12, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.card_membership_rounded, color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'membership_poin_title'.tr(context: context),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Bagian 1: Diskon Member ──
                          _SectionLabel(
                            icon: Icons.percent_rounded,
                            color: theme.colorScheme.primary,
                            title: 'membership_diskon_title'.tr(context: context),
                            subtitle: 'membership_diskon_subtitle'.tr(context: context),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: discountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '0',
                              suffixText: '%',
                              prefixIcon: const Icon(Icons.percent_rounded, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1),
                          const SizedBox(height: 20),

                          // ── Bagian 2: Sistem Poin Toggle ──
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isPointsEnabled
                                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isPointsEnabled
                                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                    : theme.dividerColor.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isPointsEnabled
                                        ? AppColors.warningFill.withValues(alpha: 0.2)
                                        : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.stars_rounded, color: isPointsEnabled ? AppColors.warningFill : theme.colorScheme.onSurfaceVariant, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('membership_sistem_poin'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text(
                                        isPointsEnabled ? 'membership_poin_aktif'.tr(context: context) : 'membership_poin_nonaktif'.tr(context: context),
                                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isPointsEnabled,
                                  onChanged: (val) => setModalState(() => isPointsEnabled = val),
                                ),
                              ],
                            ),
                          ),

                          if (isPointsEnabled) ...[
                            const SizedBox(height: 24),

                            // ── Bagian 2A: Cara Mendapat Poin ──
                            _SectionLabel(
                              icon: Icons.add_circle_outline_rounded,
                              color: AppColors.warningText,
                              title: 'membership_earning_title'.tr(context: context),
                              subtitle: 'membership_earning_subtitle'.tr(context: context),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: earningAmountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'membership_earning_label'.tr(context: context),
                                prefixText: 'Rp ',
                                hintText: '1000',
                                helperText: 'membership_earning_helper'.tr(context: context),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [500, 1000, 2000, 5000, 10000].map((amt) {
                                final isSelected = earningAmountCtrl.text == amt.toString();
                                return InkWell(
                                  onTap: () {
                                    earningAmountCtrl.text = amt.toString();
                                    setModalState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.warningText : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Rp ${NumberFormat('#,###', 'id_ID').format(amt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.warningFill.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.warningFill.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.warningText),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'membership_earning_example'.tr(context: context, args: [examplePoints.toString()]),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warningText),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                            const Divider(height: 1),
                            const SizedBox(height: 20),

                            // ── Bagian 2B: Cara Memakai Poin ──
                            _SectionLabel(
                              icon: Icons.redeem_rounded,
                              color: AppColors.successText,
                              title: 'membership_redeem_title'.tr(context: context),
                              subtitle: 'membership_redeem_subtitle'.tr(context: context),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: redeemRateCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'membership_redeem_label'.tr(context: context),
                                prefixText: '1 Poin = Rp ',
                                hintText: '100',
                                helperText: 'membership_redeem_helper'.tr(context: context),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [1.0, 10.0, 50.0, 100.0, 500.0, 1000.0].map((rate) {
                                final isSelected = double.tryParse(redeemRateCtrl.text) == rate;
                                return InkWell(
                                  onTap: () {
                                    redeemRateCtrl.text = rate % 1 == 0 ? rate.toStringAsFixed(0) : rate.toString();
                                    setModalState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.successText : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Rp ${NumberFormat('#,###', 'id_ID').format(rate)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.successFill.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.successFill.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.successText),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'membership_redeem_example'.tr(context: context, args: [NumberFormat('#,###', 'id_ID').format(exampleRedeemDiscount)]),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.successText),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('batal_5'.tr(context: context)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    setModalState(() => isSubmitting = true);
                                    final discount = double.tryParse(discountCtrl.text.trim()) ?? 0.0;
                                    final earning = double.tryParse(earningAmountCtrl.text.trim()) ?? 1000.0;
                                    final redeemRate = double.tryParse(redeemRateCtrl.text.trim()) ?? 1.0;

                                    final success = await auth.updateCompanySetting(
                                      memberDefaultDiscount: discount,
                                      isPointsEnabled: isPointsEnabled,
                                      pointEarningAmount: earning > 0 ? earning : 1000.0,
                                      pointRedeemRate: redeemRate > 0 ? redeemRate : 1.0,
                                    );
                                    if (!ctx.mounted) return;
                                    setModalState(() => isSubmitting = false);
                                    if (success) {
                                      Navigator.pop(ctx);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('pengaturan_berhasil_disimpan'.tr(context: context))),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text('gagal_menyimpan_pengaturan'.tr(context: context)),
                                          backgroundColor: AppColors.dangerFill,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text('save'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          ZenviHeader.sliver(
            title: 'store_services'.tr(context: context),
            showBackButton: true,
          ),
            SliverPadding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 120.0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── SECTION 1: WEB PORTAL & TOKO ONLINE ──
                        Text(
                          'web_portal_toko_online'.tr(context: context).toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: _buildQrMenuSettingRow(context, theme, authProvider),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── SECTION 2: BRANDING & LOGO TOKO ──
                        Text(
                          'branding_identitas_section'.tr(context: context).toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: _buildLogoSettingRow(context, theme, authProvider),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildQrMenuSettingRow(BuildContext context, ThemeData theme, AuthProvider authProvider) {
    final company = authProvider.user?.company;
    final isQrEnabled = _parseBool(company?['is_qr_menu_enabled']);
    final isReservationEnabled = _parseBool(company?['is_reservation_enabled']);
    final portalUrl = _getStorePortalUrl(company);

    // Fitur yang tidak termasuk paket saat ini. Sakelarnya tetap ditampilkan —
    // menyembunyikannya berarti pemilik toko tidak pernah tahu fiturnya ada.
    final qrLocked = !authProvider.hasFeature('qr_menu');
    final reservationLocked = !authProvider.hasFeature('reservation');
    final membershipLocked = !authProvider.hasFeature('membership');
    final productImageLocked = !authProvider.hasFeature('product_image');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'halaman_web_publik_toko'.tr(context: context),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 16),

        // 1. Menu Digital QR Switch Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.successFill.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.successText, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text('menu_digital_qr_code'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              if (qrLocked) const PremiumBadge(compact: true),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'pelanggan_bisa_scan_qr'.tr(context: context),
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PremiumSwitch(
                locked: qrLocked,
                feature: 'qr_menu',
                value: isQrEnabled,
                onChanged: (val) async {
                  await authProvider.updateCompanySetting(isQrMenuEnabled: val);
                },
              ),
            ],
          ),
        ),

        // 2. Reservasi / Booking Online Switch Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.event_seat_rounded, color: theme.colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                'reservasi_online'.tr(context: context),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'salonfnbjasa'.tr(context: context),
                                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (reservationLocked) const PremiumBadge(compact: true),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'pelanggan_dapat_memesan_jadwal'.tr(context: context),
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PremiumSwitch(
                locked: reservationLocked,
                feature: 'reservation',
                value: isReservationEnabled,
                onChanged: (val) async {
                  await authProvider.updateCompanySetting(isReservationEnabled: val);
                },
              ),
            ],
          ),
        ),

        // 3. Membership / Loyalty Program Toggle Card
        Builder(
          builder: (context) {
            final isMembershipEnabled = authProvider.isMembershipEnabled;
            final isPointsEnabled = authProvider.isPointsEnabled;
            final earningAmt = authProvider.pointEarningAmount;
            final defaultDiscount = authProvider.defaultMemberDiscountPercent;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.warningFill.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.card_membership_rounded, color: AppColors.warningText, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        'program_membership'.tr(context: context),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.warningFill.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'loyalty_badge'.tr(context: context),
                                          style: const TextStyle(color: AppColors.warningText, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (membershipLocked) const PremiumBadge(compact: true),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'kelola_data_member_poin'.tr(context: context),
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      PremiumSwitch(
                        locked: membershipLocked,
                        feature: 'membership',
                        value: isMembershipEnabled,
                        onChanged: (val) async {
                          await authProvider.updateCompanySetting(isMembershipEnabled: val);
                        },
                      ),
                    ],
                  ),
                  if (isMembershipEnabled) ...[
                    const SizedBox(height: 12),
                    Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPointsEnabled ? Icons.stars_rounded : Icons.star_border_rounded,
                                size: 18,
                                color: isPointsEnabled ? AppColors.warningText : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isPointsEnabled
                                      ? 'poin_status_active'.tr(context: context, args: [NumberFormat('#,###', 'id_ID').format(earningAmt)])
                                      : 'poin_status_inactive'.tr(context: context),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isPointsEnabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 26),
                            child: Text(
                              'diskon_default_label'.tr(context: context, args: [defaultDiscount.toStringAsFixed(0)]),
                              style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _showEditMembershipDialog(context, theme, authProvider),
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: Text('atur_poin_diskon_btn'.tr(context: context), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),

        // 4. Katalog Foto Produk Toggle Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.photo_library_rounded, color: Color(0xFF6366F1), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                'katalog_foto_produk_title'.tr(context: context),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (productImageLocked) const PremiumBadge(compact: true),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'katalog_foto_produk_desc'.tr(context: context),
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PremiumSwitch(
                locked: productImageLocked,
                feature: 'product_image',
                value: authProvider.isProductImageEnabled,
                onChanged: (val) async {
                  await authProvider.updateCompanySetting(isProductImageEnabled: val);
                },
              ),
            ],
          ),
        ),

        // Active Portal Link & Actions (If either Menu or Reservation is enabled)
        if (isQrEnabled || isReservationEnabled) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.link_rounded, color: theme.colorScheme.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        portalUrl,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'salin_tautan'.tr(context: context),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: portalUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('tautan_web_toko_berhasil'.tr(context: context)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showQrCodeDialog(context, theme, company),
                        icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                        label: Text('cetak_qr_code'.tr(context: context)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _showEditQrMenuDialog(context, theme, authProvider),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: Text('settings'.tr(context: context)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                if (isReservationEnabled) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReservationListScreen()),
                        );
                      },
                      icon: const Icon(Icons.event_seat_rounded, size: 18),
                      label: Text('buka_daftar_reservasi_masuk'.tr(context: context)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoSettingRow(BuildContext context, ThemeData theme, AuthProvider authProvider) {
    final company = authProvider.user?.company;
    final logoUrl = company?['logo_url']?.toString();
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo Avatar Preview
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hasLogo ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.dividerColor.withValues(alpha: 0.15),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: hasLogo
                ? Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.storefront_rounded,
                      color: theme.colorScheme.primary,
                      size: 36,
                    ),
                  )
                : Icon(
                    Icons.add_photo_alternate_rounded,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'logo_toko_usaha'.tr(context: context),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'opsional_badge'.tr(context: context),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'dicetak_hitamputih_di_nota'.tr(context: context),
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickAndUploadLogo(context, authProvider),
                    icon: Icon(hasLogo ? Icons.edit_rounded : Icons.file_upload_outlined, size: 16),
                    label: Text(hasLogo ? 'ganti_logo'.tr(context: context) : 'unggah_logo'.tr(context: context), style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (hasLogo)
                    TextButton.icon(
                      onPressed: () => _confirmRemoveLogo(context, authProvider),
                      icon: Icon(Icons.delete_outline_rounded, size: 16, color: theme.colorScheme.error),
                      label: Text('hapus_logo'.tr(context: context), style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadLogo(BuildContext context, AuthProvider authProvider) async {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cropTitle = 'potong_logo_toko'.tr(context: context);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      File finalFile = File(pickedFile.path);

      // 1. Interactive Cropping with ImageCropper (1:1 square ratio)
      try {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressQuality: 85,
          maxWidth: 512,
          maxHeight: 512,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: cropTitle,
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
            IOSUiSettings(
              title: cropTitle,
              aspectRatioLockEnabled: true,
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
          ],
        );
        if (croppedFile != null) {
          finalFile = File(croppedFile.path);
        }
      } catch (cropErr) {
        debugPrint('ImageCropper fallback: $cropErr');
      }

      // 2. Client-Side Image Resize & Square Crop via package:image for ultra-lightweight size (< 60KB)
      try {
        final bytes = await finalFile.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final squareSize = decoded.width < decoded.height ? decoded.width : decoded.height;
          final cropped = img.copyCrop(
            decoded,
            x: (decoded.width - squareSize) ~/ 2,
            y: (decoded.height - squareSize) ~/ 2,
            width: squareSize,
            height: squareSize,
          );
          final resized = img.copyResize(cropped, width: 400, height: 400);
          final compressedBytes = img.encodeJpg(resized, quality: 85);

          final tempDir = await getTemporaryDirectory();
          final optimizedPath = '${tempDir.path}/logo_optimized_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final optimizedFile = File(optimizedPath);
          await optimizedFile.writeAsBytes(compressedBytes);
          finalFile = optimizedFile;
        }
      } catch (optErr) {
        debugPrint('Image optimization fallback: $optErr');
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mengunggah_logo_toko'.tr(context: context))),
      );

      final success = await authProvider.uploadCompanyLogo(finalFile);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('logo_toko_berhasil_diperbarui'.tr(context: context)),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('gagal_mengunggah_logo_toko'.tr(context: context)),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_memilih_gambar'.tr(context: context, args: [e.toString()]))),
        );
      }
    }
  }

  Future<void> _confirmRemoveLogo(BuildContext context, AuthProvider authProvider) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('hapus_logo_toko'.tr(context: context)),
        content: Text('logo_toko_tidak_akan'.tr(context: context)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('batal_5'.tr(context: context))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('hapus_logo'.tr(context: context)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await authProvider.removeCompanyLogo();
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('logo_toko_berhasil_dihapus'.tr(context: context))),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('gagal_menghapus_logo_toko'.tr(context: context)),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

// ─── Helper Widget ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionLabel({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
