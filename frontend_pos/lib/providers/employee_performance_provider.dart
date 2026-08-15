import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/employee_performance_model.dart';

class EmployeePerformanceProvider extends ChangeNotifier {
  EmployeePerformanceReport? _report;
  bool _isLoading = false;
  String _selectedPeriod = 'this_month';
  String? _errorMessage;

  EmployeePerformanceReport? get report => _report;
  bool get isLoading => _isLoading;
  String get selectedPeriod => _selectedPeriod;
  String? get errorMessage => _errorMessage;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void setPeriod(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      fetchPerformanceReport();
    }
  }

  Future<void> fetchPerformanceReport() async {
    final token = await _getToken();
    if (token == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/reports/employee-performance?period=$_selectedPeriod');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _report = EmployeePerformanceReport.fromJson(data);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? 'Gagal memuat data performa karyawan';
      }
    } catch (e) {
      debugPrint('Error fetch employee performance: $e');
      _errorMessage = 'Terjadi kesalahan jaringan saat memuat data performa';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
