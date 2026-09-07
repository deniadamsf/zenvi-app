import 'package:easy_localization/easy_localization.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../providers/cart_provider.dart';
import '../models/order_model.dart';

/// Helper konversi lebar kertas (mm) ke parameter cetak ESC/POS.
/// Dipakai bersama oleh PrinterService & PrinterProvider supaya lebar
/// kertas yang dipilih user konsisten di struk maupun test print.
class ReceiptPaper {
  static const int defaultWidthMm = 58;

  /// 110mm adalah lebar printer label/resi. ESC/POS sendiri hanya mengenal
  /// sampai 80mm, jadi lebar ini hanya benar-benar terpakai pada mode gambar
  /// (TSPL/CPCL/ESC-POS raster).
  static const List<int> supportedWidthsMm = [58, 72, 80, 110];

  static int normalize(int widthMm) {
    return supportedWidthsMm.contains(widthMm) ? widthMm : defaultWidthMm;
  }

  static PaperSize toPaperSize(int widthMm) {
    switch (normalize(widthMm)) {
      case 110:
      case 80:
        return PaperSize.mm80;
      case 72:
        return PaperSize.mm72;
      default:
        return PaperSize.mm58;
    }
  }

  /// Jumlah karakter per baris pada Font A (dipakai untuk perataan kolom manual).
  static int maxChars(int widthMm) {
    switch (normalize(widthMm)) {
      case 110:
        return 64;
      case 80:
        return 48;
      case 72:
        return 42;
      default:
        return 32;
    }
  }

  /// Lebar area cetak dalam dot pada kepala printer 203 dpi (8 dot/mm).
  /// Dipakai saat struk dirender sebagai gambar (TSPL/CPCL/raster).
  static int dotWidth(int widthMm) {
    switch (normalize(widthMm)) {
      case 110:
        return 832;
      case 80:
        return 576;
      case 72:
        return 512;
      default:
        return 384;
    }
  }

