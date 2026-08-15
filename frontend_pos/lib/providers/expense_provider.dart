import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';
import '../config/api_config.dart';

class ExpenseProvider extends ChangeNotifier {
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;

  double _totalSales = 0;
  double _totalCogs = 0;
  double _grossProfit = 0;
  double _grossMarginPercent = 0;
  double _totalExpenses = 0;
  double _netProfit = 0;
  double _netMarginPercent = 0;
  int _totalOrders = 0;
  double _averageOrderValue = 0;

  List<Map<String, dynamic>> _chartData = [];
  List<Map<String, dynamic>> _hourlySales = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _branchPerformance = [];
  
  List<Map<String, dynamic>> _shiftSummaries = [];
  List<Map<String, dynamic>> _recentExpenses = [];
  List<Map<String, dynamic>> _expenseBreakdown = [];

  String _currentPeriod = 'today';
  String? _selectedBranchId; // null or 'all' = All branches
  DateTime _selectedDate = DateTime.now();

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  double get totalSales => _totalSales;
  double get totalCogs => _totalCogs;
  double get grossProfit => _grossProfit;
  double get grossMarginPercent => _grossMarginPercent;
  double get totalExpenses => _totalExpenses;
  double get netProfit => _netProfit;
  double get netMarginPercent => _netMarginPercent;
  int get totalOrders => _totalOrders;
  double get averageOrderValue => _averageOrderValue;
  
  List<Map<String, dynamic>> get chartData => _chartData;
  List<Map<String, dynamic>> get hourlySales => _hourlySales;
  List<Map<String, dynamic>> get paymentMethods => _paymentMethods;
  List<Map<String, dynamic>> get topProducts => _topProducts;
  List<Map<String, dynamic>> get branchPerformance => _branchPerformance;
  List<Map<String, dynamic>> get shiftSummaries => _shiftSummaries;
  List<Map<String, dynamic>> get recentExpenses => _recentExpenses;
  List<Map<String, dynamic>> get expenseBreakdown => _expenseBreakdown;

  String get currentPeriod => _currentPeriod;
  String? get selectedBranchId => _selectedBranchId;
  DateTime get selectedDate => _selectedDate;

