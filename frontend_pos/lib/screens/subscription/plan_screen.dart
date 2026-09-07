import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/billing_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/zenvi_header.dart';
import 'plan_card.dart';

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

  /// Kartu paket digeser ke samping, bukan ditumpuk ke bawah.
  ///
  /// Ditumpuk, membandingkan dua paket berarti menggulir bolak-balik sambil
  /// mengingat angka yang sudah lewat layar. Digeser, satu paket mengisi satu
  /// layar penuh dan tetangganya mengintip di tepi - itu yang memberi tahu
  /// bahwa masih ada paket lain tanpa perlu tulisan apa pun.
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  Map<String, dynamic> _usage = {};

  /// Bulanan atau tahunan. Satu pilihan untuk seluruh layar, bukan per kartu -
  /// orang membandingkan harga antar paket pada dasar yang sama.
  bool _yearly = false;

  final _billing = BillingService.instance;

  @override
  void initState() {
    super.initState();
    _load();
    _initBilling();
  }

  @override
  void dispose() {
    _pageController.dispose();
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

        // Buka di paket yang sedang dipakai supaya pengguna melihat posisinya
        // sendiri dulu, lalu menggeser untuk melihat yang di atasnya.
        final currentIndex =
            _plans.indexWhere((p) => p['code']?.toString() == _currentPlan);
        _currentPage = currentIndex < 0 ? 0 : currentIndex;
        _usage = Map<String, dynamic>.from(data['usage'] ?? {});
        _isLoading = false;
      });

      // PageController baru terpasang setelah PageView selesai dibangun, jadi
      // lompatannya menunggu frame berikutnya. Tanpa ini kartu terbuka di
      // halaman pertama sementara titik penunjuknya menyorot halaman lain.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(_currentPage);
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
                      : Column(
                          children: [
                            if (auth.isFoundingMember)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: _buildFoundingBanner(theme),
                              )
                            else
                              _buildStatusStrip(theme, auth),
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _plans.length,
                                onPageChanged: (i) => setState(() => _currentPage = i),
                                itemBuilder: (context, index) =>
                                    _buildPlanCard(theme, _plans[index], auth),
                              ),
                            ),
                            _buildPageDots(theme),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pita status di paling atas: paket apa yang sedang berlaku.
  ///
  /// Sebelumnya layar ini langsung menampilkan kartu tanpa menyebut posisi
  /// pengguna sama sekali, jadi pengguna paket gratis harus menggeser dan
  /// mencari lencana kecil untuk tahu di mana dirinya berada.
  Widget _buildStatusStrip(ThemeData theme, AuthProvider auth) {
    final onFree = _currentPlan == 'free';
    final planName = _plans
            .cast<Map<String, dynamic>?>()
            .firstWhere((p) => p?['code']?.toString() == _currentPlan, orElse: () => null)?['name']
            ?.toString() ??
        _currentPlan;

    final expiry = auth.planExpiresAt;

    return Container(
      margin: const EdgeInsets.fromLTRB(22, 10, 22, 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: onFree
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)
            : AppColors.premium.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onFree
              ? theme.colorScheme.outline
              : AppColors.premium.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: onFree
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12)
                  : AppColors.premium.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              onFree ? Icons.lock_open_rounded : Icons.workspace_premium_rounded,
              size: 18,
              color: onFree ? theme.colorScheme.onSurfaceVariant : AppColors.premiumText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'plan_status_label'.tr(context: context).toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  planName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: onFree ? theme.colorScheme.onSurface : AppColors.premiumText,
                  ),
                ),
                if (!onFree && expiry != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    'plan_expires_on'.tr(context: context, namedArgs: {
                      'date': DateFormat('d MMM yyyy', context.locale.languageCode).format(expiry),
                    }),
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (onFree)
            Flexible(
              child: Text(
                'plan_free_hint'.tr(context: context),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.3,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic);
  }

  /// Titik penunjuk halaman. Bisa diketuk supaya berpindah paket tidak harus
  /// selalu lewat gesekan.
  Widget _buildPageDots(ThemeData theme) {
    if (_plans.length < 2) return const SizedBox(height: 16);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(_plans.length, (i) {
          final active = i == _currentPage;
          return Semantics(
            button: true,
            selected: active,
            label: _plans[i]['name']?.toString() ?? '',
            child: GestureDetector(
              onTap: () => _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: active ? 24 : 8,
                decoration: BoxDecoration(
                  color: active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          );
        }),
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
    final monthly = _billing.productFor(BillingService.productIdFor(code, yearly: false) ?? '');
    final yearly = _billing.productFor(BillingService.productIdFor(code, yearly: true) ?? '');

    return PlanCard(
      name: plan['name']?.toString() ?? code,
      code: code,
      isCurrent: code == _currentPlan,
      // Paket tengah adalah yang paling masuk akal untuk kebanyakan toko;
      // menandainya menghemat satu keputusan bagi orang yang belum yakin.
      isRecommended: code == 'premium' && _currentPlan == 'free',
      limits: Map<String, dynamic>.from(plan['limits'] ?? {}),
      usage: _usage,
      features: (plan['features'] as List<dynamic>? ?? [])
          .map((f) => f['label']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
      freeIncludes: _freeIncludes(context),
      monthlyPrice: monthly?.price,
      yearlyPrice: yearly?.price,
      savingPercent: _savingPercent(monthly, yearly),
      yearlySelected: _yearly,
      onBillingChanged: (v) => setState(() => _yearly = v),
      onBuy: () {
        final product = _yearly ? yearly : monthly;
        if (product != null) _buy(product);
      },
      purchasing: _purchasing,
      isFoundingMember: auth.isFoundingMember,
    );
  }

  /// Apa yang didapat SEMUA paket. Daftarnya ada di sisi aplikasi karena server
  /// hanya mengirim fitur yang bisa dikunci - yang gratis justru tidak pernah
  /// disebut di sana, dan tanpa daftar ini kartu Gratis nyaris kosong.
  static List<String> _freeIncludes(BuildContext context) => <String>[
        'plan_free_inc_pos'.tr(context: context),
        'plan_free_inc_receipt'.tr(context: context),
        'plan_free_inc_offline'.tr(context: context),
        'plan_free_inc_shift'.tr(context: context),
        'plan_free_inc_stock'.tr(context: context),
        'plan_free_inc_attendance'.tr(context: context),
        'plan_free_inc_team'.tr(context: context),
        'plan_free_inc_expense'.tr(context: context),
      ];

  /// Berapa persen lebih murah berlangganan tahunan. Null kalau salah satu
  /// harga tidak tersedia atau angkanya tidak masuk akal - lebih baik tidak
  /// menampilkan klaim hemat daripada menampilkan yang salah.
  int? _savingPercent(ProductDetails? monthly, ProductDetails? yearly) {
    if (monthly == null || yearly == null) return null;
    final perYearIfMonthly = monthly.rawPrice * 12;
    if (perYearIfMonthly <= 0 || yearly.rawPrice <= 0) return null;
    final saving = (1 - yearly.rawPrice / perYearIfMonthly) * 100;
    if (saving < 1 || saving > 90) return null;
    return saving.round();
  }
}
