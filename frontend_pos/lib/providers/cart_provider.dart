import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../models/member_model.dart';
import '../models/reservation_model.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';
import '../config/api_config.dart';

class CartItem {
  final ProductModel product;
  final String? variantName;
  final double? variantPrice;
  int quantity;

  CartItem({required this.product, this.variantName, this.variantPrice, this.quantity = 1});
  
  double get subtotal => (variantPrice ?? product.finalPrice) * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Member state for current transaction
  MemberModel? _selectedMember;
  double _memberDiscountAmount = 0.0;
  List<dynamic> _activePromos = [];
  int _pointsRedeemed = 0;
  double _pointRedeemAmount = 0.0;

  // Reservation state for current transaction
  ReservationModel? _selectedReservation;

  List<CartItem> get items => _items;
  MemberModel? get selectedMember => _selectedMember;
  double get memberDiscountAmount => _memberDiscountAmount;
  int get pointsRedeemed => _pointsRedeemed;
  double get pointRedeemAmount => _pointRedeemAmount;
  ReservationModel? get selectedReservation => _selectedReservation;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Total setelah dikurangi diskon member dan potongan poin
  double get finalAmount {
    final total = totalAmount - _memberDiscountAmount - _pointRedeemAmount;
    return total < 0 ? 0.0 : total;
  }

  void setRedeemPoints(int points, double pointRate) {
    if (_selectedMember == null || points <= 0 || pointRate <= 0) {
      _pointsRedeemed = 0;
      _pointRedeemAmount = 0.0;
    } else {
      final maxPoints = _selectedMember!.points;
      final actualPoints = points.clamp(0, maxPoints);
      final rawAmount = actualPoints * pointRate;
      final maxDeductible = totalAmount - _memberDiscountAmount;
      if (rawAmount > maxDeductible && maxDeductible > 0) {
        _pointRedeemAmount = maxDeductible;
        _pointsRedeemed = (pointRate > 0 ? (_pointRedeemAmount / pointRate).ceil() : 0).clamp(0, maxPoints);
      } else {
        _pointsRedeemed = actualPoints;
        _pointRedeemAmount = rawAmount.clamp(0.0, maxDeductible > 0 ? maxDeductible : 0.0);
      }
    }
    notifyListeners();
  }

  void clearRedeemPoints() {
    _pointsRedeemed = 0;
    _pointRedeemAmount = 0.0;
    notifyListeners();
  }

  void setSelectedMember(MemberModel? member, {List<dynamic>? activePromos, double? explicitDiscount}) {
    _selectedMember = member;
    _pointsRedeemed = 0;
    _pointRedeemAmount = 0.0;
    if (activePromos != null) {
      _activePromos = activePromos;
    }
    if (explicitDiscount != null) {
      _memberDiscountAmount = explicitDiscount;
    } else {
      _recalculateMemberDiscount();
    }
    notifyListeners();
  }

  void setActivePromos(List<dynamic> activePromos) {
    _activePromos = activePromos;
    if (_selectedMember != null) {
      _recalculateMemberDiscount();
      notifyListeners();
    }
  }

  void _recalculateMemberDiscount() {
    if (_selectedMember == null) {
      _memberDiscountAmount = 0.0;
      return;
    }

    double discount = 0.0;
    final total = totalAmount;

    for (final item in _items) {
      final unitPrice = item.variantPrice ?? item.product.finalPrice;
      final itemTotal = item.subtotal;
      bool promoApplied = false;

      // Cek promo produk khusus member
      for (final rawPromo in _activePromos) {
        // rawPromo can be MemberPromoModel or dynamic map
        final pIds = rawPromo is Map 
            ? (rawPromo['product_ids'] as List? ?? [])
            : (rawPromo.productIds as List<int>? ?? []);
        final minPurchase = rawPromo is Map
            ? (double.tryParse(rawPromo['min_purchase']?.toString() ?? '0') ?? 0.0)
            : (rawPromo.minPurchase as double? ?? 0.0);
        final discountType = rawPromo is Map
            ? rawPromo['discount_type']?.toString() ?? 'percent'
            : rawPromo.discountType as String;
        final discountValue = rawPromo is Map
            ? (double.tryParse(rawPromo['discount_value']?.toString() ?? '0') ?? 0.0)
            : (rawPromo.discountValue as double? ?? 0.0);

        if (pIds.contains(item.product.id) && total >= minPurchase) {
          if (discountType == 'percent') {
            discount += itemTotal * (discountValue / 100);
          } else if (discountType == 'nominal') {
            discount += (discountValue * item.quantity).clamp(0.0, itemTotal);
          } else if (discountType == 'fixed_price') {
            final diff = (unitPrice - discountValue).clamp(0.0, unitPrice);
            discount += diff * item.quantity;
          }
          promoApplied = true;
          break; // Apply 1 promo per item
        }
      }

      // Jika tidak ada promo produk spesifik, gunakan diskon kustom member (jika ada)
      if (!promoApplied && _selectedMember!.customDiscountPercent > 0) {
        discount += itemTotal * (_selectedMember!.customDiscountPercent / 100);
      }
    }

    _memberDiscountAmount = discount.clamp(0.0, total);
  }

