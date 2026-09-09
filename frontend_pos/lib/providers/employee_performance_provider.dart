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

  /// Ambil laporan performa untuk rentang tanggal tertentu, apa adanya seperti
  /// yang dikirim server, TANPA mengubah state layar performa.
  ///
  /// Dipakai ekspor supaya isi berkas mengikuti filter waktu yang sedang dipilih
  /// di dashboard owner, bukan periode yang kebetulan terakhir dibuka di layar
  /// performa karyawan. Rentangnya dikirim sebagai tanggal eksplisit, bukan nama
  /// periode: kedua endpoint memakai ejaan yang berbeda untuk periode yang sama
  /// (`7_days` di laporan keuangan, `7days` di performa karyawan), dan
  /// menyamakannya lewat tabel padanan hanya menunggu salah satu berubah diam-diam.
  ///
  /// `shift_detail=full` meminta seluruh shift dalam rentang, bukan 5 terakhir
  /// yang cukup untuk kartu dashboard tapi memotong laporan absensi.
  Future<Map<String, dynamic>?> fetchReportForExport({
    required String startDate,
    required String endDate,
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    final uri = Uri.parse('${ApiConfig.baseUrl}/reports/employee-performance').replace(
      queryParameters: {
        'period': 'custom',
        'start_date': startDate,
        'end_date': endDate,
        'shift_detail': 'full',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : null;
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
