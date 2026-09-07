import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/zenvi_header.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val == 1 || val == true || val == '1' || val == 'true') return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            ZenviHeader.sliver(
              title: 'pembayaran_kasir_16'.tr(context: context),
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
                        Text(
                          'metode_pembayaran_17'.tr(context: context),
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(color: theme.shadowColor.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10))
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'tunai_cash_selalu_aktif_89'.tr(context: context),
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                
                                // QRIS Toggle
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.qr_code_2_rounded, size: 24, color: theme.colorScheme.primary),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('qris_digital_405'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold)),
                                                  Text('terima_pembayaran_kode_qris_406'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: _parseBool(authProvider.user?.company?['is_qris_enabled'] ?? 1),
                                        onChanged: (val) async {
                                          await authProvider.updateCompanySetting(isQrisEnabled: val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Transfer Toggle
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.account_balance_rounded, size: 24, color: theme.colorScheme.primary),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('transfer_bank_314'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold)),
                                                  Text('terima_transfer_rekening_bank_407'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: _parseBool(authProvider.user?.company?['is_transfer_enabled'] ?? 1),
                                        onChanged: (val) async {
                                          await authProvider.updateCompanySetting(isTransferEnabled: val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
