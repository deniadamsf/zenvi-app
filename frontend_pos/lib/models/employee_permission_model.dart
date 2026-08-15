import 'package:easy_localization/easy_localization.dart';
class PermissionUserSummary {
  final int id;
  final String name;
  final String email;
  final String role;

  PermissionUserSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory PermissionUserSummary.fromJson(Map<String, dynamic> json) {
    return PermissionUserSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Staff',
    );
  }
}

class PermissionReviewerSummary {
  final int id;
  final String name;

  PermissionReviewerSummary({
    required this.id,
    required this.name,
  });

  factory PermissionReviewerSummary.fromJson(Map<String, dynamic> json) {
    return PermissionReviewerSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class EmployeePermission {
  final int id;
  final int companyId;
  final int userId;
  final String type; // 'leave' or 'late'
  final String permissionDate;
  final String? estimatedArrivalTime;
  final String reason;
  final String? attachmentUrl;
  final bool isAttachmentExpired;
  final String status; // 'pending', 'approved', 'rejected'
  final String typeLabel;
  final String statusLabel;
  final int? reviewedBy;
  final String? reviewedAt;
  final String? rejectionNote;
  final String createdAt;
  final PermissionUserSummary? user;
  final PermissionReviewerSummary? reviewer;

  EmployeePermission({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.type,
    required this.permissionDate,
    this.estimatedArrivalTime,
    required this.reason,
    this.attachmentUrl,
    required this.isAttachmentExpired,
    required this.status,
    required this.typeLabel,
    required this.statusLabel,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionNote,
    required this.createdAt,
    this.user,
    this.reviewer,
  });

  factory EmployeePermission.fromJson(Map<String, dynamic> json) {
    return EmployeePermission(
      id: (json['id'] as num?)?.toInt() ?? 0,
      companyId: (json['company_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'leave',
      permissionDate: json['permission_date']?.toString() ?? '',
      estimatedArrivalTime: json['estimated_arrival_time']?.toString(),
      reason: json['reason']?.toString() ?? '',
      attachmentUrl: json['attachment_url']?.toString(),
      isAttachmentExpired: json['is_attachment_expired'] == true,
      status: json['status']?.toString() ?? 'pending',
      typeLabel: json['type_label']?.toString() ?? (json['type'] == 'late' ? 'Izin Telat Masuk' : 'Izin Libur / Tidak Masuk'),
      statusLabel: json['status_label']?.toString() ?? 'menunggu_persetujuan_20'.tr(),
      reviewedBy: (json['reviewed_by'] as num?)?.toInt(),
      reviewedAt: json['reviewed_at']?.toString(),
      rejectionNote: json['rejection_note']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      user: json['user'] != null ? PermissionUserSummary.fromJson(json['user'] as Map<String, dynamic>) : null,
      reviewer: json['reviewer'] != null ? PermissionReviewerSummary.fromJson(json['reviewer'] as Map<String, dynamic>) : null,
    );
  }
}