  /// Lebar logo optimal (px) agar tidak melebihi lebar dot printer.
  static int logoWidth(int widthMm) {
    switch (normalize(widthMm)) {
      case 110:
        return 600;
      case 80:
        return 380;
      case 72:
        return 300;
      default:
        return 200;
    }
  }
}

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
    int paperWidthMm = ReceiptPaper.defaultWidthMm,
  }) async {
    final int paperWidth = ReceiptPaper.normalize(paperWidthMm);
    final int maxChar = ReceiptPaper.maxChars(paperWidth);
    final profile = await CapabilityProfile.load();
    final generator = Generator(ReceiptPaper.toPaperSize(paperWidth), profile);
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
        final logoImage = await _fetchAndProcessLogo(logoUrl, ReceiptPaper.logoWidth(paperWidth));
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
      bytes += generator.text(
        '${'receipt_label_phone'.tr()}: ${safeCompany['phone']}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    
    bytes += generator.hr();
    
    // Receipt Info
    final printTime = transactionTime ?? DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    // Label diratakan berdasarkan yang terpanjang, bukan spasi tetap seperti
    // dulu: panjang kata berbeda di tiap bahasa, dan titik dua yang tidak lurus
    // langsung terlihat di struk.
    final labelNo = 'receipt_label_no'.tr();
    final labelDate = 'receipt_label_date'.tr();
    final labelCashier = 'receipt_label_cashier'.tr();
    final infoWidth = _widestLabel([labelNo, labelDate, labelCashier]);
    bytes += generator.text('${labelNo.padRight(infoWidth)}: $receiptNumber');
    bytes += generator.text('${labelDate.padRight(infoWidth)}: ${dateFormat.format(printTime)}');
    bytes += generator.text('${labelCashier.padRight(infoWidth)}: $cashierName');
    if (memberName != null && memberName.isNotEmpty) {
      final labelMember = 'receipt_label_member'.tr();
      final labelPhone = 'receipt_label_phone'.tr();
      final memberWidth = _widestLabel([labelMember, labelPhone]);
      bytes += generator.text('${labelMember.padRight(memberWidth)}: $memberName');
      if (memberPhone != null && memberPhone.isNotEmpty) {
        bytes += generator.text('${labelPhone.padRight(memberWidth)}: $memberPhone');
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
      bytes += _buildTotalLine(generator, '${'receipt_subtotal'.tr()}:', 'Rp${(total + memberDiscountAmount).toStringAsFixed(0)}', maxChar);
      bytes += _buildTotalLine(generator, '${'receipt_member_discount'.tr()}:', '-Rp${memberDiscountAmount.toStringAsFixed(0)}', maxChar);
    }

    // Totals
    if (tax > 0) {
      bytes += _buildTotalLine(generator, '${'receipt_subtotal'.tr()}:', 'Rp${subtotal.toStringAsFixed(0)}', maxChar);
      bytes += _buildTotalLine(generator, '${'receipt_tax'.tr()}:', 'Rp${tax.toStringAsFixed(0)}', maxChar);
    }

    // Final Total
    bytes += generator.text(
      _formatTotalLine('${'receipt_total'.tr()}:', 'Rp${total.toStringAsFixed(0)}', maxChar),
      styles: const PosStyles(bold: true, align: PosAlign.right, height: PosTextSize.size2, width: PosTextSize.size1),
    );

    // Payment details
    String payType = 'payment_method_cash_short'.tr();
    if (paymentMethod == 'qris') {
      payType = 'qris_4'.tr();
    } else if (paymentMethod == 'transfer') {
      payType = 'payment_method_transfer_short'.tr();
    }
    bytes += _buildTotalLine(generator, '${'receipt_payment_method'.tr()}:', payType, maxChar);
    if (paymentMethod == 'cash' && cashReceived != null) {
      bytes += _buildTotalLine(generator, '${'receipt_cash_received'.tr()}:', 'Rp${cashReceived.toStringAsFixed(0)}', maxChar);
      bytes += _buildTotalLine(generator, '${'receipt_change'.tr()}:', 'Rp${(cashChange ?? (cashReceived - total)).toStringAsFixed(0)}', maxChar);
    }

    if (memberName != null && memberName.isNotEmpty) {
      final pointsEarned = (total / 1000).floor();
      bytes += _buildTotalLine(generator, '${'receipt_points_earned'.tr()}:', '+$pointsEarned ${'receipt_points_unit'.tr()}', maxChar);
    }

    bytes += generator.feed(1);
    for (final line in _wrapText('receipt_thanks_print'.tr(), maxChar)) {
      bytes += generator.text(line, styles: const PosStyles(align: PosAlign.center));
    }
    for (final line in _wrapText('receipt_no_exchange'.tr(), maxChar)) {
      bytes += generator.text(line, styles: const PosStyles(align: PosAlign.center));
    }
    
    // ZENVI POS branding di bawah
    bytes += generator.feed(1);
    bytes += generator.text('Powered by Zenvi POS', styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.feed(3);
    
    return bytes;
  }

  static int _widestLabel(List<String> labels) {
    return labels.fold<int>(0, (widest, label) => label.length > widest ? label.length : widest);
  }

  /// Memecah kalimat mengikuti lebar kertas. Dulu barisnya dipotong manual di
  /// kode, yang hanya benar untuk satu bahasa - terjemahan yang lebih panjang
  /// akan terpotong printer.
  static List<String> _wrapText(String text, int maxChar) {
    final lines = <String>[];
    var current = '';
    for (final word in text.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      if (current.isEmpty) {
        current = word;
      } else if (current.length + 1 + word.length <= maxChar) {
        current = '$current $word';
      } else {
        lines.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  static List<int> _buildTotalLine(Generator generator, String label, String value, int maxChar) {
    return generator.text(_formatTotalLine(label, value, maxChar), styles: const PosStyles(align: PosAlign.right));
  }

  static String _formatTotalLine(String label, String value, int maxChar) {
    final int spaces = maxChar - label.length - value.length;
    String line = label;
    for (int i = 0; i < (spaces > 0 ? spaces : 1); i++) {
      line += ' ';
    }
    line += value;
    return line;
  }

  static Future<img.Image?> _fetchAndProcessLogo(String logoUrl, int maxLogoWidth) async {
    try {
      final response = await http.get(Uri.parse(logoUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final original = img.decodeImage(response.bodyBytes);
        if (original != null) {
          // Resize mengikuti lebar kertas yang dipilih user
          int targetWidth = maxLogoWidth;
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
