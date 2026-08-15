import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_pos/models/product_model.dart';
import 'package:frontend_pos/models/member_model.dart';
import 'package:frontend_pos/providers/cart_provider.dart';

/// Distance calculation using Haversine formula
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0; // Radius in meters
  final dLat = (lat2 - lat1) * (pi / 180.0);
  final dLon = (lon2 - lon1) * (pi / 180.0);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) *
      sin(dLon / 2) * sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Product Price Calculation Tests', () {
    test('Calculates final price with discount percent and nominal correctly', () {
      final productWithPercent = ProductModel(
        id: 1,
        companyId: 1,
        name: 'Boba Milk Tea',
        price: 20000,
        isActive: true,
        discountPercent: 10, // 10% of 20000 = 2000 discount -> 18000
      );
      expect(productWithPercent.finalPrice, equals(18000.0));

      final productWithNominal = ProductModel(
        id: 2,
        companyId: 1,
        name: 'Teh Poci',
        price: 5000,
        isActive: true,
        discountNominal: 1000, // 5000 - 1000 = 4000
      );
      expect(productWithNominal.finalPrice, equals(4000.0));

      final productBothDiscounts = ProductModel(
        id: 3,
        companyId: 1,
        name: 'Kopi Susu Gula Aren',
        price: 20000,
        isActive: true,
        discountPercent: 10, // 20000 - 2000 = 18000
        discountNominal: 3000, // 18000 - 3000 = 15000
      );
      expect(productBothDiscounts.finalPrice, equals(15000.0));
    });
  });

  group('Cart and Points Logic Tests', () {
    test('Cart correctly calculates subtotal, discounts, and point redemption', () {
      final cart = CartProvider();

      final item1 = ProductModel(
        id: 101,
        companyId: 1,
        name: 'Matcha Latte',
        price: 25000,
        isActive: true,
      );

      final item2 = ProductModel(
        id: 102,
        companyId: 1,
        name: 'Croissant',
        price: 15000,
        isActive: true,
      );

      // Add to cart
      cart.addToCart(item1);
      cart.addToCart(item2);

      expect(cart.items.length, equals(2));
      expect(cart.totalAmount, equals(40000.0));
      expect(cart.finalAmount, equals(40000.0));

      // Increase quantity of Matcha Latte to 2
      cart.increaseQty(cart.items.first);
      expect(cart.items.first.quantity, equals(2));
      expect(cart.totalAmount, equals(65000.0)); // (25000 * 2) + 15000 = 65000

      // Set member with 100 points
      final member = MemberModel(
        id: 1,
        companyId: 1,
        name: 'Budi Santoso',
        phone: '08123456789',
        memberCode: 'MBR-001',
        points: 100,
      );
      cart.setSelectedMember(member);
      expect(cart.selectedMember?.name, equals('Budi Santoso'));

      // Redeem 50 points with rate Rp 100/point = Rp 5000 discount
      cart.setRedeemPoints(50, 100.0);
      expect(cart.pointsRedeemed, equals(50));
      expect(cart.pointRedeemAmount, equals(5000.0));
      expect(cart.finalAmount, equals(60000.0)); // 65000 - 5000

      // Clear cart
      cart.clearCart();
      expect(cart.items, isEmpty);
      expect(cart.selectedMember, isNull);
      expect(cart.pointsRedeemed, equals(0));
      expect(cart.finalAmount, equals(0.0));
    });
  });

  group('Geofencing & Distance Verification Tests', () {
    test('Correctly determines if user is within or outside branch radius', () {
      // Branch at Monas Jakarta
      const branchLat = -6.175392;
      const branchLng = 106.827153;
      const branchRadius = 100.0; // 100 meters limit

      // Location 1: 30 meters away (inside radius)
      const userInsideLat = -6.175500;
      const userInsideLng = 106.827250;
      final distanceInside = calculateDistance(userInsideLat, userInsideLng, branchLat, branchLng);

      expect(distanceInside <= branchRadius, isTrue,
          reason: 'Distance ($distanceInside m) should be within $branchRadius m');

      // Location 2: 500 meters away (outside radius)
      const userOutsideLat = -6.179800;
      const userOutsideLng = 106.827153;
      final distanceOutside = calculateDistance(userOutsideLat, userOutsideLng, branchLat, branchLng);

      expect(distanceOutside > branchRadius, isTrue,
          reason: 'Distance ($distanceOutside m) should be outside $branchRadius m');
    });
  });
}
