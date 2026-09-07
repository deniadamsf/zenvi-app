import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../screens/subscription/plan_screen.dart';
import '../theme/app_colors.dart';

/// Keterangan kenapa sesuatu terkunci — dari body 403 server, atau dirakit
/// lokal oleh [PremiumGate] sebelum permintaan sempat dikirim.
class PremiumLock {
  const PremiumLock({
    this.isLimit = false,
    this.feature,
    this.limitKey,
    this.current,
    this.max,
    this.requiredPlan,
    this.message,
  });

  final bool isLimit;
  final String? feature;
  final String? limitKey;
  final int? current;
  final int? max;
  final String? requiredPlan;
  final String? message;
}

// ---------------------------------------------------------------------------
// Katalog manfaat
// ---------------------------------------------------------------------------

/// Apa yang dijanjikan sebuah fitur, untuk ditampilkan di tawaran upgrade.
///
/// Daftar ini sengaja ditulis per fitur, bukan satu paragraf umum: pengguna
/// menekan sakelar tertentu karena menginginkan hal tertentu, dan tawaran yang
/// menjawab keinginan itu jauh lebih meyakinkan daripada "tingkatkan paket
/// untuk membuka fitur ini".
class _FeatureOffer {
  const _FeatureOffer(this.icon, this.plan, this.benefitCount);

  final IconData icon;

  /// Paket termurah yang membuka fitur ini. Harus sejalan dengan
  /// `backend/config/plans.php` — server tetap penegak sebenarnya.
  final String plan;

  final int benefitCount;
}

const Map<String, _FeatureOffer> _offers = <String, _FeatureOffer>{
  'product_image': _FeatureOffer(Icons.photo_library_rounded, 'premium', 3),
  'attendance_selfie': _FeatureOffer(Icons.face_retouching_natural_rounded, 'premium', 3),
  'membership': _FeatureOffer(Icons.card_membership_rounded, 'premium', 3),
  'points': _FeatureOffer(Icons.stars_rounded, 'premium', 3),
  'qr_menu': _FeatureOffer(Icons.qr_code_2_rounded, 'premium', 3),
  'reservation': _FeatureOffer(Icons.event_seat_rounded, 'premium', 3),
  'kds': _FeatureOffer(Icons.soup_kitchen_rounded, 'premium', 3),
  'full_report': _FeatureOffer(Icons.insights_rounded, 'premium', 3),
  'export': _FeatureOffer(Icons.file_download_rounded, 'premium', 3),
  'multi_branch': _FeatureOffer(Icons.store_mall_directory_rounded, 'business', 3),
  'branch_stock': _FeatureOffer(Icons.inventory_2_rounded, 'business', 3),
  'consolidated_report': _FeatureOffer(Icons.account_tree_rounded, 'business', 3),
  'stock_transfer': _FeatureOffer(Icons.swap_horiz_rounded, 'business', 3),
};

/// Nama paket yang bisa dibaca manusia. Untuk paket tak dikenal, kode mentahnya
/// dipakai apa adanya daripada memaksakan tebakan.
String planLabel(BuildContext context, String? code) {
  switch (code) {
    case 'premium':
      return 'plan_premium'.tr(context: context);
    case 'business':
      return 'plan_business'.tr(context: context);
    case 'free':
      return 'plan_free'.tr(context: context);
    default:
      return code ?? 'plan_premium'.tr(context: context);
  }
}

// ---------------------------------------------------------------------------
// Penanda visual
// ---------------------------------------------------------------------------