  static const String _apiUrl = ApiConfig.baseUrl;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setSelectedBranchId(String? branchId) {
    _selectedBranchId = branchId;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchExpenses() async {
    final token = await _getToken();
    if (token == null) return;

    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/expenses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        _expenses = data.map((item) => ExpenseModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetch expenses: $e');
    }
    _setLoading(false);
  }

  Future<void> fetchFinancialReport({
    String? period,
    String? branchId,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await _getToken();
    if (token == null) return;
    
    if (period != null) _currentPeriod = period;
    if (branchId != null) _selectedBranchId = branchId;
    if (date != null) _selectedDate = date;

    _setLoading(true);

    try {
      final queryParams = <String, String>{
        'period': _currentPeriod,
      };

      if (_currentPeriod == 'date' || _currentPeriod == 'custom') {
        if (startDate != null && endDate != null) {
          queryParams['start_date'] = "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
          queryParams['end_date'] = "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
        } else {
          queryParams['date'] = "${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
        }
      }

      if (_selectedBranchId != null && _selectedBranchId!.isNotEmpty && _selectedBranchId != 'all') {
        queryParams['branch_id'] = _selectedBranchId!;
      }

      final uri = Uri.parse('$_apiUrl/reports/financial').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final data = res['data'] ?? {};

        _totalSales = double.tryParse(data['total_sales']?.toString() ?? '0') ?? 0.0;
        _totalCogs = double.tryParse(data['total_cogs']?.toString() ?? '0') ?? 0.0;
        _grossProfit = double.tryParse(data['gross_profit']?.toString() ?? '0') ?? (_totalSales - _totalCogs);
        _grossMarginPercent = double.tryParse(data['gross_margin_percent']?.toString() ?? '0') ?? (_totalSales > 0 ? ((_grossProfit / _totalSales) * 100) : 0.0);
        _totalExpenses = double.tryParse(data['total_expenses']?.toString() ?? '0') ?? 0.0;
        _netProfit = double.tryParse(data['net_profit']?.toString() ?? '0') ?? (_grossProfit - _totalExpenses);
        _netMarginPercent = double.tryParse(data['net_margin_percent']?.toString() ?? '0') ?? (_totalSales > 0 ? ((_netProfit / _totalSales) * 100) : 0.0);
        _totalOrders = int.tryParse(data['total_orders']?.toString() ?? '0') ?? 0;
        _averageOrderValue = double.tryParse(data['avg_order_value']?.toString() ?? data['average_order_value']?.toString() ?? '0') ?? 0.0;
        
        if (data['chart_data'] != null) {
          _chartData = (data['chart_data'] as List).map((item) {
            final map = Map<String, dynamic>.from(item);
            map['sales'] = double.tryParse(map['sales']?.toString() ?? '0') ?? 0.0;
            map['cogs'] = double.tryParse(map['cogs']?.toString() ?? '0') ?? 0.0;
            map['gross_profit'] = double.tryParse(map['gross_profit']?.toString() ?? '0') ?? (map['sales'] - map['cogs']);
            map['expense'] = double.tryParse(map['expense']?.toString() ?? '0') ?? 0.0;
            map['profit'] = double.tryParse(map['profit']?.toString() ?? map['net_profit']?.toString() ?? '0') ?? (map['gross_profit'] - map['expense']);
            map['orders'] = int.tryParse(map['orders']?.toString() ?? '0') ?? 0;
            map['label'] = map['label']?.toString() ?? map['date']?.toString() ?? '';
            return map;
          }).toList();
        } else {
          _chartData = [];
        }

        if (data['hourly_sales'] != null) {
          _hourlySales = (data['hourly_sales'] as List).map((item) {
            final map = Map<String, dynamic>.from(item);
            map['sales'] = double.tryParse(map['sales']?.toString() ?? '0') ?? 0.0;
            map['orders'] = int.tryParse(map['orders']?.toString() ?? '0') ?? 0;
            return map;
          }).toList();
        } else {
          _hourlySales = [];
        }

        if (data['payment_methods'] != null) {
          _paymentMethods = (data['payment_methods'] as List).map((item) {
            final map = Map<String, dynamic>.from(item);
            map['total'] = double.tryParse(map['total']?.toString() ?? map['amount']?.toString() ?? '0') ?? 0.0;
            map['count'] = int.tryParse(map['count']?.toString() ?? '0') ?? 0;
            map['percent'] = double.tryParse(map['percent']?.toString() ?? map['percentage']?.toString() ?? '0') ?? 0.0;
            return map;
          }).toList();
        } else {
          _paymentMethods = [];
        }

        if (data['top_products'] != null) {
          _topProducts = (data['top_products'] as List).map((item) {
            final map = Map<String, dynamic>.from(item);
            map['total'] = double.tryParse(map['total']?.toString() ?? map['revenue']?.toString() ?? '0') ?? 0.0;
            map['qty'] = double.tryParse(map['qty']?.toString() ?? '0') ?? 0.0;
            return map;
          }).toList();
        } else {
          _topProducts = [];
        }

        if (data['branch_performance'] != null) {
          _branchPerformance = (data['branch_performance'] as List).map((item) {
            final map = Map<String, dynamic>.from(item);
            map['sales'] = double.tryParse(map['sales']?.toString() ?? '0') ?? 0.0;
            map['orders'] = int.tryParse(map['orders']?.toString() ?? map['orders_count']?.toString() ?? '0') ?? 0;
            map['active_shifts'] = int.tryParse(map['active_shifts']?.toString() ?? '0') ?? 0;
            return map;
          }).toList();
        } else {
          _branchPerformance = [];
        }

        if (data['shift_summaries'] != null) {
          _shiftSummaries = (data['shift_summaries'] as List).map((item) {
            return Map<String, dynamic>.from(item);
          }).toList();
        } else {
          _shiftSummaries = [];
        }

        if (data['recent_expenses'] != null) {
          _recentExpenses = (data['recent_expenses'] as List).map((item) {
            final map = Map<String, dynamic>.from(item);
            map['amount'] = double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0;
            return map;
          }).toList();
        } else {
          _recentExpenses = [];
        }

        if (data['expense_breakdown'] != null) {
          _expenseBreakdown = (data['expense_breakdown'] as List).map((item) {
            final map = Map<String, dynamic>.from(item);
            map['amount'] = double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0;
            map['total'] = double.tryParse(map['total']?.toString() ?? '0') ?? 0.0;
            map['count'] = int.tryParse(map['count']?.toString() ?? '0') ?? 0;
            map['percent'] = double.tryParse(map['percent']?.toString() ?? '0') ?? 0.0;
            return map;
          }).toList();
        } else {
          _expenseBreakdown = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetch financial report: $e');
    }

    if (_shiftSummaries.isEmpty) {
      await _fetchShiftSummariesInternal(token);
    }

    _setLoading(false);
  }

  Future<void> _fetchShiftSummariesInternal(String token) async {
    try {
      final queryParams = <String, String>{};
      if (_selectedBranchId != null && _selectedBranchId!.isNotEmpty && _selectedBranchId != 'all') {
        queryParams['branch_id'] = _selectedBranchId!;
      }

      final uri = Uri.parse('$_apiUrl/shifts/summary').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final List<dynamic> data = res['data'] ?? [];
        _shiftSummaries = data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetch shift summary: $e');
    }
  }

  Future<bool> addExpense({
    required String expenseType,
    required double amount,
    String? description,
    int? ingredientId,
    double? qtyAdded,
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/expenses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'expense_type': expenseType,
          'amount': amount,
          'description': description,
          'ingredient_id': ingredientId,
          'qty_added': qtyAdded,
        }),
      );

      if (response.statusCode == 201) {
        await fetchExpenses();
        await fetchFinancialReport();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint('Error add expense: $e');
    }
    _setLoading(false);
    return false;
  }
}
