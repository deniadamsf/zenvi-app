import 'user_model.dart';
import 'shift_model.dart';
import 'product_model.dart';

class OrderItemModel {
  final int id;
  final int productId;
  final int qty;
  final double subtotal;
  final ProductModel? product;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.qty,
    required this.subtotal,
    this.product,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] ?? 0,
      productId: map['product_id'] ?? 0,
      qty: map['qty'] ?? 0,
      subtotal: double.tryParse(map['subtotal']?.toString() ?? '0') ?? 0.0,
      product: map['product'] != null ? ProductModel.fromMap(map['product']) : null,
    );
  }
}

class OrderModel {
  final int id;
  final int companyId;
  final int userId;
  final int shiftId;
  final double totalAmount;
  final String paymentMethod;
  final double? cashReceived;
  final double? cashChange;
  final String status;
  final String createdAt;
  final UserModel? user;
  final ShiftModel? shift;
  final List<OrderItemModel> items;
  final int? memberId;
  final String? memberName;
  final String? memberPhone;
  final double? memberDiscountAmount;
  final int? pointsRedeemed;
  final double? pointRedeemAmount;

  OrderModel({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.shiftId,
    required this.totalAmount,
    this.paymentMethod = 'cash',
    this.cashReceived,
    this.cashChange,
    required this.status,
    required this.createdAt,
    this.user,
    this.shift,
    this.items = const [],
    this.memberId,
    this.memberName,
    this.memberPhone,
    this.memberDiscountAmount,
    this.pointsRedeemed,
    this.pointRedeemAmount,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? 0,
      companyId: map['company_id'] ?? 0,
      userId: map['user_id'] ?? 0,
      shiftId: map['shift_id'] ?? 0,
      totalAmount: double.tryParse(map['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: map['payment_method'] ?? 'cash',
      cashReceived: map['cash_received'] != null ? double.tryParse(map['cash_received'].toString()) : null,
      cashChange: map['cash_change'] != null ? double.tryParse(map['cash_change'].toString()) : null,
      status: map['status'] ?? 'pending',
      createdAt: map['created_at'] ?? '',
      user: map['user'] != null ? UserModel.fromJson(map['user']) : null,
      shift: map['shift'] != null ? ShiftModel.fromJson(map['shift']) : null,
      memberId: map['member_id'] != null ? int.tryParse(map['member_id'].toString()) : null,
      memberName: map['member_name']?.toString(),
      memberPhone: map['member_phone']?.toString(),
      memberDiscountAmount: map['member_discount_amount'] != null
          ? double.tryParse(map['member_discount_amount'].toString())
          : null,
      pointsRedeemed: map['points_redeemed'] != null
          ? int.tryParse(map['points_redeemed'].toString())
          : null,
      pointRedeemAmount: map['point_redeem_amount'] != null
          ? double.tryParse(map['point_redeem_amount'].toString())
          : null,
      items: map['items'] != null
          ? List<OrderItemModel>.from(map['items'].map((x) => OrderItemModel.fromMap(x)))
          : [],
    );
  }
}
