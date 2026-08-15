import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/order_model.dart';
import '../../../models/member_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/printer_service.dart';

class ReceiptWidget extends StatelessWidget {
  final OrderModel? order;
  final List<dynamic>? items;
  final double? totalAmount;
  final String? receiptNumber;
  final DateTime? transactionTime;
  final bool isOffline;
  final String? paymentMethod;
  final double? cashReceived;
  final double? cashChange;
  final MemberModel? member;
  final String? memberName;
  final String? memberPhone;
  final double? memberDiscountAmount;
  final int? pointsRedeemed;
  final double? pointRedeemAmount;

  final String? storeName;
  final String? storeLocation;
  final String? storePhone;
  final String? cashierName;
  final String? logoUrl;

  const ReceiptWidget({
    super.key, 
    this.order, 
    this.items,
    this.totalAmount,
    this.receiptNumber,
    this.transactionTime,
    this.isOffline = false,
    this.paymentMethod,
    this.cashReceived,
    this.cashChange,
    this.member,
    this.memberName,
    this.memberPhone,
    this.memberDiscountAmount,
    this.pointsRedeemed,
    this.pointRedeemAmount,
    this.storeName,
    this.storeLocation,
    this.storePhone,
    this.cashierName,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Ambil nama toko dan logo dari data company owner (aman jika di luar provider context)
    AuthProvider? authProvider;
    try {
      authProvider = Provider.of<AuthProvider>(context, listen: false);
    } catch (_) {
      authProvider = null;
    }
    final company = authProvider?.user?.company;
    final resolvedStoreName = storeName ?? company?['name'] ?? 'toko_saya_9'.tr(context: context);
    final resolvedStoreLocation = storeLocation ?? company?['location']?.toString() ?? '';
    final resolvedStorePhone = storePhone ?? company?['phone']?.toString() ?? '';
    final resolvedCashierName = cashierName ?? authProvider?.user?.name ?? 'kasir_5'.tr(context: context);
    
    // Logo Toko (Nullable)
    String? resolvedLogoUrl = logoUrl ?? company?['logo_url']?.toString();
    if ((resolvedLogoUrl == null || resolvedLogoUrl.isEmpty) && company?['logo_path'] != null) {
      final path = company!['logo_path'].toString();
      resolvedLogoUrl = path.startsWith('http') ? path : 'https://zenvi.cellanoma.my.id/uploads/logos/$path';
    }

    final String receiptNo = order != null 
        ? (isOffline ? "Offline" : order!.id.toString())
        : (receiptNumber ?? 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}');
        
    final DateTime receiptTime = order != null
        ? (DateTime.tryParse(order!.createdAt)?.toLocal() ?? DateTime.now())
        : (transactionTime ?? DateTime.now());
        
    final double grandTotal = order?.totalAmount ?? (totalAmount ?? 0.0);
    final String activeMethod = order?.paymentMethod ?? paymentMethod ?? 'cash';
    final double? activeReceived = order?.cashReceived ?? cashReceived;
    final double? activeChange = order?.cashChange ?? cashChange;

    final String? activeMemberName = order?.memberName ?? member?.name ?? memberName;
    final String? activeMemberPhone = order?.memberPhone ?? member?.phone ?? memberPhone;
    final double? activeMemberDiscount = order?.memberDiscountAmount ?? memberDiscountAmount;
    final int activePointsRedeemed = order?.pointsRedeemed ?? pointsRedeemed ?? 0;
    final double activePointRedeemAmount = order?.pointRedeemAmount ?? pointRedeemAmount ?? 0.0;
    
    final List<PrintReceiptItem> displayItems = (order != null && order!.items.isNotEmpty)
        ? order!.items.map((i) => PrintReceiptItem.fromDynamic(i)).toList()
        : (items != null ? items!.map((i) => PrintReceiptItem.fromDynamic(i)).toList() : []);

    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo Toko (Auto-convert ke Hitam Putih / Thermal B&W Preview)
          if (resolvedLogoUrl != null && resolvedLogoUrl.isNotEmpty) ...[
            Container(
              width: 72,
              height: 72,
              margin: const EdgeInsets.only(bottom: 12),
              child: ColorFiltered(
                // Matrix Grayscale + High Contrast Monokrom Thermal Printer
                colorFilter: const ColorFilter.matrix(<double>[
                  0.299 * 1.3, 0.587 * 1.3, 0.114 * 1.3, 0, -35,
                  0.299 * 1.3, 0.587 * 1.3, 0.114 * 1.3, 0, -35,
                  0.299 * 1.3, 0.587 * 1.3, 0.114 * 1.3, 0, -35,
                  0,           0,           0,           1, 0,
                ]),
                child: Image.network(
                  resolvedLogoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
          // Header - Nama Toko dari Owner (bukan ZENVI POS)
          Text(
            resolvedStoreName.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          if (resolvedStoreLocation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              resolvedStoreLocation,
              style: const TextStyle(fontSize: 11, fontFamily: 'Courier', color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
          if (resolvedStorePhone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Telp: $resolvedStorePhone',
              style: const TextStyle(fontSize: 11, fontFamily: 'Courier', color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Struk Belanja',
            style: TextStyle(fontSize: 14, fontFamily: 'Courier', color: Colors.black),
          ),
          const SizedBox(height: 16),
          
          // Info Order
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'No: $receiptNo',
                style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
              ),
              Text(
                DateFormat('dd/MM/yy HH:mm').format(receiptTime),
                style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Kasir: $resolvedCashierName',
                style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
              ),
            ],
          ),
          if (activeMemberName != null && activeMemberName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Member: $activeMemberName',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Courier', color: Colors.black),
                ),
                if (activeMemberPhone != null && activeMemberPhone.isNotEmpty)
                  Text(
                    activeMemberPhone,
                    style: const TextStyle(fontSize: 11, fontFamily: 'Courier', color: Colors.black),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const _DashedSeparator(),
          const SizedBox(height: 16),
          
          // Items
          if (displayItems.isNotEmpty)
            ...displayItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.name,
                      style: const TextStyle(fontSize: 14, fontFamily: 'Courier', color: Colors.black),
                    ),
                  ),
                  Text(
                    '${item.qty}x',
                    style: const TextStyle(fontSize: 14, fontFamily: 'Courier', color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(item.subtotal),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 14, fontFamily: 'Courier', color: Colors.black),
                    ),
                  ),
                ],
              ),
            ))
          else if (isOffline)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Detail item offline disembunyikan.',
                style: TextStyle(fontSize: 12, fontFamily: 'Courier', fontStyle: FontStyle.italic, color: Colors.black),
              ),
            ),
            
          const SizedBox(height: 16),
          const _DashedSeparator(),
          const SizedBox(height: 16),
          
          // Subtotal, Member Discount, & Point Redemption (Jika ada diskon/poin)
          if ((activeMemberDiscount != null && activeMemberDiscount > 0) || activePointRedeemAmount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
                ),
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(grandTotal + (activeMemberDiscount ?? 0) + activePointRedeemAmount),
                  style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
                ),
              ],
            ),
            if (activeMemberDiscount != null && activeMemberDiscount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Diskon Member',
                    style: TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
                  ),
                  Text(
                    '-${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(activeMemberDiscount)}',
                    style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
                  ),
                ],
              ),
            ],
            if (activePointRedeemAmount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tukar Poin ($activePointsRedeemed Pts)',
                    style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
                  ),
                  Text(
                    '-${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(activePointRedeemAmount)}',
                    style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
          ],

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Courier', color: Colors.black),
              ),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(grandTotal),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Courier', color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Payment Method & Cash details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Metode Bayar',
                style: TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
              ),
              Text(
                activeMethod == 'qris' ? 'qris_4'.tr(context: context) : (activeMethod == 'transfer' ? 'TRANSFER BANK' : 'TUNAI (CASH)'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Courier', color: Colors.black),
              ),
            ],
          ),
          if (activeMethod == 'cash' && activeReceived != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bayar Tunai',
                  style: TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
                ),
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(activeReceived),
                  style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kembalian',
                  style: TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
                ),
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(activeChange ?? (activeReceived - grandTotal)),
                  style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
                ),
              ],
            ),
          ],

          if (activeMemberName != null && activeMemberName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Poin Diperoleh',
                  style: TextStyle(fontSize: 11, fontFamily: 'Courier', color: Colors.black),
                ),
                Text(
                  '+${(grandTotal / 1000).floor()} Pts',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Courier', color: Colors.black),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 24),
          const Text(
            'Terima kasih telah berbelanja!',
            style: TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black),
          ),
          const SizedBox(height: 8),
          // ZENVI POS sekarang di bawah sebagai branding
          const Text(
            'Powered by Zenvi POS',
            style: TextStyle(fontSize: 10, fontFamily: 'Courier', color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _DashedSeparator extends StatelessWidget {
  const _DashedSeparator();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black),
              ),
            );
          }),
        );
      },
    );
  }
}
