import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../config/api_config.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  List<String> get categories {
    final cats = _products
        .map((p) => p.category?.trim())
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    cats.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cats;
  }

  static const String _apiUrl = ApiConfig.baseUrl;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> fetchProducts() async {
    final token = await _getToken();
    if (token == null) return false;

    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        _products = data.map((item) => ProductModel.fromJson(item)).toList();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint('Error fetch products: $e');
    }
    
    _setLoading(false);
    return false;
  }

  Future<bool> addProduct({
    required String name,
    String? category,
    required double price,
    required bool isActive,
    double discountNominal = 0.0,
    double discountPercent = 0.0,
    File? imageFile,
    List<Map<String, dynamic>> ingredients = const [],
    List<Map<String, dynamic>> variants = const [],
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    _setLoading(true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_apiUrl/products'));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['name'] = name;
      if (category != null && category.trim().isNotEmpty) {
        request.fields['category'] = category.trim();
      }
      request.fields['price'] = price.toString();
      request.fields['is_active'] = isActive ? '1' : '0';
      request.fields['discount_nominal'] = discountNominal.toString();
      request.fields['discount_percent'] = discountPercent.toString();

      for (int i = 0; i < ingredients.length; i++) {
        request.fields['ingredients[$i][ingredient_id]'] = ingredients[i]['ingredient_id'].toString();
        request.fields['ingredients[$i][amount_needed]'] = ingredients[i]['amount_needed'].toString();
      }

      for (int i = 0; i < variants.length; i++) {
        request.fields['variants[$i][name]'] = variants[i]['name'].toString();
        request.fields['variants[$i][price]'] = variants[i]['price'].toString();
        request.fields['variants[$i][is_active]'] = variants[i]['is_active'] ? '1' : '0';
      }

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        await fetchProducts(); // Refresh list
        _setLoading(false);
        return true;
      } else {
        debugPrint('Gagal menambah produk: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error add product: $e');
    }

    _setLoading(false);
    return false;
  }

  Future<bool> updateProduct({
    required int id,
    required String name,
    String? category,
    required double price,
    required bool isActive,
    double discountNominal = 0.0,
    double discountPercent = 0.0,
    File? imageFile,
    List<Map<String, dynamic>> ingredients = const [],
    List<Map<String, dynamic>> variants = const [],
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    _setLoading(true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_apiUrl/products/$id'));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      request.fields['_method'] = 'PUT'; // Laravel form method spoofing

      request.fields['name'] = name;
      if (category != null) {
        request.fields['category'] = category.trim();
      }
      request.fields['price'] = price.toString();
      request.fields['is_active'] = isActive ? '1' : '0';
      request.fields['discount_nominal'] = discountNominal.toString();
      request.fields['discount_percent'] = discountPercent.toString();

      for (int i = 0; i < ingredients.length; i++) {
        request.fields['ingredients[$i][ingredient_id]'] = ingredients[i]['ingredient_id'].toString();
        request.fields['ingredients[$i][amount_needed]'] = ingredients[i]['amount_needed'].toString();
      }

      for (int i = 0; i < variants.length; i++) {
        request.fields['variants[$i][name]'] = variants[i]['name'].toString();
        request.fields['variants[$i][price]'] = variants[i]['price'].toString();
        request.fields['variants[$i][is_active]'] = variants[i]['is_active'] ? '1' : '0';
      }

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchProducts(); // Refresh list
        _setLoading(false);
        return true;
      } else {
        debugPrint('Gagal update produk: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error update product: $e');
    }

    _setLoading(false);
    return false;
  }
}
