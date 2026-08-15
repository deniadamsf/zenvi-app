import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/employee_permission_model.dart';

class EmployeePermissionProvider extends ChangeNotifier {
  List<EmployeePermission> _permissions = [];
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilterStatus = 'all';

  List<EmployeePermission> get permissions => _permissions;
  int get pendingCount => _pendingCount;
  int get approvedCount => _approvedCount;
  int get rejectedCount => _rejectedCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilterStatus => _selectedFilterStatus;

  static const String _baseUrl = ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void setFilterStatus(String status) {
    _selectedFilterStatus = status;
    fetchPermissions();
  }

  Future<bool> fetchPermissions() async {
    final token = await _getToken();
    if (token == null) {
      _errorMessage = 'sesi_telah_berakhir_silakan_43'.tr();
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String url = '$_baseUrl/permissions';
      if (_selectedFilterStatus != 'all') {
        url += '?status=$_selectedFilterStatus';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        _pendingCount = (body['pending_count'] as num?)?.toInt() ?? 0;
        _approvedCount = (body['approved_count'] as num?)?.toInt() ?? 0;
        _rejectedCount = (body['rejected_count'] as num?)?.toInt() ?? 0;

        final List<dynamic> data = body['data'] ?? [];
        _permissions = data.map((item) => EmployeePermission.fromJson(item)).toList();
        notifyListeners();
        return true;
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        _errorMessage = body['message'] ?? 'Gagal memuat daftar izin.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> submitPermission({
    required String type,
    required String permissionDate,
    String? estimatedArrivalTime,
    required String reason,
    required File attachmentFile,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi login tidak valid.'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/permissions'));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['type'] = type;
      request.fields['permission_date'] = permissionDate;
      if (type == 'late' && estimatedArrivalTime != null && estimatedArrivalTime.isNotEmpty) {
        request.fields['estimated_arrival_time'] = estimatedArrivalTime;
      }
      request.fields['reason'] = reason;

      request.files.add(await http.MultipartFile.fromPath('attachment', attachmentFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _isLoading = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchPermissions();
        return {'success': true, 'message': 'Pengajuan izin berhasil dikirim!'};
      } else {
        notifyListeners();
        final Map<String, dynamic> body = jsonDecode(response.body);
        return {'success': false, 'message': body['message'] ?? 'Gagal mengirim pengajuan izin.'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  Future<bool> approvePermission(int id) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/permissions/$id/approve'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchPermissions();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error approving permission: $e');
      return false;
    }
  }

  Future<bool> rejectPermission(int id, {String? rejectionNote}) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/permissions/$id/reject'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (rejectionNote != null && rejectionNote.isNotEmpty) 'rejection_note': rejectionNote,
        }),
      );

      if (response.statusCode == 200) {
        await fetchPermissions();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error rejecting permission: $e');
      return false;
    }
  }

  Future<bool> deletePermission(int id) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/permissions/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchPermissions();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting permission: $e');
      return false;
    }
  }
}
