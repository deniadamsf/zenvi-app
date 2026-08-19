import 'package:easy_localization/easy_localization.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../providers/cart_provider.dart';
import '../models/order_model.dart';

class PrintReceiptItem {
  final String name;
  final int qty;
  final double unitPrice;
  final double subtotal;

  PrintReceiptItem({
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
  });

  factory PrintReceiptItem.fromDynamic(dynamic item) {
    if (item is CartItem) {
      final name = item.variantName != null 
          ? '${item.product.name} - ${item.variantName}' 
          : item.product.name;
      final unitPrice = item.variantPrice ?? item.product.finalPrice;
      return PrintReceiptItem(
        name: name,
        qty: item.quantity,
        unitPrice: unitPrice,
        subtotal: item.subtotal,
      );
    } else if (item is OrderItemModel) {
      final name = item.product?.name ?? 'Produk';
      final qty = item.qty;
      final subtotal = item.subtotal;
      final unitPrice = qty > 0 ? (subtotal / qty) : subtotal;
      return PrintReceiptItem(
        name: name,
        qty: qty,
        unitPrice: unitPrice,
        subtotal: subtotal,
      );
    } else if (item is Map) {
      final name = item['product_name'] ?? item['name'] ?? 'Produk';
      final qty = int.tryParse(item['qty']?.toString() ?? '1') ?? 1;
      final subtotal = double.tryParse(item['subtotal']?.toString() ?? '0') ?? 0.0;
      final unitPrice = qty > 0 ? (subtotal / qty) : subtotal;
      return PrintReceiptItem(
        name: name.toString(),
        qty: qty,
        unitPrice: unitPrice,
        subtotal: subtotal,
      );
    } else {
      return PrintReceiptItem(
        name: item.toString(),
        qty: 1,
        unitPrice: 0.0,
        subtotal: 0.0,
      );
    }
  }
}

class PrinterService {
  static Future<List<int>> generateReceiptBytes(
    Map<String, dynamic>? company,
    List<dynamic> items,
    double total,
    double subtotal,
    double tax,
    String cashierName,
    String receiptNumber, {
    DateTime? transactionTime,
    String paymentMethod = 'cash',
    double? cashReceived,
    double? cashChange,
    String? memberName,
    String? memberPhone,
    double? memberDiscountAmount,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.reset();

    final safeCompany = company ?? {'name': 'toko_saya_9'.tr()};

    // 1. Logo Toko (Auto B&W conversion for thermal printer)
    String? logoUrl = safeCompany['logo_url']?.toString();
    if ((logoUrl == null || logoUrl.isEmpty) && safeCompany['logo_path'] != null) {
      final path = safeCompany['logo_path'].toString();
      logoUrl = path.startsWith('http') ? path : 'https://zenvi.cellanoma.my.id/uploads/logos/$path';
    }

    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final logoImage = await _fetchAndProcessLogo(logoUrl);
        if (logoImage != null) {
          bytes += generator.imageRaster(logoImage, align: PosAlign.center);
          bytes += generator.feed(1);
        }
      } catch (e) {
        // Skip logo on failure without interrupting receipt printing
      }
    }

