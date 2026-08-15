import 'package:easy_localization/easy_localization.dart';
class ExpenseModel {
  final int id;
  final int companyId;
  final int userId;
  final String userName;
  final String expenseType;
  final double amount;
  final String? description;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.userName,
    required this.expenseType,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      companyId: json['company_id'],
      userId: json['user_id'],
      userName: json['user']['name'] ?? 'unknown_7'.tr(),
      expenseType: json['expense_type'],
      amount: double.parse(json['amount'].toString()),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
