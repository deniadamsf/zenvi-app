import 'branch_model.dart';

class ShiftModel {
  final int id;
  final int companyId;
  final int userId;
  final String? userName; // fetched from relation
  final double openingBalance;
  final double? closingBalance;
  final DateTime startTime;
  final DateTime? endTime;
  final String? selfieUrl;
  final String status;
  final double? totalRevenue; // fetched from relation
  final double? cashRevenue;
  final double? qrisRevenue;
  final double? transferRevenue;
  final double? expectedCashBalance;
  final BranchModel? branch; // fetched from relation
  final double? totalWorkHours;
  final double? overtimeHours;
  final int? lateMinutes;
  final String? shiftName;

  ShiftModel({
    required this.id,
    required this.companyId,
    required this.userId,
    this.userName,
    required this.openingBalance,
    this.closingBalance,
    required this.startTime,
    this.endTime,
    this.selfieUrl,
    required this.status,
    this.totalRevenue,
    this.cashRevenue,
    this.qrisRevenue,
    this.transferRevenue,
    this.expectedCashBalance,
    this.branch,
    this.totalWorkHours,
    this.overtimeHours,
    this.lateMinutes,
    this.shiftName,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'],
      companyId: json['company_id'],
      userId: json['user_id'],
      userName: json['user']?['name'],
      openingBalance: double.parse(json['opening_balance'].toString()),
      closingBalance: json['closing_balance'] != null ? double.parse(json['closing_balance'].toString()) : null,
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      selfieUrl: json['selfie_url'],
      status: json['status'] ?? 'active',
      totalRevenue: json['total_revenue'] != null ? double.parse(json['total_revenue'].toString()) : null,
      cashRevenue: json['cash_revenue'] != null ? double.parse(json['cash_revenue'].toString()) : null,
      qrisRevenue: json['qris_revenue'] != null ? double.parse(json['qris_revenue'].toString()) : null,
      transferRevenue: json['transfer_revenue'] != null ? double.parse(json['transfer_revenue'].toString()) : null,
      expectedCashBalance: json['expected_cash_balance'] != null ? double.parse(json['expected_cash_balance'].toString()) : null,
      branch: json['branch'] != null ? BranchModel.fromJson(json['branch']) : null,
      totalWorkHours: json['total_work_hours'] != null ? double.parse(json['total_work_hours'].toString()) : null,
      overtimeHours: json['overtime_hours'] != null ? double.parse(json['overtime_hours'].toString()) : null,
      lateMinutes: json['late_minutes'] != null ? int.parse(json['late_minutes'].toString()) : null,
      shiftName: json['shift_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'user_id': userId,
      'user': userName != null ? {'name': userName} : null,
      'opening_balance': openingBalance,
      'closing_balance': closingBalance,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'selfie_url': selfieUrl,
      'status': status,
      'total_revenue': totalRevenue,
      'cash_revenue': cashRevenue,
      'qris_revenue': qrisRevenue,
      'transfer_revenue': transferRevenue,
      'expected_cash_balance': expectedCashBalance,
      'branch': branch?.toJson(),
      'total_work_hours': totalWorkHours,
      'overtime_hours': overtimeHours,
      'late_minutes': lateMinutes,
      'shift_name': shiftName,
    };
  }
}
