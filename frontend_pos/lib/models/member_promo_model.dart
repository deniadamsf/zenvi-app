import 'dart:convert';
import 'product_model.dart';

class MemberPromoModel {
  final int id;
  final int companyId;
  final String name;
  final String? description;
  final String discountType; // 'percent', 'nominal', 'fixed_price'
  final double discountValue;
  final double minPurchase;
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final List<ProductModel> products;
  final List<int> productIds;

  MemberPromoModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minPurchase = 0.0,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.products = const [],
    this.productIds = const [],
  });

  factory MemberPromoModel.fromJson(Map<String, dynamic> json) {
    List<ProductModel> productList = [];
    List<int> pIds = [];

    if (json['products'] is List) {
      productList = (json['products'] as List)
          .map((p) => ProductModel.fromJson(p))
          .toList();
      pIds = productList.map((p) => p.id).toList();
    } else if (json['product_ids_json'] != null) {
      try {
        final decoded = jsonDecode(json['product_ids_json'].toString());
        if (decoded is List) {
          pIds = decoded.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList();
        }
      } catch (_) {}
    }

    return MemberPromoModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      companyId: json['company_id'] is int ? json['company_id'] : int.tryParse(json['company_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      discountType: json['discount_type']?.toString() ?? 'percent',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      minPurchase: (json['min_purchase'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      products: productList,
      productIds: pIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_purchase': minPurchase,
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive ? 1 : 0,
      'product_ids_json': jsonEncode(productIds),
    };
  }

  /// Hitung harga setelah diskon member untuk suatu produk
  double calculateDiscountedPrice(double originalPrice) {
    if (discountType == 'percent') {
      final discountAmount = originalPrice * (discountValue / 100);
      return (originalPrice - discountAmount).clamp(0.0, double.infinity);
    } else if (discountType == 'nominal') {
      return (originalPrice - discountValue).clamp(0.0, double.infinity);
    } else if (discountType == 'fixed_price') {
      return discountValue;
    }
    return originalPrice;
  }
}
