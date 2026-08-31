import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/branch_model.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';

class BranchProvider with ChangeNotifier {
  List<BranchModel> _branches = [];
  bool _isLoading = false;
  String? _error;

  List<BranchModel> get branches => _branches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _apiUrl = ApiConfig.baseUrl;

  Future<void> fetchBranches(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/branches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      ApiClient.inspect(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        _branches = data.map((json) => BranchModel.fromJson(json)).toList();
      } else {
        _error = 'Gagal mengambil data cabang';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan jaringan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addBranch(String token, String name, double lat, double lng, int radius) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/branches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'latitude': lat,
          'longitude': lng,
          'radius_meters': radius,
        }),
      );
      ApiClient.inspect(response);

      if (response.statusCode == 201) {
        await fetchBranches(token);
        return true;
      }
    } catch (e) {
      debugPrint('Error add branch: $e');
    }
    return false;
  }

  Future<bool> updateBranch(String token, int id, String name, double lat, double lng, int radius) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/branches/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'latitude': lat,
          'longitude': lng,
          'radius_meters': radius,
        }),
      );
      ApiClient.inspect(response);

      if (response.statusCode == 200) {
        await fetchBranches(token);
        return true;
      }
    } catch (e) {
      debugPrint('Error update branch: $e');
    }
    return false;
  }

  Future<bool> deleteBranch(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiUrl/branches/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      ApiClient.inspect(response);

      if (response.statusCode == 200) {
        _branches.removeWhere((b) => b.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error delete branch: $e');
    }
    return false;
  }
}
