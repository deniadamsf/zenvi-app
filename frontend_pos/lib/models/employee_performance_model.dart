class PerformanceOverviewSummary {
  final int totalEmployees;
  final double totalSales;
  final int totalOrders;
  final int totalShifts;
  final double totalWorkHours;
  final double averageOrderValue;

  PerformanceOverviewSummary({
    required this.totalEmployees,
    required this.totalSales,
    required this.totalOrders,
    required this.totalShifts,
    required this.totalWorkHours,
    required this.averageOrderValue,
  });

  factory PerformanceOverviewSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceOverviewSummary(
      totalEmployees: (json['total_employees'] as num?)?.toInt() ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalShifts: (json['total_shifts'] as num?)?.toInt() ?? 0,
      totalWorkHours: (json['total_work_hours'] as num?)?.toDouble() ?? 0.0,
      averageOrderValue: (json['average_order_value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TopPerformerBadge {
  final int userId;
  final String name;
  final String? role;
  final String badge;
  final String description;
  final String value;
  final String subValue;

  TopPerformerBadge({
    required this.userId,
    required this.name,
    this.role,
    required this.badge,
    required this.description,
    required this.value,
    required this.subValue,
  });

  factory TopPerformerBadge.fromJson(Map<String, dynamic> json) {
    return TopPerformerBadge(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString(),
      badge: json['badge']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      subValue: json['sub_value']?.toString() ?? '',
    );
  }
}

class TopPerformersPodium {
  final TopPerformerBadge? topSales;
  final TopPerformerBadge? mostOrders;
  final TopPerformerBadge? bestAccuracy;
  final TopPerformerBadge? mostHours;
  final TopPerformerBadge? mostPunctual;

  TopPerformersPodium({
    this.topSales,
    this.mostOrders,
    this.bestAccuracy,
    this.mostHours,
    this.mostPunctual,
  });

  factory TopPerformersPodium.fromJson(Map<String, dynamic> json) {
    return TopPerformersPodium(
      topSales: json['top_sales'] != null ? TopPerformerBadge.fromJson(json['top_sales']) : null,
      mostOrders: json['most_orders'] != null ? TopPerformerBadge.fromJson(json['most_orders']) : null,
      bestAccuracy: json['best_accuracy'] != null ? TopPerformerBadge.fromJson(json['best_accuracy']) : null,
      mostHours: json['most_hours'] != null ? TopPerformerBadge.fromJson(json['most_hours']) : null,
      mostPunctual: json['most_punctual'] != null ? TopPerformerBadge.fromJson(json['most_punctual']) : null,
    );
  }
}

class ApprovedLeaveItem {
  final int id;
  final String date;
  final String reason;
  final String? approvedAt;

  ApprovedLeaveItem({
    required this.id,
    required this.date,
    required this.reason,
    this.approvedAt,
  });

  factory ApprovedLeaveItem.fromJson(Map<String, dynamic> json) {
    return ApprovedLeaveItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      approvedAt: json['approved_at']?.toString(),
    );
  }
}

class ShiftSummaryItem {
  final int id;
  final String? startTime;
  final String? endTime;
  final String shiftName;
  final String durationFormatted;
  final double openingBalance;
  final double? closingBalance;
  final double? cashVariance;
  final bool isLate;
  final bool isExcused;
  final String? excuseReason;
  final int lateMinutes;
  final double totalRevenue;
  final String status;

  ShiftSummaryItem({
    required this.id,
    this.startTime,
    this.endTime,
    required this.shiftName,
    required this.durationFormatted,
    required this.openingBalance,
    this.closingBalance,
    this.cashVariance,
    required this.isLate,
    this.isExcused = false,
    this.excuseReason,
    required this.lateMinutes,
    required this.totalRevenue,
    required this.status,
  });

  factory ShiftSummaryItem.fromJson(Map<String, dynamic> json) {
    return ShiftSummaryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      shiftName: json['shift_name']?.toString() ?? 'Shift Reguler',
      durationFormatted: json['duration_formatted']?.toString() ?? '0m',
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0.0,
      closingBalance: (json['closing_balance'] as num?)?.toDouble(),
      cashVariance: (json['cash_variance'] as num?)?.toDouble(),
      isLate: json['is_late'] == true,
      isExcused: json['is_excused'] == true,
      excuseReason: json['excuse_reason']?.toString(),
      lateMinutes: (json['late_minutes'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'closed',
    );
  }
}

class EmployeePerformanceItem {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? jobTitle;
  final double totalSales;
  final int totalOrders;
  final double cashierSales;
  final int cashierOrders;
  final double servicedSales;
  final int servicedOrders;
  final double averageOrderValue;
  final double cashSales;
  final double qrisSales;
  final double transferSales;
  final int totalShifts;
  final int closedShiftsCount;
  final int totalWorkMinutes;
  final double totalWorkHours;
  final double totalCashVariance;
  final int accuracyPercentage;
  final int punctualityPercentage;
  final int onTimeShiftsCount;
  final int lateShiftsCount;
  final int excusedLateShiftsCount;
  final int approvedLeavesCount;
  final List<ApprovedLeaveItem> approvedLeaves;
  final int totalLateMinutes;
  final double salesContributionPercent;
  final List<ShiftSummaryItem> recentShifts;

  EmployeePerformanceItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.jobTitle,
    required this.totalSales,
    required this.totalOrders,
    this.cashierSales = 0,
    this.cashierOrders = 0,
    this.servicedSales = 0,
    this.servicedOrders = 0,
    required this.averageOrderValue,
    required this.cashSales,
    required this.qrisSales,
    required this.transferSales,
    required this.totalShifts,
    required this.closedShiftsCount,
    required this.totalWorkMinutes,
    required this.totalWorkHours,
    required this.totalCashVariance,
    required this.accuracyPercentage,
    required this.punctualityPercentage,
    required this.onTimeShiftsCount,
    required this.lateShiftsCount,
    this.excusedLateShiftsCount = 0,
    this.approvedLeavesCount = 0,
    this.approvedLeaves = const [],
    required this.totalLateMinutes,
    required this.salesContributionPercent,
    required this.recentShifts,
  });

  factory EmployeePerformanceItem.fromJson(Map<String, dynamic> json) {
    return EmployeePerformanceItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Staff',
      jobTitle: json['job_title']?.toString() ?? json['role']?.toString() ?? 'Staff',
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      cashierSales: (json['cashier_sales'] as num?)?.toDouble() ?? 0.0,
      cashierOrders: (json['cashier_orders'] as num?)?.toInt() ?? 0,
      servicedSales: (json['serviced_sales'] as num?)?.toDouble() ?? 0.0,
      servicedOrders: (json['serviced_orders'] as num?)?.toInt() ?? 0,
      averageOrderValue: (json['average_order_value'] as num?)?.toDouble() ?? 0.0,
      cashSales: (json['cash_sales'] as num?)?.toDouble() ?? 0.0,
      qrisSales: (json['qris_sales'] as num?)?.toDouble() ?? 0.0,
      transferSales: (json['transfer_sales'] as num?)?.toDouble() ?? 0.0,
      totalShifts: (json['total_shifts'] as num?)?.toInt() ?? 0,
      closedShiftsCount: (json['closed_shifts_count'] as num?)?.toInt() ?? 0,
      totalWorkMinutes: (json['total_work_minutes'] as num?)?.toInt() ?? 0,
      totalWorkHours: (json['total_work_hours'] as num?)?.toDouble() ?? 0.0,
      totalCashVariance: (json['total_cash_variance'] as num?)?.toDouble() ?? 0.0,
      accuracyPercentage: (json['accuracy_percentage'] as num?)?.toInt() ?? 100,
      punctualityPercentage: (json['punctuality_percentage'] as num?)?.toInt() ?? 100,
      onTimeShiftsCount: (json['on_time_shifts_count'] as num?)?.toInt() ?? 0,
      lateShiftsCount: (json['late_shifts_count'] as num?)?.toInt() ?? 0,
      excusedLateShiftsCount: (json['excused_late_shifts_count'] as num?)?.toInt() ?? 0,
      approvedLeavesCount: (json['approved_leaves_count'] as num?)?.toInt() ?? 0,
      approvedLeaves: (json['approved_leaves'] as List<dynamic>?)
              ?.map((item) => ApprovedLeaveItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalLateMinutes: (json['total_late_minutes'] as num?)?.toInt() ?? 0,
      salesContributionPercent: (json['sales_contribution_percent'] as num?)?.toDouble() ?? 0.0,
      recentShifts: (json['recent_shifts'] as List<dynamic>?)
              ?.map((item) => ShiftSummaryItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EmployeePerformanceReport {
  final String period;
  final String periodLabel;
  final PerformanceOverviewSummary summary;
  final TopPerformersPodium topPerformers;
  final List<EmployeePerformanceItem> employees;

  EmployeePerformanceReport({
    required this.period,
    required this.periodLabel,
    required this.summary,
    required this.topPerformers,
    required this.employees,
  });

  factory EmployeePerformanceReport.fromJson(Map<String, dynamic> json) {
    return EmployeePerformanceReport(
      period: json['period']?.toString() ?? 'this_month',
      periodLabel: json['period_label']?.toString() ?? '',
      summary: PerformanceOverviewSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
      topPerformers: TopPerformersPodium.fromJson(json['top_performers'] as Map<String, dynamic>? ?? {}),
      employees: (json['employees'] as List<dynamic>?)
              ?.map((item) => EmployeePerformanceItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
