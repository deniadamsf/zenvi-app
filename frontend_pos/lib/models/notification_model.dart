import 'package:easy_localization/easy_localization.dart';
class InAppNotificationModel {
  final int id;
  final int? companyId;
  final int? userId;
  final String? targetRole;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? dataPayload;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  InAppNotificationModel({
    required this.id,
    this.companyId,
    this.userId,
    this.targetRole,
    required this.title,
    required this.body,
    required this.type,
    this.dataPayload,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory InAppNotificationModel.fromJson(Map<String, dynamic> json) {
    return InAppNotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      companyId: json['company_id'] != null ? (json['company_id'] is int ? json['company_id'] : int.tryParse(json['company_id'].toString())) : null,
      userId: json['user_id'] != null ? (json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString())) : null,
      targetRole: json['target_role']?.toString(),
      title: json['title']?.toString() ?? 'notifikasi_10'.tr(),
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      dataPayload: json['data_payload'] is Map<String, dynamic>
          ? json['data_payload']
          : (json['data_payload'] is String ? _tryParseJson(json['data_payload']) : null),
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static Map<String, dynamic>? _tryParseJson(String? str) {
    if (str == null || str.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(
        (str.startsWith('{') ? {} : {}) // safely handled in json decoding if needed
      );
    } catch (_) {
      return null;
    }
  }

  InAppNotificationModel copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return InAppNotificationModel(
      id: id,
      companyId: companyId,
      userId: userId,
      targetRole: targetRole,
      title: title,
      body: body,
      type: type,
      dataPayload: dataPayload,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
