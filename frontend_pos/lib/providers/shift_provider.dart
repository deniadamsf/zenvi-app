import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift_model.dart';
import '../config/api_config.dart';

class ShiftProvider extends ChangeNotifier {
  List<ShiftModel> _shiftLogs = [];
  List<Map<String, dynamic>> _shiftSummaries = [];
  double _totalSummaryRevenue = 0.0;
  ShiftModel? _activeShift;
  bool _isLoading = false;

  List<ShiftModel> get shiftLogs => _shiftLogs;
  List<Map<String, dynamic>> get shiftSummaries => _shiftSummaries;
  double get totalSummaryRevenue => _totalSummaryRevenue;
  ShiftModel? get activeShift => _activeShift;
  bool get isLoading => _isLoading;

  final String _apiUrl = ApiConfig.baseUrl;

  ShiftProvider() {
    _loadCachedShift();
  }

  Future<void> _loadCachedShift() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedShiftJson = prefs.getString('cached_active_shift');
      if (cachedShiftJson != null) {
        final data = jsonDecode(cachedShiftJson);
        _activeShift = ShiftModel.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached shift: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchActiveShift(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/shifts/active'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final prefs = await SharedPreferences.getInstance();
        if (data != null) {
          _activeShift = ShiftModel.fromJson(data);
          await prefs.setString('cached_active_shift', jsonEncode(data));
        } else {
          _activeShift = null;
          await prefs.remove('cached_active_shift');
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching active shift (offline fallback maintained): $e');
    }
  }

  Future<void> fetchShiftLogs(String token, {String? date, String? userId}) async {
    _setLoading(true);
    try {
      var uri = Uri.parse('$_apiUrl/shifts');
      Map<String, String> queryParams = {};
      if (date != null) queryParams['date'] = date;
      if (userId != null) queryParams['user_id'] = userId;
      
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _shiftLogs = data.map((json) => ShiftModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching shift logs: $e');
    }
    _setLoading(false);
  }

  Future<bool> startShift(String token, double openingBalance, File? selfie, double? lat, double? lng) async {
    _setLoading(true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_apiUrl/shifts/open'));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      request.fields['opening_balance'] = openingBalance.toString();
      if (lat != null) request.fields['latitude'] = lat.toString();
      if (lng != null) request.fields['longitude'] = lng.toString();
      
      if (selfie != null) {
        request.files.add(await http.MultipartFile.fromPath('selfie', selfie.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        _activeShift = ShiftModel.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_active_shift', jsonEncode(data));
        _setLoading(false);
        return true;
      } else {
        debugPrint('Failed to start shift: ${response.body}');
        throw Exception(jsonDecode(response.body)['message'] ?? 'Gagal memulai shift');
      }
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> endShift(String token, int shiftId, double closingBalance, List<Map<String, dynamic>> opnameData) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/shifts/close'),
        headers: {
          'Authorization': 'Bearer $token', 
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'shift_id': shiftId,
          'closing_balance': closingBalance,
          'opname_data': opnameData,
        }),
      );

      if (response.statusCode == 200) {
        _activeShift = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_active_shift');
        _setLoading(false);
        return true;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Gagal mengakhiri shift');
      }
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchShiftSummary(String token) async {
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/shifts/summary'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _shiftSummaries = (data['data'] as List).map((item) {
          final map = Map<String, dynamic>.from(item);
          // Parse revenue dari String ke double agar tidak error di NumberFormat
          map['revenue'] = double.tryParse(map['revenue']?.toString() ?? '0') ?? 0.0;
          return map;
        }).toList();
        _totalSummaryRevenue = double.tryParse(data['total_revenue']?.toString() ?? '0') ?? 0.0;
      }
    } catch (e) {
      debugPrint('Error fetching shift summary: $e');
    }
    _setLoading(false);
  }
}
