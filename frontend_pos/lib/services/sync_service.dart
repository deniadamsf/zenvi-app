import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/product_model.dart';
import '../config/api_config.dart';
import 'product_image_cache.dart';

class SyncService {
  static const String _apiUrl = ApiConfig.baseUrl;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static bool _isSyncing = false;

  // Track retries in memory
  static final Map<int, int> _retryCount = {};

  // --- Sinkronisasi Otomatis ---

  /// Mulai memantau perubahan sinyal internet
  void startMonitoringConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none)) {
        debugPrint('🌐 Sinyal kembali! Memulai sinkronisasi background...');
        pushOfflineOrders(); // Dorong order offline
        pullProducts();      // Perbarui menu
      }
    });
  }

  // --- Operasi Tarik Data (Pull) ---

  Future<bool> pullProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$_apiUrl/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        final products = data.map((json) => ProductModel.fromJson(json)).toList();
        
        // Simpan ke SQLite
        await _dbHelper.syncLocalProducts(products);
        debugPrint('✅ Berhasil menarik ${products.length} produk ke database lokal.');

        // Unduh foto produk ke penyimpanan lokal supaya POS tetap menampilkan
        // gambar saat offline. Sengaja tanpa await: membuka POS tidak boleh
        // menunggu seluruh foto selesai diunduh.
        unawaited(ProductImageCache.instance.syncProducts(products));
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Gagal pull produk: $e');
      return false;
    }
  }

  // --- Operasi Dorong Data (Push Bulk) ---

  Future<void> pushOfflineOrders() async {
    if (_isSyncing) {
      debugPrint('⚡ Sinkronisasi sedang berjalan, skip.');
      return;
    }
    
    try {
      _isSyncing = true;
      final unsyncedOrders = await _dbHelper.getUnsyncedOrders();
      if (unsyncedOrders.isEmpty) {
        debugPrint('⚡ Tidak ada order offline yang perlu disinkronkan.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      for (var order in unsyncedOrders) {
        final localId = order['local_id'];
        
        final retries = _retryCount[localId] ?? 0;
        if (retries >= 3) {
          debugPrint('⏩ Order $localId telah gagal $retries kali, skip.');
          continue;
        }

        final payload = {
          'orders': [{
            'client_order_id': order['client_order_id'],
            'shift_id': order['shift_id'],
            'total_amount': order['total_amount'],
            'payment_method': order['payment_method'] ?? 'cash',
            'cash_received': order['cash_received'],
            'cash_change': order['cash_change'],
            'serviced_by_user_id': order['serviced_by_user_id'],
            'member_id': order['member_id'],
            'member_name': order['member_name'],
            'member_phone': order['member_phone'],
            'member_discount_amount': order['member_discount_amount'],
            'points_redeemed': order['points_redeemed'],
            'point_redeem_amount': order['point_redeem_amount'],
            'items': order['items'],
          }],
        };

        try {
          final response = await http.post(
            Uri.parse('$_apiUrl/orders/sync'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          );

          if (response.statusCode == 201) {
            debugPrint('✅ Sukses sinkronisasi order $localId ke Server!');
            await _dbHelper.deleteSyncedOrder(localId);
            _retryCount.remove(localId);
          } else {
            debugPrint('❌ Gagal sinkronisasi order $localId: ${response.body}');
            _retryCount[localId] = retries + 1;
          }
        } catch (e) {
          debugPrint('❌ Terjadi kesalahan saat push order $localId: $e');
          _retryCount[localId] = retries + 1;
        }
      }
    } catch (e) {
      debugPrint('❌ Terjadi kesalahan saat memproses antrean order: $e');
    } finally {
      _isSyncing = false;
    }
  }
}

