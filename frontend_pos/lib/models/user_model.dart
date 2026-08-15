import 'dart:convert';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? jobTitle;
  final Map<String, dynamic>? permissions;
  final int? companyId;
  final bool isApproved;
  final Map<String, dynamic>? company;
  final Map<String, dynamic>? branch;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.jobTitle,
    this.permissions,
    this.companyId,
    required this.isApproved,
    this.company,
    this.branch,
  });

  bool get isOwner => role.toLowerCase() == 'owner';

  bool _checkPermission(String key, {bool defaultValue = false}) {
    if (isOwner) return true;
    if (permissions != null && permissions!.containsKey(key)) {
      final val = permissions![key];
      if (val == true || val == 1 || val == '1' || val == 'true') return true;
      if (val == false || val == 0 || val == '0' || val == 'false') return false;
    }

    final title = (jobTitle ?? '').toLowerCase();
    if (key == 'can_access_pos') {
      if (title.contains('kapster') || title.contains('terapis') || title.contains('dapur') || title.contains('gudang') || title.contains('staff')) {
        return false;
      }
      return true;
    }
    if (key == 'can_access_stock') {
      return title.contains('dapur') || title.contains('barista') || title.contains('gudang') || title.contains('koki');
    }
    if (key == 'can_access_reservations') {
      if (title.contains('dapur') || title.contains('koki') || title.contains('gudang')) {
        return false;
      }
      return true;
    }
    if (key == 'can_access_expenses') {
      return title.contains('kasir') || title.contains('admin');
    }
    if (key == 'can_access_kds') {
      return title.contains('dapur') || title.contains('koki') || title.contains('barista');
    }

    return defaultValue;
  }

  bool get canAccessPos => _checkPermission('can_access_pos', defaultValue: true);
  bool get canAccessStock => _checkPermission('can_access_stock', defaultValue: false);
  bool get canAccessReservations => _checkPermission('can_access_reservations', defaultValue: false);
  bool get canAccessExpenses => _checkPermission('can_access_expenses', defaultValue: false);
  bool get canAccessKds => _checkPermission('can_access_kds', defaultValue: false);

  int? get branchId => branch != null ? (branch!['id'] is int ? branch!['id'] as int : int.tryParse(branch!['id']?.toString() ?? '')) : null;
  String? get branchName => branch != null ? branch!['name']?.toString() : null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedPermissions;
    if (json['permissions'] != null) {
      if (json['permissions'] is Map) {
        parsedPermissions = Map<String, dynamic>.from(json['permissions']);
      } else if (json['permissions'] is String) {
        try {
          final decoded = jsonDecode(json['permissions']);
          if (decoded is Map) {
            parsedPermissions = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
    }

    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Cashier',
      jobTitle: json['job_title'],
      permissions: parsedPermissions,
      companyId: json['company_id'] is int ? json['company_id'] : int.tryParse(json['company_id']?.toString() ?? ''),
      isApproved: json['is_approved'] == 1 || json['is_approved'] == true || json['is_approved'] == '1',
      company: json['company'] != null && json['company'] is Map ? Map<String, dynamic>.from(json['company']) : null,
      branch: json['branch'] != null && json['branch'] is Map ? Map<String, dynamic>.from(json['branch']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'job_title': jobTitle,
      'permissions': permissions,
      'company_id': companyId,
      'is_approved': isApproved ? 1 : 0,
      'company': company,
      'branch': branch,
    };
  }
}

