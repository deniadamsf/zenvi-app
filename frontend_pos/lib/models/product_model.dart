import 'dart:convert';
import 'ingredient_model.dart';

class ProductModel {
  final int id;
  final int companyId;
  final String name;
  final String? category;
  final double price;
  final bool isActive;
  final String? imageUrl;
  final double discountNominal;
  final double discountPercent;
  final List<IngredientModel> ingredients;
  final List<ProductVariantModel> variants;

  double get finalPrice {
    double afterPercent = price - (price * (discountPercent / 100));
    double afterNominal = afterPercent - discountNominal;
    return afterNominal > 0 ? afterNominal : 0;
  }

  ProductModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.category,
    required this.price,
    required this.isActive,
    this.imageUrl,
    this.discountNominal = 0.0,
    this.discountPercent = 0.0,
    this.ingredients = const [],
    this.variants = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<IngredientModel> parsedIngredients = [];
    if (json['ingredients'] != null) {
      parsedIngredients = (json['ingredients'] as List)
          .map((item) => IngredientModel.fromJson(item))
          .toList();
    }

    List<ProductVariantModel> parsedVariants = [];
    if (json['variants'] != null) {
      parsedVariants = (json['variants'] as List)
          .map((item) => ProductVariantModel.fromJson(item))
          .toList();
    }

    return ProductModel(
      id: json['id'],
      companyId: json['company_id'] ?? 0,
      name: json['name'],
      category: json['category'],
      price: double.parse(json['price'].toString()),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      imageUrl: json['image_url'],
      discountNominal: double.tryParse(json['discount_nominal']?.toString() ?? '0') ?? 0.0,
      discountPercent: double.tryParse(json['discount_percent']?.toString() ?? '0') ?? 0.0,
      ingredients: parsedIngredients,
      variants: parsedVariants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'category': category,
      'price': price,
      'is_active': isActive ? 1 : 0,
      'image_url': imageUrl,
      'discount_nominal': discountNominal,
      'discount_percent': discountPercent,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'category': category,
      'price': price,
      'is_active': isActive ? 1 : 0,
      'image_url': imageUrl,
      'discount_nominal': discountNominal,
      'discount_percent': discountPercent,
      'variants_json': jsonEncode(variants.map((v) => v.toJson()).toList()),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    List<ProductVariantModel> parsedVariants = [];
    // Handle variants from SQLite (variants_json) or API (variants array)
    if (map['variants_json'] != null) {
      try {
        final List<dynamic> decoded = jsonDecode(map['variants_json']);
        parsedVariants = decoded.map((item) => ProductVariantModel.fromJson(item)).toList();
      } catch (e) {
        // ignore errors
      }
    } else if (map['variants'] != null) {
      try {
        parsedVariants = (map['variants'] as List)
            .map((item) => ProductVariantModel.fromJson(item))
            .toList();
      } catch (e) {
        // ignore errors
      }
    }

    return ProductModel(
      id: map['id'],
      companyId: map['company_id'] ?? 0,
      name: map['name'],
      category: map['category'],
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      imageUrl: map['image_url'],
      discountNominal: double.tryParse(map['discount_nominal']?.toString() ?? '0') ?? 0.0,
      discountPercent: double.tryParse(map['discount_percent']?.toString() ?? '0') ?? 0.0,
      variants: parsedVariants,
    );
  }
}

class ProductVariantModel {
  final int? id;
  final String name;
  final double price;
  final bool isActive;

  ProductVariantModel({
    this.id,
    required this.name,
    required this.price,
    this.isActive = true,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'],
      name: json['name'],
      price: double.parse(json['price'].toString()),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'is_active': isActive ? 1 : 0,
    };
  }
}
