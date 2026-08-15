class MemberModel {
  final int id;
  final int companyId;
  final String memberCode;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? birthDate;
  final int points;
  final double totalSpend;
  final int totalTransactions;
  final double customDiscountPercent;
  final bool isActive;
  final String? notes;
  final String? createdAt;

  MemberModel({
    required this.id,
    required this.companyId,
    required this.memberCode,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.birthDate,
    this.points = 0,
    this.totalSpend = 0.0,
    this.totalTransactions = 0,
    this.customDiscountPercent = 0.0,
    this.isActive = true,
    this.notes,
    this.createdAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      companyId: json['company_id'] is int ? json['company_id'] : int.tryParse(json['company_id']?.toString() ?? '0') ?? 0,
      memberCode: json['member_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      birthDate: json['birth_date']?.toString(),
      points: json['points'] is int ? json['points'] : int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      totalSpend: (json['total_spend'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: json['total_transactions'] is int ? json['total_transactions'] : int.tryParse(json['total_transactions']?.toString() ?? '0') ?? 0,
      customDiscountPercent: (json['custom_discount_percent'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'member_code': memberCode,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'birth_date': birthDate,
      'points': points,
      'total_spend': totalSpend,
      'total_transactions': totalTransactions,
      'custom_discount_percent': customDiscountPercent,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  MemberModel copyWith({
    int? id,
    int? companyId,
    String? memberCode,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? birthDate,
    int? points,
    double? totalSpend,
    int? totalTransactions,
    double? customDiscountPercent,
    bool? isActive,
    String? notes,
    String? createdAt,
  }) {
    return MemberModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      memberCode: memberCode ?? this.memberCode,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      points: points ?? this.points,
      totalSpend: totalSpend ?? this.totalSpend,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      customDiscountPercent: customDiscountPercent ?? this.customDiscountPercent,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
