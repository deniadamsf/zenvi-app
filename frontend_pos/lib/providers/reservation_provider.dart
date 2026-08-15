import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reservation_model.dart';
import '../config/api_config.dart';

class ReservationProvider extends ChangeNotifier {
  List<ReservationModel> _reservations = [];
  bool _isLoading = false;
  String _selectedStatusFilter = 'all'; // 'all', 'pending', 'confirmed', 'completed', 'cancelled'
  String? _selectedDateFilter; // YYYY-MM-DD
  String _searchQuery = '';

  List<ReservationModel> get allReservations => _reservations;
  bool get isLoading => _isLoading;
  String get selectedStatusFilter => _selectedStatusFilter;
  String? get selectedDateFilter => _selectedDateFilter;
  String get searchQuery => _searchQuery;

  int get pendingCount => _reservations.where((r) => r.status == 'pending').length;
  int get confirmedCount => _reservations.where((r) => r.status == 'confirmed').length;
  int get completedCount => _reservations.where((r) => r.status == 'completed').length;
  int get cancelledCount => _reservations.where((r) => r.status == 'cancelled').length;

  List<ReservationModel> get filteredReservations {
    return _reservations.where((res) {
      // Status filter
      if (_selectedStatusFilter != 'all' && res.status != _selectedStatusFilter) {
        return false;
      }
      // Date filter
      if (_selectedDateFilter != null && _selectedDateFilter!.isNotEmpty) {
        if (res.reservationDate != _selectedDateFilter) {
          return false;
        }
      }
      // Search filter (name or phone or service)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = res.customerName.toLowerCase().contains(q);
        final matchPhone = res.customerPhone.toLowerCase().contains(q);
        final matchService = (res.serviceNames ?? '').toLowerCase().contains(q);
        if (!matchName && !matchPhone && !matchService) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  static const String _apiUrl = ApiConfig.baseUrl;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setDateFilter(String? date) {
    _selectedDateFilter = date;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchReservations({String? status, String? date, int? branchId}) async {
    final token = await _getToken();
    if (token == null) return;

    _setLoading(true);
    try {
      final queryParams = <String, String>{};
      if (status != null && status != 'all') queryParams['status'] = status;
      if (date != null && date.isNotEmpty) queryParams['date'] = date;
      if (branchId != null) queryParams['branch_id'] = branchId.toString();

      final uri = Uri.parse('$_apiUrl/reservations').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        _reservations = data.map((item) => ReservationModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetchReservations: $e');
    }
    _setLoading(false);
  }

  Future<bool> updateReservationStatus(int id, String status, {int? assignedStaffId}) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$_apiUrl/reservations/$id/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'assigned_staff_id': ?assignedStaffId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['data'] != null) {
          final updated = ReservationModel.fromJson(body['data']);
          final index = _reservations.indexWhere((r) => r.id == id);
          if (index != -1) {
            _reservations[index] = updated;
            notifyListeners();
          }
        } else {
          await fetchReservations();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error updateReservationStatus: $e');
    }
    return false;
  }

  Future<bool> createReservation({
    required String customerName,
    required String customerPhone,
    required String reservationDate,
    required String reservationTime,
    int numberOfPeople = 1,
    String? serviceNames,
    String? notes,
    int? branchId,
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    _setLoading(true);
    try {
      final bodyMap = <String, dynamic>{
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'reservation_date': reservationDate,
        'reservation_time': reservationTime,
        'number_of_people': numberOfPeople,
        'service_names': serviceNames,
        'notes': notes,
      };
      if (branchId != null) {
        bodyMap['branch_id'] = branchId;
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/reservations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode == 201) {
        await fetchReservations();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint('Error createReservation: $e');
    }
    _setLoading(false);
    return false;
  }

  Future<bool> deleteReservation(int id) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_apiUrl/reservations/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _reservations.removeWhere((r) => r.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleteReservation: $e');
    }
    return false;
  }
}
