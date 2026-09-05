import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  String? _lastError;
  bool _isLoading = false;
  bool _isInitializing = true;

  UserModel? get user => _user;
  String? get token => _token;
  String? get lastError => _lastError;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isOwner => _user?.isOwner ?? false;

  // --- Paket langganan ---
  //
  // Payload `plan` dikirim server lewat /auth/me (Company::getPlanAttribute) dan
  // berisi paket YANG BERLAKU - kedaluwarsa serta masa tenggang sudah dihitung
  // di sisi server, jadi di sini tidak perlu menghitung ulang apa pun.
  Map<String, dynamic>? get _plan {
    final raw = _user?.company?['plan'];
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  bool get hasPlanInfo => _plan != null;
  String get planCode => _plan?['code']?.toString() ?? 'free';
  String get planName => _plan?['name']?.toString() ?? '';
  String get planStatus => _plan?['status']?.toString() ?? 'active';
  bool get isPremiumPlan => planCode != 'free';
  bool get isFoundingMember => _plan?['is_founding_member'] == true;

  DateTime? get planExpiresAt {
    final raw = _plan?['expires_at'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  /// Profil yang tersimpan di cache dari versi lama aplikasi belum punya payload
  /// `plan`. Dalam keadaan itu UI sengaja TIDAK mengunci apa pun - server tetap
  /// menjadi penegak sebenarnya, dan mengunci berdasarkan data yang tidak
  /// diketahui hanya akan membuat aplikasi terasa rusak setelah pembaruan.
  bool hasFeature(String feature) {
    final plan = _plan;
    if (plan == null) return true;
    final features = plan['features'];
    return features is List && features.contains(feature);
  }

  /// Batas paket untuk sebuah kunci. `null` berarti tak terbatas.
  int? planLimit(String key) {
    final limits = _plan?['limits'];
    if (limits is! Map) return null;
    final value = limits[key];
    return value == null ? null : int.tryParse(value.toString());
  }

  bool get isReservationEnabled => (_user?.company?['is_reservation_enabled'] == 1 || _user?.company?['is_reservation_enabled'] == true) && hasFeature('reservation');
  String get reservationDescription => _user?.company?['reservation_description']?.toString() ?? '';
  bool get isQrMenuEnabled => (_user?.company?['is_qr_menu_enabled'] == 1 || _user?.company?['is_qr_menu_enabled'] == true) && hasFeature('qr_menu');
  String get qrMenuDescription => _user?.company?['qr_menu_description']?.toString() ?? '';
  bool get isKdsEnabled => (_user?.company?['is_kds_enabled'] == 1 || _user?.company?['is_kds_enabled'] == true) && hasFeature('kds');
  bool get isMembershipEnabled => (_user?.company?['is_membership_enabled'] == 1 || _user?.company?['is_membership_enabled'] == true) && hasFeature('membership');
  bool get isPointsEnabled => (_user?.company?['is_points_enabled'] == null || _user?.company?['is_points_enabled'] == 1 || _user?.company?['is_points_enabled'] == true) && hasFeature('points');
  double get pointEarningAmount => double.tryParse(_user?.company?['point_earning_amount']?.toString() ?? '1000') ?? 1000.0;
  double get pointRedeemRate => double.tryParse(_user?.company?['point_redeem_rate']?.toString() ?? '1') ?? 1.0;
  double get defaultMemberDiscountPercent => double.tryParse(_user?.company?['default_member_discount_percent']?.toString() ?? (_user?.company?['member_default_discount']?.toString() ?? '0')) ?? 0.0;
  String get companySlug => _user?.company?['slug']?.toString() ?? '';
  bool get isProductImageEnabled => (_user?.company?['is_product_image_enabled'] == null || _user?.company?['is_product_image_enabled'] == 1 || _user?.company?['is_product_image_enabled'] == true) && hasFeature('product_image');

  bool get canAccessPos => _user?.canAccessPos ?? true;
  bool get canAccessStock => _user?.canAccessStock ?? false;
  bool get canAccessReservations => isReservationEnabled && (_user?.canAccessReservations ?? false);
  bool get canAccessExpenses => _user?.canAccessExpenses ?? false;
  
  // Web application Client ID dari Firebase / Google Cloud Console (zenvi-erp)
  static const String _serverClientId = '919665567596-b0lf3pcf00273dc2n98ep0o6oecsd9a7.apps.googleusercontent.com';
  
  // URL API Laravel Anda
  static const String _apiUrl = ApiConfig.baseUrl; 

  AuthProvider() {
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await gsi.GoogleSignIn.instance.initialize(
        serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
      );
    } catch (e) {
      debugPrint('Error initializing GoogleSignIn: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final cachedUserJson = prefs.getString('cached_user_profile');
      
      if (savedToken != null) {
        _token = savedToken;
        if (cachedUserJson != null) {
          try {
            final Map<String, dynamic> userMap = jsonDecode(cachedUserJson);
            _user = UserModel.fromJson(userMap);
          } catch (e) {
            debugPrint('Error restoring cached user: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error checkLoginStatus: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }

    // Jika ada token, coba refresh data terbaru dari server di background
    if (_token != null) {
      fetchUserData().then((_) {
        NotificationService().syncTokenWithBackend();
      }).catchError((e) {
        debugPrint('Background fetchUserData offline: $e');
      });
    }
  }

  // --- Fungsi Login Menggunakan Google (v7 API) ---
  Future<bool> loginWithGoogle({String? bypassRole}) async {
    bypassRole ??= 'Owner';
    _lastError = null;
    _setLoading(true);
    try {
      final gsi.GoogleSignInAccount googleUser = await gsi.GoogleSignIn.instance.authenticate(scopeHint: ['email']);

      final auth = googleUser.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        throw Exception('Google idToken kosong. Pastikan serverClientId/Web Client ID sudah cocok dengan SHA-1 di Google Cloud / Firebase.');
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/auth/google'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'token': idToken,
          'intended_role': bypassRole,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['data']['access_token'];
        _user = UserModel.fromJson(data['data']['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('cached_user_profile', jsonEncode(_user!.toJson()));
        
        NotificationService().syncTokenWithBackend();
        _lastError = null;
        _setLoading(false);
        return true;
      } else {
        throw Exception('Server backend menolak (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Error Login: $e');
      _lastError = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchUserData() async {
    if (_token == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = (data['data'] != null && data['data']['user'] != null)
            ? data['data']['user']
            : (data['data'] ?? data);
        _user = UserModel.fromJson(userData);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_profile', jsonEncode(_user!.toJson()));
        notifyListeners();
      } else if (response.statusCode == 401) {
        // Token tidak valid atau dicabut di server
        await logout();
      }
    } catch (e) {
      debugPrint('Error fetch user (offline grace): $e');
    }
  }

  Future<bool> updateStoreLocation(double lat, double lng, int radius) async {
    if (_token == null) return false;
    _setLoading(true);
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/companies/location'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
          'radius_meters': radius,
        }),
      );
      _setLoading(false);
      return response.statusCode == 200;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // --- API Tambahan untuk Karyawan ---
  Future<List<Map<String, dynamic>>> fetchPublicCompanies() async {
    if (_token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/companies/public'),
        headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('Error fetch companies: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchPublicBranches(int companyId) async {
    if (_token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/companies/$companyId/branches'),
        headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('Error fetch branches: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> lookupCompanyByCode(String code) async {
    if (_token == null) return null;
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/companies/lookup?code=${Uri.encodeComponent(code.trim().toUpperCase())}'),
        headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'},
      );
      _setLoading(false);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] as Map<String, dynamic>?;
      } else {
        final json = jsonDecode(response.body);
        throw Exception(json['message'] ?? 'Kode toko tidak ditemukan.');
      }
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> joinCompany(int companyId, int branchId) async {
    if (_token == null) return false;
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/companies/join'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'company_id': companyId,
          'branch_id': branchId,
        }),
      );

      if (response.statusCode == 200) {
        await fetchUserData();
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Error join company: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> cancelJoinCompany() async {
    if (_token == null) return false;
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/companies/cancel-join'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );
      _setLoading(false);
      if (response.statusCode == 200) {
        await fetchUserData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error cancel join: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateCompanySetting({
    bool? requireOpname, 
    bool? requireAttendance,
    bool? requireSchedule,
    bool? requireCashDrawerBalance,
    bool? isQrisEnabled,
    bool? isTransferEnabled,
    int? lateToleranceMinutes,
    List<Map<String, String>>? shiftSchedules,
    bool? isQrMenuEnabled,
    bool? isReservationEnabled,
    bool? isMembershipEnabled,
    double? memberDefaultDiscount,
    bool? isPointsEnabled,
    double? pointEarningAmount,
    double? pointRedeemRate,
    String? slug,
    String? qrMenuDescription,
    String? reservationDescription,
    String? name,
    bool? isKdsEnabled,
    bool? isProductImageEnabled,
    String? defaultLanguage,
  }) async {
    if (_token == null || _user == null) return false;
    
    // Optimistic update
    final currentOpname = _user!.company?['require_opname_on_shift_close'];
    final currentAttendance = _user!.company?['require_attendance'];
    final currentSchedule = _user!.company?['require_schedule'];
    final currentCashDrawer = _user!.company?['require_cash_drawer_balance'];
    final currentQris = _user!.company?['is_qris_enabled'];
    final currentTransfer = _user!.company?['is_transfer_enabled'];
    final currentTolerance = _user!.company?['late_tolerance_minutes'];
    final currentShiftSchedules = _user!.company?['shift_schedules'];
    final currentQrMenuEnabled = _user!.company?['is_qr_menu_enabled'];
    final currentReservationEnabled = _user!.company?['is_reservation_enabled'];
    final currentMembershipEnabled = _user!.company?['is_membership_enabled'];
    final currentMemberDefaultDiscount = _user!.company?['default_member_discount_percent'] ?? _user!.company?['member_default_discount'];
    final currentPointsEnabled = _user!.company?['is_points_enabled'];
    final currentPointEarningAmount = _user!.company?['point_earning_amount'];
    final currentPointRedeemRate = _user!.company?['point_redeem_rate'];
    final currentSlug = _user!.company?['slug'];
    final currentQrMenuDesc = _user!.company?['qr_menu_description'];
    final currentReservationDesc = _user!.company?['reservation_description'];
    final currentName = _user!.company?['name'];
    final currentKds = _user!.company?['is_kds_enabled'] == 1;
    final currentProductImage = _user!.company?['is_product_image_enabled'];
    final currentDefaultLanguage = _user!.company?['default_language'];

    if (requireOpname != null) _user!.company?['require_opname_on_shift_close'] = requireOpname ? 1 : 0;
    if (requireAttendance != null) _user!.company?['require_attendance'] = requireAttendance ? 1 : 0;
    if (requireSchedule != null) _user!.company?['require_schedule'] = requireSchedule ? 1 : 0;
    if (requireCashDrawerBalance != null) _user!.company?['require_cash_drawer_balance'] = requireCashDrawerBalance ? 1 : 0;
    if (isQrisEnabled != null) _user!.company?['is_qris_enabled'] = isQrisEnabled ? 1 : 0;
    if (isTransferEnabled != null) _user!.company?['is_transfer_enabled'] = isTransferEnabled ? 1 : 0;
    if (lateToleranceMinutes != null) _user!.company?['late_tolerance_minutes'] = lateToleranceMinutes;
    if (shiftSchedules != null) _user!.company?['shift_schedules'] = shiftSchedules;
    if (isQrMenuEnabled != null) _user!.company?['is_qr_menu_enabled'] = isQrMenuEnabled ? 1 : 0;
    if (isReservationEnabled != null) _user!.company?['is_reservation_enabled'] = isReservationEnabled ? 1 : 0;
    if (isMembershipEnabled != null) _user!.company?['is_membership_enabled'] = isMembershipEnabled ? 1 : 0;
    if (memberDefaultDiscount != null) {
      _user!.company?['default_member_discount_percent'] = memberDefaultDiscount;
      _user!.company?['member_default_discount'] = memberDefaultDiscount;
    }
    if (isPointsEnabled != null) _user!.company?['is_points_enabled'] = isPointsEnabled ? 1 : 0;
    if (pointEarningAmount != null) _user!.company?['point_earning_amount'] = pointEarningAmount;
    if (pointRedeemRate != null) _user!.company?['point_redeem_rate'] = pointRedeemRate;
    if (slug != null) _user!.company?['slug'] = slug;
    if (qrMenuDescription != null) _user!.company?['qr_menu_description'] = qrMenuDescription;
    if (reservationDescription != null) _user!.company?['reservation_description'] = reservationDescription;
    if (name != null) _user!.company?['name'] = name;
    if (isKdsEnabled != null) _user!.company?['is_kds_enabled'] = isKdsEnabled ? 1 : 0;
    if (isProductImageEnabled != null) _user!.company?['is_product_image_enabled'] = isProductImageEnabled ? 1 : 0;
    if (defaultLanguage != null) _user!.company?['default_language'] = defaultLanguage;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (requireOpname != null) body['require_opname_on_shift_close'] = requireOpname;
      if (requireAttendance != null) body['require_attendance'] = requireAttendance;
      if (requireSchedule != null) body['require_schedule'] = requireSchedule;
      if (requireCashDrawerBalance != null) body['require_cash_drawer_balance'] = requireCashDrawerBalance;
      if (isQrisEnabled != null) body['is_qris_enabled'] = isQrisEnabled;
      if (isTransferEnabled != null) body['is_transfer_enabled'] = isTransferEnabled;
      if (lateToleranceMinutes != null) body['late_tolerance_minutes'] = lateToleranceMinutes;
      if (shiftSchedules != null) body['shift_schedules'] = shiftSchedules;
      if (isQrMenuEnabled != null) body['is_qr_menu_enabled'] = isQrMenuEnabled;
      if (isReservationEnabled != null) body['is_reservation_enabled'] = isReservationEnabled;
      if (isMembershipEnabled != null) body['is_membership_enabled'] = isMembershipEnabled;
      if (memberDefaultDiscount != null) {
        body['default_member_discount_percent'] = memberDefaultDiscount;
        body['member_default_discount'] = memberDefaultDiscount;
      }
      if (isPointsEnabled != null) body['is_points_enabled'] = isPointsEnabled;
      if (pointEarningAmount != null) body['point_earning_amount'] = pointEarningAmount;
      if (pointRedeemRate != null) body['point_redeem_rate'] = pointRedeemRate;
      if (slug != null) body['slug'] = slug;
      if (qrMenuDescription != null) body['qr_menu_description'] = qrMenuDescription;
      if (reservationDescription != null) body['reservation_description'] = reservationDescription;
      if (name != null) body['name'] = name;
      if (isKdsEnabled != null) body['is_kds_enabled'] = isKdsEnabled;
      if (isProductImageEnabled != null) body['is_product_image_enabled'] = isProductImageEnabled;
      if (defaultLanguage != null) body['default_language'] = defaultLanguage;

      final response = await http.post(
        Uri.parse('$_apiUrl/companies/settings'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      debugPrint('updateCompanySetting response: ${response.statusCode} -> ${response.body}');
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['data'] != null && _user != null) {
          _user!.company?.addAll(Map<String, dynamic>.from(resData['data']));
          notifyListeners();
        } else {
          await fetchUserData();
        }
        return true;
      }
      // Permintaan ini memakai `http` langsung, bukan ApiClient, jadi 403 karena
      // paket harus dikenali di sini. Tanpa ini pembatalan optimistic update di
      // bawah berjalan diam-diam dan sakelarnya terlihat macet tanpa sebab.
      ApiClient.inspect(response);
      // Revert optimistic update on fail
      _user!.company?['require_opname_on_shift_close'] = currentOpname;
      _user!.company?['require_attendance'] = currentAttendance;
      _user!.company?['require_schedule'] = currentSchedule;
      _user!.company?['require_cash_drawer_balance'] = currentCashDrawer;
      _user!.company?['is_qris_enabled'] = currentQris;
      _user!.company?['is_transfer_enabled'] = currentTransfer;
      _user!.company?['late_tolerance_minutes'] = currentTolerance;
      _user!.company?['shift_schedules'] = currentShiftSchedules;
      _user!.company?['is_qr_menu_enabled'] = currentQrMenuEnabled;
      _user!.company?['is_reservation_enabled'] = currentReservationEnabled;
      _user!.company?['is_membership_enabled'] = currentMembershipEnabled;
      _user!.company?['default_member_discount_percent'] = currentMemberDefaultDiscount;
      _user!.company?['member_default_discount'] = currentMemberDefaultDiscount;
      _user!.company?['is_points_enabled'] = currentPointsEnabled;
      _user!.company?['point_earning_amount'] = currentPointEarningAmount;
      _user!.company?['point_redeem_rate'] = currentPointRedeemRate;
      _user!.company?['slug'] = currentSlug;
      _user!.company?['qr_menu_description'] = currentQrMenuDesc;
      _user!.company?['reservation_description'] = currentReservationDesc;
      _user!.company?['name'] = currentName;
      _user!.company?['is_kds_enabled'] = currentKds ? 1 : 0;
      _user!.company?['is_product_image_enabled'] = currentProductImage;
      _user!.company?['default_language'] = currentDefaultLanguage;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('updateCompanySetting error: $e');
      // Revert optimistic update on fail
      _user!.company?['require_opname_on_shift_close'] = currentOpname;
      _user!.company?['require_attendance'] = currentAttendance;
      _user!.company?['require_schedule'] = currentSchedule;
      _user!.company?['require_cash_drawer_balance'] = currentCashDrawer;
      _user!.company?['is_qris_enabled'] = currentQris;
      _user!.company?['is_transfer_enabled'] = currentTransfer;
      _user!.company?['late_tolerance_minutes'] = currentTolerance;
      _user!.company?['shift_schedules'] = currentShiftSchedules;
      _user!.company?['is_qr_menu_enabled'] = currentQrMenuEnabled;
      _user!.company?['is_reservation_enabled'] = currentReservationEnabled;
      _user!.company?['is_membership_enabled'] = currentMembershipEnabled;
      _user!.company?['default_member_discount_percent'] = currentMemberDefaultDiscount;
      _user!.company?['member_default_discount'] = currentMemberDefaultDiscount;
      _user!.company?['is_points_enabled'] = currentPointsEnabled;
      _user!.company?['point_earning_amount'] = currentPointEarningAmount;
      _user!.company?['point_redeem_rate'] = currentPointRedeemRate;
      _user!.company?['slug'] = currentSlug;
      _user!.company?['qr_menu_description'] = currentQrMenuDesc;
      _user!.company?['reservation_description'] = currentReservationDesc;
      _user!.company?['name'] = currentName;
      _user!.company?['is_kds_enabled'] = currentKds ? 1 : 0;
      _user!.company?['is_product_image_enabled'] = currentProductImage;
      _user!.company?['default_language'] = currentDefaultLanguage;
      _user!.company?['late_tolerance_minutes'] = currentTolerance;
      _user!.company?['shift_schedules'] = currentShiftSchedules;
      _user!.company?['is_qr_menu_enabled'] = currentQrMenuEnabled;
      _user!.company?['is_reservation_enabled'] = currentReservationEnabled;
      _user!.company?['is_membership_enabled'] = currentMembershipEnabled;
      _user!.company?['default_member_discount_percent'] = currentMemberDefaultDiscount;
      _user!.company?['member_default_discount'] = currentMemberDefaultDiscount;
      _user!.company?['is_points_enabled'] = currentPointsEnabled;
      _user!.company?['point_earning_amount'] = currentPointEarningAmount;
      _user!.company?['point_redeem_rate'] = currentPointRedeemRate;
      _user!.company?['slug'] = currentSlug;
      _user!.company?['qr_menu_description'] = currentQrMenuDesc;
      _user!.company?['reservation_description'] = currentReservationDesc;
      _user!.company?['name'] = currentName;
      _user!.company?['is_kds_enabled'] = currentKds ? 1 : 0;
      _user!.company?['default_language'] = currentDefaultLanguage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadCompanyLogo(File imageFile) async {
    if (_token == null || _user == null) return false;
    _setLoading(true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiUrl/companies/logo'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      });
      request.files.add(
        await http.MultipartFile.fromPath('logo', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('uploadCompanyLogo response: ${response.statusCode} -> ${response.body}');
      
      if (response.statusCode == 200) {
        await fetchUserData();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint('uploadCompanyLogo error: $e');
    }
    _setLoading(false);
    return false;
  }

  Future<bool> removeCompanyLogo() async {
    if (_token == null || _user == null) return false;
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/companies/logo'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'remove_logo': true}),
      );
      debugPrint('removeCompanyLogo response: ${response.statusCode} -> ${response.body}');
      if (response.statusCode == 200) {
        await fetchUserData();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint('removeCompanyLogo error: $e');
    }
    _setLoading(false);
    return false;
  }

  Future<bool> createCompany(String companyName, {bool isKdsEnabled = false}) async {
    if (_token == null || _user == null) return false;
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/companies'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': companyName,
          'is_kds_enabled': isKdsEnabled,
        }),
      );

      if (response.statusCode == 201) {
        // Company created, fetch user data again to get updated company_id
        await fetchUserData();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint('Error create company: $e');
    }
    
    _setLoading(false);
    return false;
  }

  Future<bool> updateCompanyName(String newName) async {
    return updateCompanySetting(name: newName);
  }

  Future<List<Map<String, dynamic>>> fetchPendingEmployees() async {
    if (_token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/companies/employees/pending'),
        headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('Error fetch pending employees: $e');
    }
    return [];
  }

  Future<bool> approveEmployee(int employeeId, {String? jobTitle, Map<String, dynamic>? permissions}) async {
    if (_token == null) return false;
    _setLoading(true);
    try {
      final body = <String, dynamic>{};
      if (jobTitle != null) body['job_title'] = jobTitle;
      if (permissions != null) body['permissions'] = permissions;

      final response = await http.post(
        Uri.parse('$_apiUrl/companies/employees/$employeeId/approve'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      _setLoading(false);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error approve employee: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateEmployeePermissions(int employeeId, {String? jobTitle, required Map<String, dynamic> permissions}) async {
    if (_token == null) return false;
    _setLoading(true);
    try {
      final body = <String, dynamic>{
        'permissions': permissions,
      };
      if (jobTitle != null) body['job_title'] = jobTitle;

      final response = await http.post(
        Uri.parse('$_apiUrl/companies/employees/$employeeId/permissions'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        if (_user != null && _user!.id == employeeId) {
          await fetchUserData();
        }
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Error update employee permissions: $e');
      _setLoading(false);
      return false;
    }
  }

  List<Map<String, dynamic>> _activeEmployees = [];
  List<Map<String, dynamic>> get activeEmployees => _activeEmployees;

  Future<List<Map<String, dynamic>>> fetchActiveEmployees() async {
    if (_token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/companies/employees/active'),
        headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _activeEmployees = List<Map<String, dynamic>>.from(data);
        notifyListeners();
        return _activeEmployees;
      }
    } catch (e) {
      debugPrint('Error fetch active employees: $e');
    }
    return [];
  }

  Future<bool> removeEmployee(int employeeId) async {
    if (_token == null) return false;
    _setLoading(true);
    try {
      final response = await http.delete(
        Uri.parse('$_apiUrl/companies/employees/$employeeId'),
        headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'},
      );
      _setLoading(false);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error remove employee: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    // Unregister FCM token on logout
    await NotificationService().unregisterTokenOnLogout();

    // Logout dari server (Opsional)
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('$_apiUrl/logout'),
          headers: {'Authorization': 'Bearer $_token'},
        );
      } catch (_) {}
    }

    // Hapus data lokal
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('cached_user_profile');
    await prefs.remove('cached_active_shift');
    
    await gsi.GoogleSignIn.instance.signOut();
    notifyListeners();
  }
}