  void clearMember() {
    _selectedMember = null;
    _memberDiscountAmount = 0.0;
    _pointsRedeemed = 0;
    _pointRedeemAmount = 0.0;
    notifyListeners();
  }

  void addToCart(ProductModel product, {String? variantName, double? variantPrice}) {
    // Cek apakah sudah ada di keranjang
    final index = _items.indexWhere((item) => item.product.id == product.id && item.variantName == variantName);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product, variantName: variantName, variantPrice: variantPrice));
    }
    if (_selectedMember != null) {
      _recalculateMemberDiscount();
    }
    notifyListeners();
  }

  void increaseQty(CartItem item) {
    item.quantity++;
    if (_selectedMember != null) {
      _recalculateMemberDiscount();
    }
    notifyListeners();
  }

  void decreaseQty(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }
    if (_selectedMember != null) {
      _recalculateMemberDiscount();
    }
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    if (_selectedMember != null) {
      _recalculateMemberDiscount();
    }
    notifyListeners();
  }

  void updateQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      _items.remove(item);
    } else {
      item.quantity = quantity;
    }
    if (_selectedMember != null) {
      _recalculateMemberDiscount();
    }
    notifyListeners();
  }

  void setSelectedReservation(ReservationModel? reservation) {
    _selectedReservation = reservation;
    notifyListeners();
  }

  void clearReservation() {
    _selectedReservation = null;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedMember = null;
    _selectedReservation = null;
    _memberDiscountAmount = 0.0;
    _pointsRedeemed = 0;
    _pointRedeemAmount = 0.0;
    notifyListeners();
  }

  /// Proses Checkout Offline-First
  /// Simpan ke SQLite dulu, sync ke server di background (tidak blocking)
  Future<bool> checkout(
    int currentShiftId, {
    String paymentMethod = 'cash',
    double? cashReceived,
    double? cashChange,
    int? companyId,
    int? userId,
    int? servicedByUserId,
    String? servicedByName,
    int? pointsRedeemed,
    double? pointRedeemAmount,
  }) async {
    if (_items.isEmpty) return false;

    try {
      final orderItems = _items.map((item) => {
        'product_id': item.product.id,
        'variant_name': item.variantName,
        'qty': item.quantity,
        'subtotal': item.subtotal,
      }).toList();

      final actualPointsRedeemed = pointsRedeemed ?? _pointsRedeemed;
      final actualPointRedeemAmount = pointRedeemAmount ?? _pointRedeemAmount;
      final currentReservationId = _selectedReservation?.id;

      // 1. Simpan ke SQLite (SELALU berhasil, tidak butuh internet)
      await _dbHelper.saveOfflineOrder(
        currentShiftId, 
        finalAmount, 
        orderItems,
        paymentMethod: paymentMethod,
        cashReceived: cashReceived,
        cashChange: cashChange,
        companyId: companyId,
        userId: userId,
        servicedByUserId: servicedByUserId,
        servicedByName: servicedByName,
        memberId: _selectedMember?.id,
        memberName: _selectedMember?.name ?? _selectedReservation?.customerName,
        memberPhone: _selectedMember?.phone ?? _selectedReservation?.customerPhone,
        memberDiscountAmount: _memberDiscountAmount,
        pointsRedeemed: actualPointsRedeemed,
        pointRedeemAmount: actualPointRedeemAmount,
      );
      debugPrint('✅ Order ($paymentMethod, staff: $servicedByName, member: ${_selectedMember?.name}, redeemed: $actualPointsRedeemed pts) disimpan ke SQLite (offline)');
      
      // 2. Tandai reservasi selesai jika ada
      if (currentReservationId != null) {
        _completeReservationInBackground(currentReservationId);
      }

      // 3. Bersihkan keranjang
      clearCart();
      
      // 4. Coba sync ke server di BACKGROUND (fire-and-forget)
      //    Tidak perlu await - biarkan berjalan sendiri
      //    Jika gagal, akan di-retry saat koneksi kembali
      SyncService().pushOfflineOrders().then((_) {
        debugPrint('✅ Background sync selesai');
      }).catchError((e) {
        debugPrint('⚠️ Background sync gagal (akan retry nanti): $e');
      });
      
      return true;
    } catch (e) {
      debugPrint('❌ Error Checkout: $e');
      return false;
    }
  }

  void _completeReservationInBackground(int reservationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final url = Uri.parse('${ApiConfig.baseUrl}/reservations/$reservationId/status');
      await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': 'completed'}),
      );
      debugPrint('✅ Reservasi #$reservationId otomatis diselesaikan.');
    } catch (e) {
      debugPrint('⚠️ Gagal auto-complete reservasi: $e');
    }
  }
}

