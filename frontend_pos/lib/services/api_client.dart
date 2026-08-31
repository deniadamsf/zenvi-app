import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../widgets/premium_gate.dart';
import 'notification_service.dart';

/// Pembungkus HTTP terpusat.
///
/// Sebelum ini setiap provider memanggil `package:http` langsung tanpa klien
/// bersama, sehingga penanganan respons terkunci harus ditambal satu per satu di
/// belasan tempat. Semua permintaan yang lewat sini otomatis:
///
///  - menyisipkan header Authorization & Accept
///  - mengenali balasan 403 `feature_locked` / `plan_limit_reached` dan
///    memunculkan tawaran upgrade, bukan pesan error yang membingungkan
///
/// Server tetap penegak sebenarnya; ini murni lapisan tampilan.
class ApiClient {
  static const String _baseUrl = ApiConfig.baseUrl;

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await _token();
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalized');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  static Future<http.Response> get(String path, {Map<String, dynamic>? query}) async {
    final response = await http.get(_uri(path, query), headers: await _headers());
    inspect(response);
    return response;
  }

  static Future<http.Response> post(String path, {Object? body}) async {
    final response = await http.post(
      _uri(path),
      headers: await _headers(json: true),
      body: body == null ? null : jsonEncode(body),
    );
    inspect(response);
    return response;
  }

  static Future<http.Response> put(String path, {Object? body}) async {
    final response = await http.put(
      _uri(path),
      headers: await _headers(json: true),
      body: body == null ? null : jsonEncode(body),
    );
    inspect(response);
    return response;
  }

  static Future<http.Response> delete(String path) async {
    final response = await http.delete(_uri(path), headers: await _headers());
    inspect(response);
    return response;
  }

  /// Mengenali respons terkunci dan memunculkan tawaran upgrade.
  ///
  /// Bisa dipanggil langsung oleh provider yang belum memakai pembungkus di atas,
  /// sehingga migrasinya bisa bertahap tanpa mengubah 15 provider sekaligus.
  /// Mengembalikan true kalau respons memang terkunci.
  static bool inspect(http.Response response) {
    final locked = parseLock(response);
    if (locked == null) return false;

    // navigatorKey sudah dipasang di MaterialApp (main.dart) dan dipakai
    // NotificationService, jadi sheet bisa muncul dari lapisan mana pun -
    // termasuk dari provider yang tidak punya BuildContext.
    final context = NotificationService.navigatorKey.currentContext;
    if (context != null) {
      showPremiumUpsellSheet(context, locked);
    }
    return true;
  }

  /// Membaca body 403 bertipe dari server. Mengembalikan null kalau respons ini
  /// bukan soal paket (403 biasa karena bukan Owner, misalnya).
  static PremiumLock? parseLock(http.Response response) {
    if (response.statusCode != 403) return null;
    try {
      final body = jsonDecode(response.body);
      if (body is! Map) return null;
      final error = body['error']?.toString();
      if (error != 'feature_locked' && error != 'plan_limit_reached') return null;
      return PremiumLock(
        isLimit: error == 'plan_limit_reached',
        feature: body['feature']?.toString(),
        limitKey: body['limit']?.toString(),
        current: body['current'] is num ? (body['current'] as num).toInt() : null,
        max: body['max'] is num ? (body['max'] as num).toInt() : null,
        requiredPlan: body['required_plan']?.toString(),
        message: body['message']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
