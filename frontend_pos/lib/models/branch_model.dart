import 'package:easy_localization/easy_localization.dart';
class BranchModel {
  final int id;
  final int companyId;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final int activeShiftsCount;

  BranchModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.activeShiftsCount = 0,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      companyId: json['company_id'] is int ? json['company_id'] : (int.tryParse(json['company_id']?.toString() ?? '0') ?? 0),
      name: json['name']?.toString() ?? 'cabang_6'.tr(),
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      radiusMeters: int.tryParse(json['radius_meters']?.toString() ?? '50') ?? 50,
      activeShiftsCount: int.tryParse(json['active_shifts_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'active_shifts_count': activeShiftsCount,
    };
  }
}
