import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ingredient_model.dart';
import '../config/api_config.dart';

class IngredientProvider extends ChangeNotifier {
  List<IngredientModel> _ingredients = [];
  bool _isLoading = false;
  int? _selectedBranchId;

  List<IngredientModel> get ingredients => _ingredients;
  bool get isLoading => _isLoading;
  int? get selectedBranchId => _selectedBranchId;

  final String _apiUrl = '${ApiConfig.baseUrl}/ingredients';

  Future<void> fetchIngredients({int? branchId}) async {
    _isLoading = true;
    _selectedBranchId = branchId;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      String url = _apiUrl;
      if (branchId != null) {
        url = '$_apiUrl?branch_id=$branchId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _ingredients = (data['data'] as List)
            .map((item) => IngredientModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetch ingredients: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addIngredient(String name, String unit, double qty, {double tolerancePercent = 0, double price = 0, int? branchId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final bodyMap = <String, dynamic>{
        'name': name,
        'unit': unit,
        'stock_qty': qty,
        'tolerance_percent': tolerancePercent,
        'price': price,
      };
      if (branchId != null) {
        bodyMap['branch_id'] = branchId;
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode == 201) {
        await fetchIngredients(branchId: _selectedBranchId);
        return true;
      }
    } catch (e) {
      debugPrint('Error add ingredient: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
