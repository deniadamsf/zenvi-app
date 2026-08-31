import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/zenvi_header.dart';

/// Halaman "Paket Langganan".
///
/// Katalog paket diambil dari server (GET /api/plans) supaya daftar fiturnya
/// tidak pernah menyimpang dari yang benar-benar ditegakkan backend.
///
/// Harga TIDAK ditampilkan dari sini: pembayaran memakai Google Play Billing,
/// jadi harga datang dari Play Console. Sampai bagian itu terpasang, tombolnya
/// menunjukkan keadaan "segera hadir" - lebih jujur daripada memampangkan angka
/// yang belum tentu sama dengan yang ditagih Google.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _isLoading = true;
  String? _error;
  String _currentPlan = 'free';
  List<dynamic> _plans = [];
  Map<String, dynamic> _usage = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get('/plans');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] ?? {};
        if (!mounted) return;
        setState(() {
          _currentPlan = data['current_plan']?.toString() ?? 'free';
          _plans = data['plans'] as List<dynamic>? ?? [];
          _usage = Map<String, dynamic>.from(data['usage'] ?? {});
          _isLoading = false;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'plan_load_failed'.tr(context: context);
        _isLoading = false;
      });
    }
  }

  String _limitText(BuildContext context, dynamic value) {
    if (value == null) return 'unlimited'.tr(context: context);
    return value.toString();
  }

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
            ),
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
                              ..._plans.map((plan) => _buildPlanCard(theme, plan)),
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

  Widget _buildError(ThemeData theme) {
    return Center(
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
  }

  /// Toko yang sudah terdaftar sebelum langganan diberlakukan mendapat paket
  /// berbayar selamanya. Ditampilkan sebagai penghargaan, bukan sekadar status.
  Widget _buildFoundingBanner(ThemeData theme) {
    return Container(
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
                Text(
                  'founding_member_title'.tr(context: context),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'founding_member_desc'.tr(context: context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(ThemeData theme, dynamic plan) {
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
          color: isCurrent
              ? theme.colorScheme.primary
              : theme.dividerColor.withValues(alpha: 0.3),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan['name']?.toString() ?? code,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'current_plan_badge'.tr(context: context),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                : 'history_days'.tr(context: context, namedArgs: {'days': '${limits['history_days']}'}),
            null,
          ),
          if (features.isNotEmpty) ...[
            const Divider(height: 28),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f['label']?.toString() ?? '', style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!isCurrent && code != 'free') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              // Dinonaktifkan sampai Google Play Billing terpasang. Menampilkan
              // tombol beli yang tidak berfungsi lebih merugikan daripada
              // menyatakan terus terang bahwa pembeliannya belum dibuka.
              child: FilledButton.tonal(
                onPressed: null,
                child: Text('purchase_coming_soon'.tr(context: context)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLimitRow(ThemeData theme, String label, String value, dynamic used) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            used == null ? value : '$used / $value',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
