class ReservationModel {
  final int id;
  final int companyId;
  final int? branchId;
  final String customerName;
  final String customerPhone;
  final String reservationDate; // YYYY-MM-DD
  final String reservationTime; // HH:mm
  final int numberOfPeople;
  final String? serviceNames;
  final String? notes;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final int? assignedStaffId;
  final DateTime createdAt;
  final Map<String, dynamic>? branch;
  final Map<String, dynamic>? assignedStaff;

  ReservationModel({
    required this.id,
    required this.companyId,
    this.branchId,
    required this.customerName,
    required this.customerPhone,
    required this.reservationDate,
    required this.reservationTime,
    required this.numberOfPeople,
    this.serviceNames,
    this.notes,
    required this.status,
    this.assignedStaffId,
    required this.createdAt,
    this.branch,
    this.assignedStaff,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      companyId: json['company_id'] is int ? json['company_id'] : int.tryParse(json['company_id'].toString()) ?? 0,
      branchId: json['branch_id'] != null ? (json['branch_id'] is int ? json['branch_id'] : int.tryParse(json['branch_id'].toString())) : null,
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      reservationDate: json['reservation_date'] ?? '',
      reservationTime: json['reservation_time'] ?? '',
      numberOfPeople: json['number_of_people'] is int ? json['number_of_people'] : int.tryParse(json['number_of_people'].toString()) ?? 1,
      serviceNames: json['service_names'],
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      assignedStaffId: json['assigned_staff_id'] != null ? (json['assigned_staff_id'] is int ? json['assigned_staff_id'] : int.tryParse(json['assigned_staff_id'].toString())) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      branch: json['branch'] is Map<String, dynamic> ? json['branch'] : null,
      assignedStaff: json['assigned_staff'] is Map<String, dynamic> ? json['assigned_staff'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'branch_id': branchId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'reservation_date': reservationDate,
      'reservation_time': reservationTime,
      'number_of_people': numberOfPeople,
      'service_names': serviceNames,
      'notes': notes,
      'status': status,
      'assigned_staff_id': assignedStaffId,
    };
  }

  ReservationModel copyWith({
    int? id,
    int? companyId,
    int? branchId,
    String? customerName,
    String? customerPhone,
    String? reservationDate,
    String? reservationTime,
    int? numberOfPeople,
    String? serviceNames,
    String? notes,
    String? status,
    int? assignedStaffId,
    DateTime? createdAt,
    Map<String, dynamic>? branch,
    Map<String, dynamic>? assignedStaff,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      branchId: branchId ?? this.branchId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      reservationDate: reservationDate ?? this.reservationDate,
      reservationTime: reservationTime ?? this.reservationTime,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      serviceNames: serviceNames ?? this.serviceNames,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      createdAt: createdAt ?? this.createdAt,
      branch: branch ?? this.branch,
      assignedStaff: assignedStaff ?? this.assignedStaff,
    );
  }
}
