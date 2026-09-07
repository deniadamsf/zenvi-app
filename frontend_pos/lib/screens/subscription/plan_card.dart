import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';

/// Satu kartu paket di layar langganan.
///
/// Sengaja dipisah dari [PlanScreen] dan hanya menerima data biasa - tanpa
/// provider, tanpa panggilan jaringan. Kartu inilah yang paling sering diubah
/// tampilannya, dan begitu ia bisa dibangun dari data karangan, hasilnya bisa
/// dilihat lebih dulu tanpa perlu akun berbayar sungguhan.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.name,
    required this.code,
    required this.isCurrent,
    required this.isRecommended,
    required this.limits,
    required this.usage,
    required this.features,
    required this.freeIncludes,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.savingPercent,
    required this.yearlySelected,
    required this.onBillingChanged,
    required this.onBuy,
    required this.purchasing,
    required this.isFoundingMember,
  });

  final String name;
  final String code;
  final bool isCurrent;
  final bool isRecommended;
  final Map<String, dynamic> limits;
  final Map<String, dynamic> usage;

  /// Label fitur berbayar, apa adanya dari server.
  final List<String> features;

  /// Yang selalu didapat semua paket. Dipakai untuk mengisi kartu Gratis, yang
  /// daftar fitur berbayarnya memang kosong - tanpa ini kartunya nyaris melompong
  /// dan terbaca seolah paket Gratis tidak memberi apa-apa, padahal isinya
  /// justru seluruh inti aplikasi.
  final List<String> freeIncludes;

  final String? monthlyPrice;
  final String? yearlyPrice;

  /// Persentase hemat kalau berlangganan tahunan. Null kalau tidak bisa dihitung.
  final int? savingPercent;

  final bool yearlySelected;
  final ValueChanged<bool> onBillingChanged;
  final VoidCallback? onBuy;
  final bool purchasing;
  final bool isFoundingMember;

  bool get _isFree => code == 'free';
  bool get _hasPrice => monthlyPrice != null || yearlyPrice != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _isFree ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: isCurrent ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme, accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasPrice && !_isFree) ...[
                    _buildBillingToggle(theme),
                    const SizedBox(height: 18),
                  ],
                  _buildLimitGrid(theme),
                  const SizedBox(height: 18),
                  _buildIncludes(theme, accent),
                  const SizedBox(height: 18),
                  _buildCta(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Kepala kartu --------------------------------------------------------

  Widget _buildHeader(ThemeData theme, Color accent) {
    final isPaid = !_isFree;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: isPaid
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.premiumGradient,
              )
            : null,
        color: isPaid ? null : theme.colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isPaid ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isCurrent) _badge(theme, 'current_plan_badge'.tr(), isPaid)
              else if (isRecommended) _badge(theme, 'plan_popular_badge'.tr(), isPaid),
            ],
          ),
          const SizedBox(height: 10),
          _buildPriceLine(theme, isPaid),
        ],
      ),
    );
  }

  Widget _badge(ThemeData theme, String label, bool onGradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: onGradient ? Colors.white.withValues(alpha: 0.18) : theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
        border: onGradient ? Border.all(color: AppColors.premiumBright.withValues(alpha: 0.5)) : null,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: onGradient ? AppColors.premiumGlow : theme.colorScheme.onPrimary,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPriceLine(ThemeData theme, bool isPaid) {
    final onHeader = isPaid ? Colors.white : theme.colorScheme.onSurface;
    final muted = isPaid ? Colors.white.withValues(alpha: 0.75) : theme.colorScheme.onSurfaceVariant;

    if (_isFree) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('Rp 0',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: onHeader, letterSpacing: -1)),
          const SizedBox(width: 8),
          Text('plan_free_forever'.tr(),
              style: TextStyle(fontSize: 13, color: muted, fontWeight: FontWeight.w600)),
        ],
      );
    }

    final price = yearlySelected ? yearlyPrice : monthlyPrice;
    if (price == null) {
      return Text('purchase_unavailable'.tr(),
          style: TextStyle(fontSize: 14, color: muted, fontWeight: FontWeight.w600));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Angkanya diberi kunci per pilihan penagihan supaya berganti dengan
        // pergantian halus saat pengguna menekan bulanan/tahunan - perubahan
        // yang mendadak membuat orang ragu apakah tombolnya benar-benar bekerja.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: Text(
            price,
            key: ValueKey<String>('$code-$price'),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: onHeader, letterSpacing: -1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          yearlySelected ? 'per_year'.tr() : 'per_month'.tr(),
          style: TextStyle(fontSize: 13, color: muted, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // --- Pilihan penagihan ---------------------------------------------------

  Widget _buildBillingToggle(ThemeData theme) {
    if (monthlyPrice == null || yearlyPrice == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _billingOption(theme, 'plan_billing_monthly', false)),
          Expanded(child: _billingOption(theme, 'plan_billing_yearly', true)),
        ],
      ),
    );
  }

  Widget _billingOption(ThemeData theme, String labelKey, bool yearly) {
    final selected = yearlySelected == yearly;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => onBillingChanged(yearly),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                labelKey.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (yearly && savingPercent != null && savingPercent! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successFill.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'plan_save_badge'.tr(namedArgs: {'percent': '$savingPercent'}),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.successText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Batas paket ---------------------------------------------------------

  /// Batas ditampilkan sebagai empat petak, bukan empat baris teks.
  ///
  /// Baris teks memaksa mata membaca; petak dengan angka besar bisa dibandingkan
  /// sekilas antar paket saat kartunya digeser - dan itulah satu-satunya
  /// pekerjaan layar ini.
  Widget _buildLimitGrid(ThemeData theme) {
    final tiles = <Widget>[
      _limitTile(theme, Icons.people_alt_rounded, 'limit_employees'.tr(),
          _limitText(limits['employees']), usage['employees']),
      _limitTile(theme, Icons.storefront_rounded, 'limit_branches'.tr(),
          _limitText(limits['branches']), usage['branches']),
      _limitTile(theme, Icons.inventory_2_rounded, 'limit_products'.tr(),
          _limitText(limits['products']), usage['products']),
      _limitTile(
        theme,
        Icons.history_rounded,
        'limit_history'.tr(),
        limits['history_days'] == null
            ? 'history_full'.tr()
            : 'history_days'.tr(namedArgs: {'days': '${limits['history_days']}'}),
        null,
      ),
    ];

    return Column(
      children: [
        Row(children: [Expanded(child: tiles[0]), const SizedBox(width: 10), Expanded(child: tiles[1])]),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: tiles[2]), const SizedBox(width: 10), Expanded(child: tiles[3])]),
      ],
    );
  }

  String _limitText(dynamic value) =>
      value == null ? 'unlimited'.tr() : value.toString();

  Widget _limitTile(ThemeData theme, IconData icon, String label, String value, dynamic used) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            used == null ? value : '$used / $value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // --- Isi paket -----------------------------------------------------------

  Widget _buildIncludes(ThemeData theme, Color accent) {
    final items = _isFree ? freeIncludes : features;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'plan_includes_title'.tr().toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        if (!_isFree)
          _includeRow(theme, accent, 'plan_all_free_included'.tr(), bold: true),
        ...items.asMap().entries.map(
              (e) => _includeRow(theme, accent, e.value)
                  .animate()
                  .fadeIn(delay: (40 * (e.key.clamp(0, 8))).ms, duration: 260.ms)
                  .slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
            ),
      ],
    );
  }

  Widget _includeRow(ThemeData theme, Color accent, String label, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Icon(Icons.check_circle_rounded, size: 16, color: accent),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tombol --------------------------------------------------------------

  Widget _buildCta(ThemeData theme) {
    if (isCurrent) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, size: 17, color: theme.colorScheme.primary),
            const SizedBox(width: 7),
            Text(
              'plan_you_are_here'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    // Paket permanen: menawarkan pembelian hanya akan membingungkan.
    if (isFoundingMember) return const SizedBox.shrink();
    if (_isFree) return const SizedBox.shrink();

    if (!_hasPrice) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.tonal(
          onPressed: null,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
          child: Text('purchase_unavailable'.tr()),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: purchasing ? null : onBuy,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        icon: purchasing
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.workspace_premium_rounded, size: 19),
        label: Text('plan_upgrade_to'.tr(namedArgs: {'plan': name})),
      ),
    );
  }
}
