import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';

class StockHistoryModel {
  final int id;
  final String userName;
  final String ingredientName;
  final String ingredientUnit;
  final String? branchName;
  final int? branchId;
  final String type;
  final double qtyChange;
  final String notes;
  final bool isSuspicious;
  final DateTime createdAt;

  StockHistoryModel({
    required this.id,
    required this.userName,
    required this.ingredientName,
    required this.ingredientUnit,
    this.branchName,
    this.branchId,
    required this.type,
    required this.qtyChange,
    required this.notes,
    required this.isSuspicious,
    required this.createdAt,
  });

  factory StockHistoryModel.fromJson(Map<String, dynamic> json) {
    final double change = double.tryParse(json['qty_change']?.toString() ?? '0') ?? 0.0;
    final String noteText = json['notes']?.toString() ?? '';
    final bool suspicious = json['is_suspicious'] == 1 || 
                            json['is_suspicious'] == true || 
                            noteText.toLowerCase().contains('selisih') || 
                            noteText.toLowerCase().contains('manual') ||
                            change < -10;

    return StockHistoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userName: json['user']?['name']?.toString() ?? 'Sistem',
      ingredientName: json['ingredient']?['name']?.toString() ?? 'Bahan',
      ingredientUnit: json['ingredient']?['unit']?.toString() ?? '',
      branchName: json['branch']?['name']?.toString(),
      branchId: json['branch_id'] != null ? int.tryParse(json['branch_id'].toString()) : null,
      type: json['type']?.toString() ?? 'opname',
      qtyChange: change,
      notes: noteText,
      isSuspicious: suspicious,
      createdAt: json['created_at'] != null 
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class StockManagementProvider extends ChangeNotifier {
  List<StockHistoryModel> _histories = [];
  bool _isLoading = false;
  String _lastErrorMessage = '';
  int? _selectedBranchId;

  List<StockHistoryModel> get histories => _histories;
  bool get isLoading => _isLoading;
  String get lastErrorMessage => _lastErrorMessage;
  int? get selectedBranchId => _selectedBranchId;

  final String _apiUrl = '${ApiConfig.baseUrl}/stock';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchHistory({int? branchId}) async {
    _setLoading(true);
    _lastErrorMessage = '';
    _selectedBranchId = branchId;
    try {
      String url = '$_apiUrl/history';
      if (branchId != null) {
        url = '$_apiUrl/history?branch_id=$branchId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'] ?? [];
        _histories = data.map((json) => StockHistoryModel.fromJson(json)).toList();
      } else {
        try {
          final decoded = jsonDecode(response.body);
          _lastErrorMessage = decoded['message'] ?? 'Gagal memuat riwayat stok';
        } catch (_) {
          _lastErrorMessage = 'Gagal memuat riwayat stok (${response.statusCode})';
        }
      }
    } catch (e) {
      _lastErrorMessage = 'Koneksi error: $e';
      debugPrint('Error fetching history: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> restock(int ingredientId, double qty, double totalPrice, String notes, {int? branchId}) async {
    _setLoading(true);
    _lastErrorMessage = '';
    try {
      final bodyMap = <String, dynamic>{
        'ingredient_id': ingredientId,
        'qty': qty,
        'total_price': totalPrice,
        'notes': notes,
      };
      if (branchId != null) {
        bodyMap['branch_id'] = branchId;
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/restock'),
        headers: await _getHeaders(),
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchHistory(branchId: _selectedBranchId);
        return true;
      } else {
        try {
          final decoded = jsonDecode(response.body);
          _lastErrorMessage = decoded['message'] ?? 'Gagal restock bahan';
        } catch (_) {
          _lastErrorMessage = 'Gagal restock bahan (${response.statusCode})';
        }
        return false;
      }
    } catch (e) {
      _lastErrorMessage = 'Koneksi error: $e';
      debugPrint('Error restock: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> wastage(int ingredientId, double qty, String notes, {int? branchId}) async {
    _setLoading(true);
    _lastErrorMessage = '';
    try {
      final bodyMap = <String, dynamic>{
        'ingredient_id': ingredientId,
        'qty': qty,
        'notes': notes,
      };
      if (branchId != null) {
        bodyMap['branch_id'] = branchId;
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/wastage'),
        headers: await _getHeaders(),
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchHistory(branchId: _selectedBranchId);
        return true;
      } else {
        try {
          final decoded = jsonDecode(response.body);
          _lastErrorMessage = decoded['message'] ?? 'Gagal catat wastage';
        } catch (_) {
          _lastErrorMessage = 'Gagal catat wastage (${response.statusCode})';
        }
        return false;
      }
    } catch (e) {
      _lastErrorMessage = 'Koneksi error: $e';
      debugPrint('Error wastage: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Memindahkan stok bahan dari satu cabang ke cabang lain (paket Bisnis).
  ///
  /// Server yang memutuskan boleh atau tidak; balasan 403 bertipe ditangkap
  /// ApiClient.inspect() dan diubah jadi tawaran upgrade, bukan pesan error.
  Future<bool> transfer({
    required int ingredientId,
    required int fromBranchId,
    required int toBranchId,
    required double qty,
    String notes = '',
  }) async {
    _setLoading(true);
    _lastErrorMessage = '';
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/transfer'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'ingredient_id': ingredientId,
          'from_branch_id': fromBranchId,
          'to_branch_id': toBranchId,
          'qty': qty,
          'notes': notes,
        }),
      );

      if (ApiClient.inspect(response)) {
        _lastErrorMessage = '';
        return false;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchHistory(branchId: _selectedBranchId);
        return true;
      }

      try {
        _lastErrorMessage = jsonDecode(response.body)['message'] ?? 'Transfer gagal';
      } catch (_) {
        _lastErrorMessage = 'Transfer gagal (${response.statusCode})';
      }
      return false;
    } catch (e) {
      _lastErrorMessage = 'Koneksi error: $e';
      debugPrint('Error transfer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> opname(int ingredientId, double actualQty, String notes, {int? branchId}) async {
    _setLoading(true);
    _lastErrorMessage = '';
    try {
      final bodyMap = <String, dynamic>{
        'ingredient_id': ingredientId,
        'actual_qty': actualQty,
        'notes': notes,
      };
      if (branchId != null) {
        bodyMap['branch_id'] = branchId;
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/opname'),
        headers: await _getHeaders(),
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchHistory(branchId: _selectedBranchId);
        return true;
      } else {
        try {
          final decoded = jsonDecode(response.body);
          _lastErrorMessage = decoded['message'] ?? 'Gagal simpan opname';
        } catch (_) {
          _lastErrorMessage = 'Gagal simpan opname (${response.statusCode})';
        }
        return false;
      }
    } catch (e) {
      _lastErrorMessage = 'Koneksi error: $e';
      debugPrint('Error opname: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