/// Lencana emas untuk ditempel di judul menu atau baris pengaturan yang terkunci.
///
/// Emas dipakai HANYA di sini dan di tawaran upgrade — tidak muncul di tempat
/// lain dalam aplikasi. Karena itu lencananya langsung terbaca sebagai "ini
/// bagian berbayar" tanpa perlu keterangan tambahan.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.plan = 'premium', this.compact = false});

  final String plan;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final label = planLabel(context, plan).toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.premiumBright, AppColors.premium],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.premium.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: compact ? 10 : 12, color: Colors.white),
          SizedBox(width: compact ? 3 : 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 8.5 : 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sakelar yang tahu paket langganan.
///
/// Saat [locked], sakelarnya sengaja TIDAK bisa berpindah dan ketukan membuka
/// tawaran upgrade. Sebelum ini sakelar tetap bergeser, permintaan dikirim,
/// server menolak dengan 403, lalu keadaan dikembalikan diam-diam — dari sisi
/// pengguna sakelarnya terlihat macet tanpa penjelasan apa pun.
class PremiumSwitch extends StatelessWidget {
  const PremiumSwitch({
    super.key,
    required this.locked,
    required this.value,
    required this.onChanged,
    this.feature,
    this.requiredPlan,
  });

  final bool locked;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? feature;
  final String? requiredPlan;

  @override
  Widget build(BuildContext context) {
    if (!locked) {
      return Switch(
        value: value,
        onChanged: onChanged,
      );
    }

    final plan = requiredPlan ?? _offers[feature]?.plan ?? 'premium';

    return Semantics(
      button: true,
      label: 'upsell_unlock_with'.tr(
        context: context,
        namedArgs: {'plan': planLabel(context, plan)},
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => showPremiumUpsellSheet(
          context,
          PremiumLock(feature: feature, requiredPlan: plan),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.premium.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.premium.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bentuknya tetap menyerupai sakelar mati supaya jelas ini kontrol
              // yang sama, hanya belum bisa dipakai.
              Container(
                width: 34,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.premium.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.premiumBright, AppColors.premium],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  planLabel(context, plan).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.premiumText,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Membungkus sesuatu yang hanya tersedia di paket berbayar.
///
/// Sengaja TIDAK menyembunyikan isinya: menu yang hilang tidak menjual apa pun,
/// sementara menu bergembok memberi tahu pengguna bahwa fiturnya ada dan bisa
/// dibuka. Ketukan mengarah ke tawaran upgrade, bukan ke pesan error.
class PremiumGate extends StatelessWidget {
  const PremiumGate({
    super.key,
    required this.locked,
    required this.child,
    this.feature,
    this.requiredPlan,
  });

  /// Kalau false, [child] ditampilkan apa adanya tanpa biaya tambahan.
  final bool locked;
  final Widget child;
  final String? feature;
  final String? requiredPlan;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    final plan = requiredPlan ?? _offers[feature]?.plan ?? 'premium';

    return Stack(
      children: [
        // Isinya tetap terlihat tapi diredupkan, dan tidak bisa disentuh.
        Opacity(
          opacity: 0.45,
          child: IgnorePointer(child: child),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showPremiumUpsellSheet(
                context,
                PremiumLock(feature: feature, requiredPlan: plan),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: PremiumBadge(plan: plan),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tawaran upgrade
// ---------------------------------------------------------------------------

bool _upsellVisible = false;

/// Menampilkan tawaran upgrade. Dipanggil dari [PremiumGate], [PremiumSwitch],
/// maupun dari ApiClient saat server membalas 403 bertipe.
void showPremiumUpsellSheet(BuildContext context, PremiumLock lock) {
  // Satu permintaan pengguna bisa memicu beberapa panggilan API yang semuanya
  // terkunci; tanpa penjaga ini sheet-nya bertumpuk.
  if (_upsellVisible) return;
  _upsellVisible = true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _UpsellSheet(lock: lock),
  ).whenComplete(() => _upsellVisible = false);
}

class _UpsellSheet extends StatelessWidget {
  const _UpsellSheet({required this.lock});

  final PremiumLock lock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final offer = lock.feature == null ? null : _offers[lock.feature];
    final plan = lock.requiredPlan ?? offer?.plan ?? 'premium';
    final planName = planLabel(context, plan);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(context, theme, plan, planName, offer),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 22, 24, media.viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'upsell_benefits_title'.tr(context: context),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._benefits(context).map(
                    (text) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 1),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.premiumBright, AppColors.premium],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              text,
                              style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.premium.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.premium.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.premiumText),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'upsell_all_features'.tr(
                              context: context,
                              namedArgs: {'plan': planName},
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.brightness == Brightness.dark
                                  ? AppColors.premiumGlow
                                  : AppColors.premiumText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute(builder: (_) => const PlanScreen()),
                        );
                      },
                      icon: const Icon(Icons.workspace_premium_rounded),
                      label: Text('upsell_cta'.tr(context: context)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('later'.tr(context: context)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Center(
                    child: Text(
                      'upsell_billing_note'.tr(context: context),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
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

  Widget _buildHero(
    BuildContext context,
    ThemeData theme,
    String plan,
    String planName,
    _FeatureOffer? offer,
  ) {
    final title = lock.isLimit
        ? 'plan_limit_title'.tr(context: context)
        : (lock.feature != null && _offers.containsKey(lock.feature)
            ? 'feat_${lock.feature}_title'.tr(context: context)
            : 'feature_locked_title'.tr(context: context));

    final subtitle = lock.isLimit && lock.max != null
        ? 'plan_limit_desc'.tr(context: context, namedArgs: {'max': '${lock.max}'})
        : (lock.message ?? 'feature_locked_desc'.tr(context: context));

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.premiumGradient,
        ),
      ),
      child: Stack(
        children: [
          // Cahaya emas samar di sudut kanan atas — satu-satunya ornamen di
          // sheet ini, sengaja tidak diulang di tempat lain.
          Positioned(
            right: -70,
            top: -70,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.premiumBright.withValues(alpha: 0.28),
                    AppColors.premiumBright.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.premiumBright.withValues(alpha: 0.45)),
                    ),
                    child: Icon(
                      lock.isLimit
                          ? Icons.trending_up_rounded
                          : (offer?.icon ?? Icons.workspace_premium_rounded),
                      color: AppColors.premiumGlow,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'upsell_eyebrow'.tr(context: context).toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.premiumGlow,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            PremiumBadge(plan: plan, compact: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Manfaat yang ditampilkan. Untuk fitur yang dikenal dipakai salinan
  /// spesifik fitur itu; kalau tidak, dipakai janji umum paketnya supaya sheet
  /// tetap menjual sesuatu dan bukan sekadar memberi tahu ada yang terkunci.
  List<String> _benefits(BuildContext context) {
    final feature = lock.feature;
    final offer = feature == null ? null : _offers[feature];
    if (offer != null) {
      return List<String>.generate(
        offer.benefitCount,
        (i) => 'feat_${feature}_b${i + 1}'.tr(context: context),
      );
    }

    final plan = lock.requiredPlan ?? 'premium';
    final keys = plan == 'business'
        ? const ['plan_business_b1', 'plan_business_b2', 'plan_business_b3']
        : const ['plan_premium_b1', 'plan_premium_b2', 'plan_premium_b3'];
    return keys.map((k) => k.tr(context: context)).toList();
  }
}
