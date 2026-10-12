import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layanan In-App Review Google Play.
///
/// Mengatur dialog ulasan resmi Google Play yang muncul secara khusus setelah
/// pengguna mencoba/mengaktifkan Free Trial atau secara manual dari menu Pengaturan.
class ReviewService {
  ReviewService._();
  static final InAppReview _iapReview = InAppReview.instance;

  static const String _keyTrialReviewPrompted = 'in_app_review_trial_prompted';

  /// Meminta ulasan secara otomatis HANYA setelah pengguna mencoba Free Trial.
  /// Memastikan dialog hanya muncul 1 kali agar tidak mengganggu pengguna.
  static Future<void> requestReviewAfterTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyPrompted = prefs.getBool(_keyTrialReviewPrompted) ?? false;
      if (alreadyPrompted) return;

      if (await _iapReview.isAvailable()) {
        await prefs.setBool(_keyTrialReviewPrompted, true);
        await _iapReview.requestReview();
        debugPrint('ReviewService: In-App Review dialog requested after free trial.');
      }
    } catch (e) {
      debugPrint('ReviewService: Gagal meminta in-app review - $e');
    }
  }

  /// Membuka halaman Zenvi langsung di Google Play Store untuk ulasan manual.
  /// Dipakai saat pengguna menekan tombol "Beri Ulasan" di menu Pengaturan.
  static Future<void> openStoreListing() async {
    try {
      await _iapReview.openStoreListing();
    } catch (e) {
      debugPrint('ReviewService: Gagal membuka Play Store - $e');
    }
  }
}
