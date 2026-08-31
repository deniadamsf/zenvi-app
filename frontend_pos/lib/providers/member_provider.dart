import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../database/database_helper.dart';
import '../models/member_model.dart';
import '../services/api_client.dart';

class MemberProvider extends ChangeNotifier {
  List<MemberModel> _members = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _errorMessage;

  List<MemberModel> get members => _members;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  List<MemberModel> get filteredMembers {
    if (_searchQuery.trim().isEmpty) return _members;
    final q = _searchQuery.toLowerCase();
    return _members.where((m) {
      return m.name.toLowerCase().contains(q) ||
          m.phone.toLowerCase().contains(q) ||
          m.memberCode.toLowerCase().contains(q);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? prefs.getString('token');
  }

  Future<void> fetchMembers({String? query}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        await _loadFromLocal(query: query);
        return;
      }

      String endpoint = '${ApiConfig.baseUrl}/members';
      if (query != null && query.trim().isNotEmpty) {
        endpoint += '?search=${Uri.encodeComponent(query.trim())}';
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      ApiClient.inspect(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List list = data['data'] ?? [];
        _members = list.map((json) => MemberModel.fromJson(json)).toList();

        // Sync local SQLite for offline support
        final localData = _members.map((m) => m.toJson()).toList();
        await DatabaseHelper.instance.syncLocalMembers(localData);
      } else {
        await _loadFromLocal(query: query);
      }
    } catch (e) {
      debugPrint('Error fetching members from API, fallback to local: $e');
      await _loadFromLocal(query: query);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromLocal({String? query}) async {
    try {
      final localMaps = await DatabaseHelper.instance.getLocalMembers(query: query);
      _members = localMaps.map((map) => MemberModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint('Error loading local members: $e');
      _errorMessage = 'Gagal memuat data member offline';
    }
  }

  Future<MemberModel?> createMember({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? birthDate,
    double customDiscountPercent = 0.0,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _errorMessage = 'Sesi telah berakhir, silakan login kembali.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/members'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'address': address,
          'birth_date': birthDate,
          'custom_discount_percent': customDiscountPercent,
          'notes': notes,
        }),
      );
      ApiClient.inspect(response);

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final newMember = MemberModel.fromJson(data['data']);
        await fetchMembers();
        return newMember;
      } else {
        _errorMessage = data['message'] ?? 'gagal_menambahkan_member_25'.tr();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan koneksi: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMember({
    required int id,
    required String name,
    required String phone,
    String? email,
    String? address,
    String? birthDate,
    double customDiscountPercent = 0.0,
    bool isActive = true,
    String? notes,
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

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/members/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'address': address,
          'birth_date': birthDate,
          'custom_discount_percent': customDiscountPercent,
          'is_active': isActive ? 1 : 0,
          'notes': notes,
        }),
      );
      ApiClient.inspect(response);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchMembers();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Gagal memperbarui member.';
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

  Future<bool> deleteMember(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/members/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      ApiClient.inspect(response);

      if (response.statusCode == 200) {
        _members.removeWhere((m) => m.id == id);
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Gagal menghapus member.';
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

  Future<Map<String, dynamic>?> getMemberDetail(int id) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/members/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      ApiClient.inspect(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('Error getting member detail: $e');
    }
    return null;
  }
}
