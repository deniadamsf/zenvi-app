import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/order_model.dart';
import '../../../models/member_model.dart';
import '../../../providers/auth_provider.dart';
import '../printer_dialog.dart';
import 'receipt_widget.dart';

class ReceiptPreviewModal extends StatefulWidget {
  final OrderModel? order;
  final List<dynamic>? items;
  final double totalAmount;
  final String receiptNumber;
  final DateTime transactionTime;
  final bool isOffline;
  final String paymentMethod;
  final double? cashReceived;
  final double? cashChange;
  final MemberModel? member;
  final String? memberName;
  final String? memberPhone;
  final double? memberDiscountAmount;
  final int? pointsRedeemed;
  final double? pointRedeemAmount;

  const ReceiptPreviewModal({
    super.key,
    this.order,
    this.items,
    required this.totalAmount,
    required this.receiptNumber,
    required this.transactionTime,
    this.isOffline = false,
    this.paymentMethod = 'cash',
    this.cashReceived,
    this.cashChange,
    this.member,
    this.memberName,
    this.memberPhone,
    this.memberDiscountAmount,
    this.pointsRedeemed,
    this.pointRedeemAmount,
  });

  static Future<void> show({
    required BuildContext context,
    OrderModel? order,
    List<dynamic>? items,
    double? totalAmount,
    String? receiptNumber,
    DateTime? transactionTime,
    bool isOffline = false,
    String? paymentMethod,
    double? cashReceived,
    double? cashChange,
    MemberModel? member,
    String? memberName,
    String? memberPhone,
    double? memberDiscountAmount,
    int? pointsRedeemed,
    double? pointRedeemAmount,
  }) {
    final double amount = order?.totalAmount ?? totalAmount ?? 0.0;
    final String rNo = order != null
        ? (isOffline ? 'OFFLINE-${order.id}' : 'INV-${order.id}')
        : (receiptNumber ?? 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}');
    final DateTime tTime = order != null
        ? (DateTime.tryParse(order.createdAt)?.toLocal() ?? DateTime.now())
        : (transactionTime ?? DateTime.now());
    final String pMethod = order?.paymentMethod ?? paymentMethod ?? 'cash';
    final double? cReceived = order?.cashReceived ?? cashReceived;
    final double? cChange = order?.cashChange ?? cashChange;

    final dynamic receiptItems = order?.items ?? items ?? [];

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReceiptPreviewModal(
        order: order,
        items: receiptItems is List ? receiptItems : [],
        totalAmount: amount,
        receiptNumber: rNo,
        transactionTime: tTime,
        isOffline: isOffline,
        paymentMethod: pMethod,
        cashReceived: cReceived,
        cashChange: cChange,
        member: member,
        memberName: memberName ?? order?.memberName,
        memberPhone: memberPhone ?? order?.memberPhone,
        memberDiscountAmount: memberDiscountAmount ?? order?.memberDiscountAmount,
        pointsRedeemed: pointsRedeemed ?? order?.pointsRedeemed,
        pointRedeemAmount: pointRedeemAmount ?? order?.pointRedeemAmount,
      ),
    );
  }

  @override
  State<ReceiptPreviewModal> createState() => _ReceiptPreviewModalState();
}

