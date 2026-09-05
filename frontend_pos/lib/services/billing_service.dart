import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'api_client.dart';

/// Pembelian langganan lewat Google Play Billing.
///
/// Aturan yang tidak boleh dilanggar: **aplikasi tidak pernah menentukan paket**.
/// Yang dikirim ke server hanya `purchaseToken` dari Google; backend memverifikasi
/// token itu langsung ke Google Play Developer API, dan hanya setelah Google
/// mengonfirmasi barulah paket toko berubah. Klien yang dimodifikasi tidak bisa
/// memalsukan langganan karena token palsu akan ditolak Google.
///
/// Harga TIDAK ada di kode. Semua angka datang dari Play Console lewat
/// [ProductDetails.price], sudah terformat sesuai mata uang perangkat. Menyimpan
/// harga di aplikasi akan membuat yang tampil berbeda dari yang ditagih Google.
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  static const String premiumMonthly = 'zenvi_premium_monthly';
  static const String premiumYearly = 'zenvi_premium_yearly';
  static const String businessMonthly = 'zenvi_business_monthly';
  static const String businessYearly = 'zenvi_business_yearly';

  static const Set<String> productIds = {
    premiumMonthly,
    premiumYearly,
    businessMonthly,
    businessYearly,
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _available = false;
  bool get isAvailable => _available;

  /// Dipanggil saat halaman Paket dibuka.
  ///
  /// Aman dipanggil berulang: langganan stream lama dibatalkan lebih dulu supaya
  /// satu pembelian tidak diproses dua kali.
  Future<void> init({
    void Function(PurchaseDetails purchase)? onPending,
    void Function(PurchaseDetails purchase, bool verified)? onDone,
    void Function(String message)? onError,
  }) async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    await _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      (purchases) => _handle(purchases, onPending, onDone, onError),
      onError: (e) => onError?.call(e.toString()),
    );

    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      debugPrint('BillingService: queryProductDetails gagal - ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      // Normal sebelum produk dibuat di Play Console, atau saat aplikasi
      // dipasang di luar Play Store (sideload).
      debugPrint('BillingService: produk belum tersedia - ${response.notFoundIDs}');
    }
    _products = response.productDetails;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  ProductDetails? productFor(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Langganan dibeli dengan buyNonConsumable - Play Billing memperlakukan
  /// langganan sebagai produk non-konsumsi yang diperpanjang otomatis.
  Future<bool> buy(ProductDetails product) async {
    if (!_available) return false;
    return _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  /// Mengembalikan langganan aktif setelah pasang ulang atau ganti perangkat.
  /// Hasilnya masuk ke purchaseStream dan ikut diverifikasi ke server.
  Future<void> restore() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  Future<void> _handle(
    List<PurchaseDetails> purchases,
    void Function(PurchaseDetails)? onPending,
    void Function(PurchaseDetails, bool)? onDone,
    void Function(String)? onError,
  ) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          onPending?.call(purchase);
          break;

        case PurchaseStatus.error:
          onError?.call(purchase.error?.message ?? 'Pembelian gagal');
          // Tetap diselesaikan; kalau tidak, transaksi gagal akan terus muncul
          // di stream setiap aplikasi dibuka.
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verified = await _verifyOnServer(purchase);
          // completePurchase HANYA setelah server mengonfirmasi. Kalau
          // diselesaikan lebih dulu lalu verifikasi gagal, Google menganggap
          // pembelian sudah ditangani dan tokennya tidak dikirim ulang -
          // pelanggan sudah membayar tapi paketnya tidak pernah aktif.
          if (verified && purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          onDone?.call(purchase, verified);
          break;
      }
    }
  }

  Future<bool> _verifyOnServer(PurchaseDetails purchase) async {
    try {
      final response = await ApiClient.post('/billing/play/verify', body: {
        'product_id': purchase.productID,
        // Di Android inilah purchaseToken dari Google Play.
        'purchase_token': purchase.verificationData.serverVerificationData,
      });
      if (response.statusCode == 200) return true;
      debugPrint('BillingService: verifikasi ditolak server - '
          '${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      debugPrint('BillingService: verifikasi gagal - $e');
      return false;
    }
  }

  /// Dipakai halaman Paket untuk mencocokkan kode paket + periode ke produk Play.
  static String? productIdFor(String planCode, {required bool yearly}) {
    if (planCode == 'premium') return yearly ? premiumYearly : premiumMonthly;
    if (planCode == 'business') return yearly ? businessYearly : businessMonthly;
    return null;
  }

  /// Membaca pesan kesalahan bertipe dari server, kalau ada.
  static String? messageFrom(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return null;
  }
}
