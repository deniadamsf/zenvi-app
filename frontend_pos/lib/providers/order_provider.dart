import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../database/database_helper.dart';
import '../config/api_config.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  List<Map<String, dynamic>> _offlineOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  List<Map<String, dynamic>> get offlineOrders => _offlineOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const String _apiUrl = ApiConfig.baseUrl;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Fetch orders - ALWAYS shows offline orders, tries API when online
  Future<void> loadAllOrders({String? date}) async {
    _setLoading(true);
    _errorMessage = null;
    
    // 1. SELALU ambil offline orders dari SQLite dulu (instant)
    await fetchOfflineOrders();

    // 2. Coba fetch dari API (jangan crash kalau gagal)
    final dateStr = date ?? DateTime.now().toIso8601String().split('T')[0];
    try {
      await fetchOrders(date: dateStr).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏱️ API timeout, menampilkan data offline saja');
          return false;
        },
      );
    } catch (e) {
      debugPrint('❌ Gagal fetch orders dari API: $e');
      _errorMessage = 'Tidak bisa terhubung ke server. Menampilkan data offline.';
    }

    _setLoading(false);
  }

  /// Fetch orders from API, with optional filters
  Future<bool> fetchOrders({String? date, int? branchId, int? userId}) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final queryParams = <String, String>{};
      if (date != null) queryParams['date'] = date;
      if (branchId != null) queryParams['branch_id'] = branchId.toString();
      if (userId != null) queryParams['user_id'] = userId.toString();

      final uri = Uri.parse('$_apiUrl/orders').replace(queryParameters: queryParams);
      
      debugPrint('📡 Fetching orders from: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      debugPrint('📡 Orders response status: ${response.statusCode}');
      debugPrint('📡 Orders response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        _orders = data.map((item) => OrderModel.fromMap(item)).toList();
        debugPrint('✅ Loaded ${_orders.length} orders from API');
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ API returned status: ${response.statusCode} body: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error fetch orders: $e');
    }
    return false;
  }

  /// Fetch unsynced offline orders
  Future<void> fetchOfflineOrders() async {
    _offlineOrders = await _dbHelper.getUnsyncedOrders();
    debugPrint('📦 Loaded ${_offlineOrders.length} offline orders from SQLite');
    notifyListeners();
  }

  /// Void an order on the backend
  Future<bool> voidOrder(int orderId) async {
    final token = await _getToken();
    if (token == null) return false;

    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/orders/$orderId/void'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local status in the list to voided
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          final old = _orders[index];
          _orders[index] = OrderModel(
            id: old.id,
            companyId: old.companyId,
            userId: old.userId,
            shiftId: old.shiftId,
            totalAmount: old.totalAmount,
            status: 'voided',
            createdAt: old.createdAt,
            user: old.user,
            shift: old.shift,
            items: old.items,
          );
        }
        _setLoading(false);
        return true;
      } else {
        debugPrint('Failed to void order: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error voiding order: $e');
    }

    _setLoading(false);
    return false;
  }

  /// Void an offline order by deleting it locally
  Future<bool> voidOfflineOrder(int localOrderId) async {
    try {
      await _dbHelper.deleteSyncedOrder(localOrderId);
      await fetchOfflineOrders();
      return true;
    } catch (e) {
      debugPrint('Error voiding offline order: $e');
      return false;
    }
  }
}