class _ReceiptPreviewModalState extends State<ReceiptPreviewModal> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareReceipt() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final company = authProvider.user?.company;
    final storeName = company?['name'] ?? 'toko_saya_9'.tr(context: context);
    final storeLoc = company?['location']?.toString() ?? '';
    final storeTelp = company?['phone']?.toString() ?? '';
    final cashier = authProvider.user?.name ?? 'kasir_5'.tr(context: context);
    String? lUrl = company?['logo_url']?.toString();
    if ((lUrl == null || lUrl.isEmpty) && company?['logo_path'] != null) {
      final path = company!['logo_path'].toString();
      lUrl = path.startsWith('http') ? path : 'https://zenvi.cellanoma.my.id/uploads/logos/$path';
    }
    final shareText = 'receipt_share_text'.tr(context: context, args: [widget.receiptNumber]);
    final failShareText = 'failed_share_receipt'.tr(context: context);

    try {
      // 1. Coba capture langsung dari Screenshot widget yang sudah terpasang di layar (High Res pixelRatio 2.0)
      Uint8List? image;
      try {
        image = await _screenshotController.capture(
          pixelRatio: 2.0,
          delay: const Duration(milliseconds: 50),
        );
      } catch (e) {
        debugPrint('Direct screenshot capture error: $e');
      }

      // 2. Jika capture langsung belum siap/null, fallback ke captureFromWidget dengan data lengkap
      if (image == null || image.isEmpty) {
        image = await _screenshotController.captureFromWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Material(
              color: Colors.white,
              child: ReceiptWidget(
                order: widget.order,
                items: widget.items,
                totalAmount: widget.totalAmount,
                receiptNumber: widget.receiptNumber,
                transactionTime: widget.transactionTime,
                isOffline: widget.isOffline,
                paymentMethod: widget.paymentMethod,
                cashReceived: widget.cashReceived,
                cashChange: widget.cashChange,
                member: widget.member,
                memberName: widget.memberName,
                memberPhone: widget.memberPhone,
                memberDiscountAmount: widget.memberDiscountAmount,
                pointsRedeemed: widget.pointsRedeemed,
                pointRedeemAmount: widget.pointRedeemAmount,
                storeName: storeName,
                storeLocation: storeLoc,
                storePhone: storeTelp,
                cashierName: cashier,
                logoUrl: lUrl,
              ),
            ),
          ),
          context: mounted ? context : null,
          delay: const Duration(milliseconds: 150),
          pixelRatio: 2.0,
        );
      }

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/struk_${widget.receiptNumber}.png').create();
      await imagePath.writeAsBytes(image);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath.path)],
          text: shareText,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$failShareText $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _printReceipt() {
    showDialog(
      context: context,
      builder: (_) => PrinterDialog(
        totalAmount: widget.totalAmount,
        subtotal: widget.totalAmount + (widget.memberDiscountAmount ?? 0.0),
        tax: 0.0,
        items: widget.items ?? widget.order?.items ?? [],
        receiptNumber: widget.receiptNumber,
        transactionTime: widget.transactionTime,
        paymentMethod: widget.paymentMethod,
        cashReceived: widget.cashReceived,
        cashChange: widget.cashChange,
        memberName: widget.memberName ?? widget.member?.name,
        memberPhone: widget.memberPhone ?? widget.member?.phone,
        memberDiscountAmount: widget.memberDiscountAmount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedTotal = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'rp_3'.tr(context: context),
      decimalDigits: 0,
    ).format(widget.totalAmount);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pembayaran Berhasil',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total $formattedTotal • ${widget.receiptNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 20),

          // Scrollable Receipt Preview
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Center(
                child: Screenshot(
                  controller: _screenshotController,
                  child: ReceiptWidget(
                    order: widget.order,
                    items: widget.items,
                    totalAmount: widget.totalAmount,
                    receiptNumber: widget.receiptNumber,
                    transactionTime: widget.transactionTime,
                    isOffline: widget.isOffline,
                    paymentMethod: widget.paymentMethod,
                    cashReceived: widget.cashReceived,
                    cashChange: widget.cashChange,
                    member: widget.member,
                    memberName: widget.memberName,
                    memberPhone: widget.memberPhone,
                    memberDiscountAmount: widget.memberDiscountAmount,
                    pointsRedeemed: widget.pointsRedeemed,
                    pointRedeemAmount: widget.pointRedeemAmount,
                  ),
                ),
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Tombol Share
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                        ),
                        onPressed: _isSharing ? null : _shareReceipt,
                        icon: _isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.share_outlined, size: 20),
                        label: Text('bagikan_320'.tr(context: context), style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Cetak Struk
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _printReceipt,
                        icon: const Icon(Icons.print, size: 20),
                        label: const Text(
                          'Cetak Struk',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Tombol Transaksi Baru / Selesai
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Selesai & Transaksi Baru',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
