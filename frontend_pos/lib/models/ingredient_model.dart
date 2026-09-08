class IngredientModel {
  final int id;
  final int companyId;
  final String name;
  final String unit;
  final double stockQty;
  final double costPerUnit;
  final double minStock;
  final double tolerancePercent;
  final int? branchId;
  final String? branchName;
  // Pivot field used when attached to a product
  final double? amountNeeded;

  IngredientModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.unit,
    required this.stockQty,
    this.costPerUnit = 0.0,
    this.minStock = 5.0,
    required this.tolerancePercent,
    this.branchId,
    this.branchName,
    this.amountNeeded,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    double? pivotAmountNeeded;
    if (json['pivot'] != null && json['pivot']['amount_needed'] != null) {
      pivotAmountNeeded = double.tryParse(json['pivot']['amount_needed'].toString());
    }

    return IngredientModel(
      id: json['id'],
      companyId: json['company_id'],
      name: json['name'],
      unit: json['unit'],
      stockQty: double.tryParse(json['stock_qty'].toString()) ?? 0,
      costPerUnit: double.tryParse(json['cost_per_unit']?.toString() ?? '0') ?? 0.0,
      minStock: double.tryParse(json['min_stock']?.toString() ?? '5') ?? 5.0,
      tolerancePercent: double.tryParse(json['tolerance_percent'].toString()) ?? 0,
      branchId: json['branch_id'] != null ? int.tryParse(json['branch_id'].toString()) : null,
      branchName: json['branch_name'],
      amountNeeded: pivotAmountNeeded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'unit': unit,
      'stock_qty': stockQty,
      'cost_per_unit': costPerUnit,
      'min_stock': minStock,
      'tolerance_percent': tolerancePercent,
      if (branchId != null) 'branch_id': branchId,
      if (branchName != null) 'branch_name': branchName,
      if (amountNeeded != null) 'amount_needed': amountNeeded,
    };
  }
}