    // Header - Nama Toko dari Company (bukan ZENVI POS)
    final storeName = (safeCompany['name'] ?? 'toko_saya_9'.tr()).toString().toUpperCase();
    bytes += generator.text(
      storeName,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    
    // Address if exists
    if (safeCompany['location'] != null && safeCompany['location'].toString().isNotEmpty) {
      bytes += generator.text(
        safeCompany['location'].toString(),
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    
    // Phone if exists
    if (safeCompany['phone'] != null && safeCompany['phone'].toString().isNotEmpty) {
      bytes += generator.text('Telp: ${safeCompany['phone']}', styles: const PosStyles(align: PosAlign.center));
    }
    
    bytes += generator.hr();
    
    // Receipt Info
    final printTime = transactionTime ?? DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    bytes += generator.text('No   : $receiptNumber');
    bytes += generator.text('Tgl  : ${dateFormat.format(printTime)}');
    bytes += generator.text('Kasir: $cashierName');
    if (memberName != null && memberName.isNotEmpty) {
      bytes += generator.text('Member: $memberName');
      if (memberPhone != null && memberPhone.isNotEmpty) {
        bytes += generator.text('Telp  : $memberPhone');
      }
    }
    
    bytes += generator.hr();

    // Items (Polymorphic support)
    for (var rawItem in items) {
      final item = PrintReceiptItem.fromDynamic(rawItem);
      bytes += generator.text(
        item.name,
        styles: const PosStyles(bold: true),
      );
      
      final String qtyAndPrice = '${item.qty} x Rp${item.unitPrice.toStringAsFixed(0)}';
      final String itemTotal = 'Rp${item.subtotal.toStringAsFixed(0)}';
      
      const int maxChar = 32;
      final int spaces = maxChar - qtyAndPrice.length - itemTotal.length;
      
      String line = qtyAndPrice;
      for (int i = 0; i < (spaces > 0 ? spaces : 1); i++) {
        line += ' ';
      }
      line += itemTotal;
      
      bytes += generator.text(line);
    }

    bytes += generator.hr();
    
    // Member Discount & Subtotal (if discount exists)
    if (memberDiscountAmount != null && memberDiscountAmount > 0) {
      bytes += _buildTotalLine(generator, 'Subtotal:', 'Rp${(total + memberDiscountAmount).toStringAsFixed(0)}');
      bytes += _buildTotalLine(generator, 'Diskon Member:', '-Rp${memberDiscountAmount.toStringAsFixed(0)}');
    }

    // Totals
    if (tax > 0) {
      bytes += _buildTotalLine(generator, 'Subtotal:', 'Rp${subtotal.toStringAsFixed(0)}');
      bytes += _buildTotalLine(generator, 'Pajak:', 'Rp${tax.toStringAsFixed(0)}');
    }
    
    // Final Total
    bytes += generator.text(
      _formatTotalLine('TOTAL:', 'Rp${total.toStringAsFixed(0)}'),
      styles: const PosStyles(bold: true, align: PosAlign.right, height: PosTextSize.size2, width: PosTextSize.size1),
    );

    // Payment details
    String payType = 'TUNAI';
    if (paymentMethod == 'qris') {
      payType = 'qris_4'.tr();
    } else if (paymentMethod == 'transfer') {
      payType = 'TRANSFER';
    }
    bytes += _buildTotalLine(generator, 'Metode Bayar:', payType);
    if (paymentMethod == 'cash' && cashReceived != null) {
      bytes += _buildTotalLine(generator, 'Bayar Tunai:', 'Rp${cashReceived.toStringAsFixed(0)}');
      bytes += _buildTotalLine(generator, 'Kembali:', 'Rp${(cashChange ?? (cashReceived - total)).toStringAsFixed(0)}');
    }

    if (memberName != null && memberName.isNotEmpty) {
      final pointsEarned = (total / 1000).floor();
      bytes += _buildTotalLine(generator, 'Poin Diperoleh:', '+$pointsEarned Pts');
    }

    bytes += generator.feed(1);
    bytes += generator.text('Terima Kasih Atas Kunjungan Anda', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Barang yang sudah dibeli', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('tidak dapat ditukar/dikembalikan', styles: const PosStyles(align: PosAlign.center));
    
    // ZENVI POS branding di bawah
    bytes += generator.feed(1);
    bytes += generator.text('Powered by Zenvi POS', styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.feed(3);
    
    return bytes;
  }

  static List<int> _buildTotalLine(Generator generator, String label, String value) {
    return generator.text(_formatTotalLine(label, value), styles: const PosStyles(align: PosAlign.right));
  }

  static String _formatTotalLine(String label, String value) {
    const int maxChar = 32;
    final int spaces = maxChar - label.length - value.length;
    String line = label;
    for (int i = 0; i < (spaces > 0 ? spaces : 1); i++) {
      line += ' ';
    }
    line += value;
    return line;
  }

  static Future<img.Image?> _fetchAndProcessLogo(String logoUrl) async {
    try {
      final response = await http.get(Uri.parse(logoUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final original = img.decodeImage(response.bodyBytes);
        if (original != null) {
          // Resize for 58mm printer (optimal width 200px)
          int targetWidth = 200;
          if (original.width < targetWidth) {
            targetWidth = original.width;
          }
          final resized = img.copyResize(original, width: targetWidth);
          
          // Convert to grayscale
          final grayscale = img.grayscale(resized);
          
          // Auto-convert to pure high-contrast Black & White for clean thermal output
          for (final pixel in grayscale) {
            if (pixel.a < 128) {
              pixel.r = 255;
              pixel.g = 255;
              pixel.b = 255;
              pixel.a = 255;
            } else {
              final lum = pixel.luminance;
              if (lum > 160) {
                pixel.r = 255;
                pixel.g = 255;
                pixel.b = 255;
              } else {
                pixel.r = 0;
                pixel.g = 0;
                pixel.b = 0;
              }
            }
          }

          return grayscale;
        }
      }
    } catch (e) {
      // Gracefully catch any timeout or image decode error
    }
    return null;
  }
}
