import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';

/// Halaman sambutan yang hanya muncul sekali, saat aplikasi pertama dibuka.
///
/// Tugasnya bukan mengajari cara memakai aplikasi - itu percuma sebelum orang
/// punya data sendiri. Tugasnya menjawab satu pertanyaan yang ada di kepala
/// pemilik toko saat baru memasang: "apa yang bisa aplikasi ini lakukan untuk
/// toko saya?". Karena itu tiap halaman menjual satu kemampuan, bukan
/// menjelaskan satu tombol.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  /// Dipanggil setelah penanda "sudah pernah dilihat" tersimpan.
  final VoidCallback onFinished;

  static const String prefsKey = 'onboarding_seen';

  /// Dibaca sekali saat aplikasi mulai. Default-nya `false` supaya pemasangan
  /// baru melihat sambutan, tapi kalau pembacaan preferensi gagal kita anggap
  /// SUDAH pernah dilihat - lebih baik melewatkan sambutan daripada
  /// menyodorkannya berulang kali kepada pengguna lama.
  static Future<bool> hasBeenSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefsKey) ?? false;
    } catch (_) {
      return true;
    }
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.chipIcons,
    required this.accent,
    required this.titleKey,
    required this.bodyKey,
  });

  final IconData icon;
  final List<IconData> chipIcons;
  final Color accent;
  final String titleKey;
  final String bodyKey;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_OnboardingPage> _pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.point_of_sale_rounded,
      chipIcons: [Icons.qr_code_scanner_rounded, Icons.receipt_long_rounded, Icons.wifi_off_rounded],
      accent: AppColors.brandDeep,
      titleKey: 'onboarding_pos_title',
      bodyKey: 'onboarding_pos_body',
    ),
    _OnboardingPage(
      icon: Icons.inventory_2_rounded,
      chipIcons: [Icons.blender_rounded, Icons.fact_check_rounded, Icons.trending_down_rounded],
      accent: AppColors.infoText,
      titleKey: 'onboarding_stock_title',
      bodyKey: 'onboarding_stock_body',
    ),
    _OnboardingPage(
      icon: Icons.groups_rounded,
      chipIcons: [Icons.fingerprint_rounded, Icons.event_available_rounded, Icons.emoji_events_rounded],
      accent: AppColors.warningText,
      titleKey: 'onboarding_team_title',
      bodyKey: 'onboarding_team_body',
    ),
    _OnboardingPage(
      icon: Icons.insights_rounded,
      chipIcons: [Icons.qr_code_2_rounded, Icons.event_seat_rounded, Icons.store_mall_directory_rounded],
      accent: AppColors.successText,
      titleKey: 'onboarding_grow_title',
      bodyKey: 'onboarding_grow_body',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(OnboardingScreen.prefsKey, true);
    } catch (_) {
      // Kalau penandanya gagal disimpan, sambutan akan muncul lagi nanti.
      // Menahan pengguna di layar ini jauh lebih buruk daripada itu.
    }
    if (mounted) widget.onFinished();
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Tombol lewati sengaja ada sejak halaman pertama. Sambutan yang
            // tidak bisa dilewati terasa seperti penghalang, bukan perkenalan.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'onboarding_skip'.tr(context: context),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) => _buildPage(theme, _pages[index], index),
              ),
            ),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(ThemeData theme, _OnboardingPage page, int index) {
    // Isinya digulir meski biasanya muat sekali layar. Ilustrasi 220px ditambah
    // judul dua baris dan isi empat baris masih aman di ponsel biasa, tapi di
    // layar pendek atau saat pengguna membesarkan ukuran font, kolom yang kaku
    // akan meluap - dan luapan itu tampil sebagai garis kuning-hitam tepat di
    // layar pertama yang dilihat orang setelah memasang aplikasi.
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIllustration(theme, page),
          const SizedBox(height: 40),
          Text(
            page.titleKey.tr(context: context),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          )
              .animate(key: ValueKey<String>('title_$index'))
              .fadeIn(delay: 120.ms, duration: 380.ms)
              .slideY(begin: 0.16, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 14),
          Text(
            page.bodyKey.tr(context: context),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 14.5,
              height: 1.55,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
              .animate(key: ValueKey<String>('body_$index'))
              .fadeIn(delay: 200.ms, duration: 380.ms)
              .slideY(begin: 0.16, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  /// Gambarnya dirakit dari bentuk dan ikon, bukan berkas aset.
  ///
  /// Ilustrasi bitmap harus ditulis ulang tiap kali palet berubah dan tidak
  /// pernah cocok di mode gelap tanpa versi kedua. Bentuk yang mengambil warna
  /// dari tema selalu ikut, dan tidak menambah ukuran APK sedikit pun.
  Widget _buildIllustration(ThemeData theme, _OnboardingPage page) {
    return SizedBox(
      height: 220,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.accent.withValues(alpha: 0.07),
            ),
          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutCubic),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.accent.withValues(alpha: 0.12),
            ),
          ).animate().fadeIn(delay: 60.ms, duration: 500.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutCubic),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: page.accent,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: page.accent.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(page.icon, size: 44, color: Colors.white),
          ).animate().fadeIn(duration: 460.ms).scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),

          // Tiga keping kecil mengelilingi ikon utama: isyarat bahwa satu
          // kemampuan ini terdiri dari beberapa hal, tanpa perlu menuliskannya.
          _chip(theme, page, page.chipIcons[0], const Alignment(-1.0, -0.55), 220.ms),
          _chip(theme, page, page.chipIcons[1], const Alignment(1.0, -0.1), 300.ms),
          _chip(theme, page, page.chipIcons[2], const Alignment(-0.72, 0.78), 380.ms),
        ],
      ),
    );
  }

  Widget _chip(ThemeData theme, _OnboardingPage page, IconData icon, Alignment align, Duration delay) {
    return Align(
      alignment: align,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: page.accent),
      ),
    )
        .animate()
        .fadeIn(delay: delay, duration: 340.ms)
        .scale(begin: const Offset(0.6, 0.6), curve: Curves.easeOutBack);
  }

  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(_pages.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: active ? 26 : 8,
                decoration: BoxDecoration(
                  color: active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _isLast
                      ? 'onboarding_start'.tr(context: context)
                      : 'onboarding_next'.tr(context: context),
                  key: ValueKey<bool>(_isLast),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
