import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../database/database_helper.dart';
import '../models/member_promo_model.dart';

class MemberPromoProvider extends ChangeNotifier {
  List<MemberPromoModel> _promos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MemberPromoModel> get promos => _promos;
  List<MemberPromoModel> get activePromos => _promos.where((p) => p.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? prefs.getString('token');
  }

  Future<void> fetchPromos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        await _loadFromLocal();
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/member-promos'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List list = data['data'] ?? [];
        _promos = list.map((json) => MemberPromoModel.fromJson(json)).toList();

        // Sync to local SQLite
        final localData = _promos.map((p) => p.toJson()).toList();
        await DatabaseHelper.instance.syncLocalMemberPromos(localData);
      } else {
        await _loadFromLocal();
      }
    } catch (e) {
      debugPrint('Error fetching member promos, fallback to local: $e');
      await _loadFromLocal();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final localMaps = await DatabaseHelper.instance.getLocalMemberPromos();
      _promos = localMaps.map((map) => MemberPromoModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint('Error loading local member promos: $e');
      _errorMessage = 'Gagal memuat promo member offline';
    }
  }

  Future<bool> createPromo({
    required String name,
    String? description,
    required String discountType,
    required double discountValue,
    double minPurchase = 0.0,
    String? startDate,
    String? endDate,
    bool isActive = true,
    required List<int> productIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _errorMessage = 'Sesi telah berakhir.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/member-promos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'discount_type': discountType,
          'discount_value': discountValue,
          'min_purchase': minPurchase,
          'start_date': startDate,
          'end_date': endDate,
          'is_active': isActive ? 1 : 0,
          'product_ids': productIds,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await fetchPromos();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Gagal membuat promo member.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan koneksi: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePromo({
    required int id,
    required String name,
    String? description,
    required String discountType,
    required double discountValue,
    double minPurchase = 0.0,
    String? startDate,
    String? endDate,
    bool isActive = true,
    required List<int> productIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/member-promos/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'discount_type': discountType,
          'discount_value': discountValue,
          'min_purchase': minPurchase,
          'start_date': startDate,
          'end_date': endDate,
          'is_active': isActive ? 1 : 0,
          'product_ids': productIds,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchPromos();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Gagal memperbarui promo member.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan koneksi: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePromo(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/member-promos/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _promos.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Gagal menghapus promo member.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan koneksi: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
