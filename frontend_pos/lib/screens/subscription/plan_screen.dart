import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/billing_service.dart';
import '../../widgets/zenvi_header.dart';

/// Halaman "Paket Langganan".
///
/// Katalog paket (fitur & batas) datang dari server supaya tidak pernah
/// menyimpang dari yang benar-benar ditegakkan backend. HARGA datang dari Google
/// Play, bukan dari kode maupun dari server - menyimpannya di dua tempat akan
/// membuat angka yang tampil berbeda dari yang benar-benar ditagih Google.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _isLoading = true;
  bool _purchasing = false;
  String? _error;
  String _currentPlan = 'free';
  List<dynamic> _plans = [];
  Map<String, dynamic> _usage = {};

  final _billing = BillingService.instance;

  @override
  void initState() {
    super.initState();
    _load();
    _initBilling();
  }

  @override
  void dispose() {
    _billing.dispose();
    super.dispose();
  }

  Future<void> _initBilling() async {
    await _billing.init(
      onPending: (_) {
        if (mounted) setState(() => _purchasing = true);
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _purchasing = false);
        _snack(message);
      },
      onDone: (purchase, verified) async {
        if (!mounted) return;
        setState(() => _purchasing = false);
        if (verified) {
          // Paket diambil ulang dari server, bukan diasumsikan dari sisi klien.
          await context.read<AuthProvider>().fetchUserData();
          if (!mounted) return;
          _snack('purchase_success'.tr(context: context));
          _load();
        } else {
          _snack('purchase_unverified'.tr(context: context));
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get('/plans');
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
      final data = jsonDecode(response.body)['data'] ?? {};
      if (!mounted) return;
      setState(() {
        _currentPlan = data['current_plan']?.toString() ?? 'free';
        _plans = data['plans'] as List<dynamic>? ?? [];
        _usage = Map<String, dynamic>.from(data['usage'] ?? {});
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'plan_load_failed'.tr(context: context);
        _isLoading = false;
      });
    }
  }

  Future<void> _buy(ProductDetails product) async {
    setState(() => _purchasing = true);
    final started = await _billing.buy(product);
    if (!started && mounted) {
      setState(() => _purchasing = false);
      _snack('purchase_failed_start'.tr(context: context));
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _limitText(BuildContext context, dynamic value) =>
      value == null ? 'unlimited'.tr(context: context) : value.toString();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ZenviHeader(
              title: 'subscription_title'.tr(context: context),
              subtitle: 'subscription_subtitle'.tr(context: context),
              showBackButton: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.restore_rounded, size: 22),
                  tooltip: 'restore_purchases'.tr(context: context),
                  onPressed: () {
                    // Snack ditampilkan SEBELUM await: hasil restore datang
                    // lewat purchaseStream, bukan dari nilai balik fungsi ini,
                    // jadi tidak ada gunanya menunggu - dan menunggu berarti
                    // memakai context setelah async gap.
                    _snack('restore_started'.tr(context: context));
                    _billing.restore();
                  },
                ),
              ],
            ),
            if (_purchasing) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError(theme)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (auth.isFoundingMember) _buildFoundingBanner(theme),
                              ..._plans.map((plan) => _buildPlanCard(theme, plan, auth)),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(_error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: Text('retry'.tr(context: context))),
          ],
        ),
      );

  /// Toko yang terdaftar sebelum langganan diberlakukan mendapat paket berbayar
  /// selamanya. Ditampilkan sebagai penghargaan, bukan sekadar status.
  Widget _buildFoundingBanner(ThemeData theme) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('founding_member_title'.tr(context: context),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('founding_member_desc'.tr(context: context),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildPlanCard(ThemeData theme, dynamic plan, AuthProvider auth) {
    final code = plan['code']?.toString() ?? '';
    final isCurrent = code == _currentPlan;
    final limits = Map<String, dynamic>.from(plan['limits'] ?? {});
    final features = plan['features'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.3),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan['name']?.toString() ?? code,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('current_plan_badge'.tr(context: context),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLimitRow(theme, 'limit_employees'.tr(context: context),
              _limitText(context, limits['employees']), _usage['employees']),
          _buildLimitRow(theme, 'limit_branches'.tr(context: context),
              _limitText(context, limits['branches']), _usage['branches']),
          _buildLimitRow(theme, 'limit_products'.tr(context: context),
              _limitText(context, limits['products']), _usage['products']),
          _buildLimitRow(
            theme,
            'limit_history'.tr(context: context),
            limits['history_days'] == null
                ? 'history_full'.tr(context: context)
                : 'history_days'
                    .tr(context: context, namedArgs: {'days': '${limits['history_days']}'}),
            null,
          ),
          if (features.isNotEmpty) ...[
            const Divider(height: 28),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(f['label']?.toString() ?? '',
                              style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                )),
          ],
          if (!isCurrent && code != 'free') _buildPurchaseArea(theme, code, auth),
        ],
      ),
    );
  }

  Widget _buildPurchaseArea(ThemeData theme, String code, AuthProvider auth) {
    // Founding member tidak pernah ditawari membeli - paketnya sudah permanen,
    // dan menawarkan pembelian hanya akan membingungkan.
    if (auth.isFoundingMember) return const SizedBox.shrink();

    final monthly = _billing.productFor(BillingService.productIdFor(code, yearly: false) ?? '');
    final yearly = _billing.productFor(BillingService.productIdFor(code, yearly: true) ?? '');

    // Produk belum tersedia: belum dibuat di Play Console, atau aplikasi dipasang
    // di luar Play Store. Lebih jujur menyatakannya daripada menampilkan tombol
    // yang pasti gagal ditekan.
    if (monthly == null && yearly == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: null,
            child: Text('purchase_unavailable'.tr(context: context)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (monthly != null)
            Expanded(
              child: FilledButton(
                onPressed: _purchasing ? null : () => _buy(monthly),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Column(
                  children: [
                    Text(monthly.price, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('per_month'.tr(context: context), style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
          if (monthly != null && yearly != null) const SizedBox(width: 10),
          if (yearly != null)
            Expanded(
              child: FilledButton.tonal(
                onPressed: _purchasing ? null : () => _buy(yearly),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Column(
                  children: [
                    Text(yearly.price, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('per_year'.tr(context: context), style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLimitRow(ThemeData theme, String label, String value, dynamic used) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            Text(used == null ? value : '$used / $value',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
