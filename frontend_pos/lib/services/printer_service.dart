import 'package:easy_localization/easy_localization.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../providers/cart_provider.dart';
import '../models/order_model.dart';
import 'label_printer_service.dart';

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

/// Perataan satu baris struk.
///
/// Sengaja lepas dari `PosAlign` milik ESC/POS: isi struk yang sama harus bisa
/// dikirim sebagai ESC/POS, TSPL, CPCL, maupun bitmap.
enum ReceiptAlign { left, center, right }

enum ReceiptLineKind { text, rule, feed }

/// Satu baris struk beserta gayanya, belum terikat bahasa printer mana pun.
class ReceiptLine {
  const ReceiptLine.text(
    this.text, {
    this.align = ReceiptAlign.left,
    this.bold = false,
    this.doubleHeight = false,
    this.doubleWidth = false,
  })  : kind = ReceiptLineKind.text,
        count = 0;

  const ReceiptLine.rule()
      : kind = ReceiptLineKind.rule,
        text = '',
        align = ReceiptAlign.left,
        bold = false,
        doubleHeight = false,
        doubleWidth = false,
        count = 0;

  const ReceiptLine.feed(this.count)
      : kind = ReceiptLineKind.feed,
        text = '',
        align = ReceiptAlign.left,
        bold = false,
        doubleHeight = false,
        doubleWidth = false;

  final ReceiptLineKind kind;
  final String text;
  final ReceiptAlign align;
  final bool bold;
  final bool doubleHeight;
  final bool doubleWidth;

  /// Jumlah baris kosong, hanya berarti untuk [ReceiptLineKind.feed].
  final int count;
}

/// Isi struk yang sudah lengkap tapi belum jadi perintah printer.
///
/// Dokumen ini dibangun sekali, lalu satu encoder per bahasa printer yang
/// mengubahnya jadi byte. Sebelumnya isi struk dan perintah ESC/POS ditulis
/// bercampur dalam satu fungsi, sehingga printer TSPL/CPCL mustahil didukung
/// tanpa menyalin ulang seluruh susunan struk.
class ReceiptDocument {
  ReceiptDocument({
    required this.paperWidthMm,
    required this.maxChars,
    required this.lines,
    this.logo,
  });

  final int paperWidthMm;
  final int maxChars;
  final List<ReceiptLine> lines;
  final img.Image? logo;
}

class PrinterService {
  /// Byte siap kirim ke printer, mengikuti [mode] yang dipilih user.
  ///
  /// Default-nya ESC/POS teks - perilaku lama - supaya pemanggil yang belum
  /// meneruskan mode tidak berubah hasilnya.
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
    PrintMode mode = PrintMode.escPosText,
  }) async {
    final doc = await buildReceiptDocument(
      company,
      items,
      total,
      subtotal,
      tax,
      cashierName,
      receiptNumber,
      transactionTime: transactionTime,
      paymentMethod: paymentMethod,
      cashReceived: cashReceived,
      cashChange: cashChange,
      memberName: memberName,
      memberPhone: memberPhone,
      memberDiscountAmount: memberDiscountAmount,
      paperWidthMm: paperWidthMm,
      // Logo hanya diambil kalau modenya memang mengenal bitmap. Mengunduhnya
      // untuk mode teks cuma menambah tunggu 4 detik sebelum struk keluar.
      includeLogo: mode.render == PrintRender.image || mode.language == PrintLanguage.escPos,
    );
    return encodeReceipt(doc, mode);
  }

  /// Susun isi struk tanpa menyentuh perintah printer sama sekali.
  static Future<ReceiptDocument> buildReceiptDocument(
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
    bool includeLogo = true,
  }) async {
    final int paperWidth = ReceiptPaper.normalize(paperWidthMm);
    final int maxChar = ReceiptPaper.maxChars(paperWidth);
    final lines = <ReceiptLine>[];

    final safeCompany = company ?? {'name': 'toko_saya_9'.tr()};

    // 1. Logo Toko (Auto B&W conversion for thermal printer)
    img.Image? logo;
    if (includeLogo) {
      String? logoUrl = safeCompany['logo_url']?.toString();
      if ((logoUrl == null || logoUrl.isEmpty) && safeCompany['logo_path'] != null) {
        final path = safeCompany['logo_path'].toString();
        logoUrl = path.startsWith('http') ? path : 'https://zenvi.cellanoma.my.id/uploads/logos/$path';
      }

      if (logoUrl != null && logoUrl.isNotEmpty) {
        try {
          logo = await _fetchAndProcessLogo(logoUrl, ReceiptPaper.logoWidth(paperWidth));
        } catch (e) {
          // Skip logo on failure without interrupting receipt printing
        }
      }
    }

    // Header - Nama Toko dari Company (bukan ZENVI POS)
    final storeName = (safeCompany['name'] ?? 'toko_saya_9'.tr()).toString().toUpperCase();
    lines.add(ReceiptLine.text(
      storeName,
      align: ReceiptAlign.center,
      bold: true,
      doubleHeight: true,
      doubleWidth: true,
    ));

    // Address if exists
    if (safeCompany['location'] != null && safeCompany['location'].toString().isNotEmpty) {
      lines.add(ReceiptLine.text(safeCompany['location'].toString(), align: ReceiptAlign.center));
    }

    // Phone if exists
    if (safeCompany['phone'] != null && safeCompany['phone'].toString().isNotEmpty) {
      lines.add(ReceiptLine.text(
        '${'receipt_label_phone'.tr()}: ${safeCompany['phone']}',
        align: ReceiptAlign.center,
      ));
    }

    lines.add(const ReceiptLine.rule());

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
    lines.add(ReceiptLine.text('${labelNo.padRight(infoWidth)}: $receiptNumber'));
    lines.add(ReceiptLine.text('${labelDate.padRight(infoWidth)}: ${dateFormat.format(printTime)}'));
    lines.add(ReceiptLine.text('${labelCashier.padRight(infoWidth)}: $cashierName'));
    if (memberName != null && memberName.isNotEmpty) {
      final labelMember = 'receipt_label_member'.tr();
      final labelPhone = 'receipt_label_phone'.tr();
      final memberWidth = _widestLabel([labelMember, labelPhone]);
      lines.add(ReceiptLine.text('${labelMember.padRight(memberWidth)}: $memberName'));
      if (memberPhone != null && memberPhone.isNotEmpty) {
        lines.add(ReceiptLine.text('${labelPhone.padRight(memberWidth)}: $memberPhone'));
      }
    }

    lines.add(const ReceiptLine.rule());

    // Items (Polymorphic support)
    for (var rawItem in items) {
      final item = PrintReceiptItem.fromDynamic(rawItem);
      lines.add(ReceiptLine.text(item.name, bold: true));

      final String qtyAndPrice = '${item.qty} x Rp${item.unitPrice.toStringAsFixed(0)}';
      final String itemTotal = 'Rp${item.subtotal.toStringAsFixed(0)}';

      final int spaces = maxChar - qtyAndPrice.length - itemTotal.length;

      String line = qtyAndPrice;
      for (int i = 0; i < (spaces > 0 ? spaces : 1); i++) {
        line += ' ';
      }
      line += itemTotal;

      lines.add(ReceiptLine.text(line));
    }

    lines.add(const ReceiptLine.rule());

    // Member Discount & Subtotal (if discount exists)
    if (memberDiscountAmount != null && memberDiscountAmount > 0) {
      lines.add(_totalLine('${'receipt_subtotal'.tr()}:', 'Rp${(total + memberDiscountAmount).toStringAsFixed(0)}', maxChar));
      lines.add(_totalLine('${'receipt_member_discount'.tr()}:', '-Rp${memberDiscountAmount.toStringAsFixed(0)}', maxChar));
    }

    // Totals
    if (tax > 0) {
      lines.add(_totalLine('${'receipt_subtotal'.tr()}:', 'Rp${subtotal.toStringAsFixed(0)}', maxChar));
      lines.add(_totalLine('${'receipt_tax'.tr()}:', 'Rp${tax.toStringAsFixed(0)}', maxChar));
    }

    // Final Total
    lines.add(ReceiptLine.text(
      _formatTotalLine('${'receipt_total'.tr()}:', 'Rp${total.toStringAsFixed(0)}', maxChar),
      align: ReceiptAlign.right,
      bold: true,
      doubleHeight: true,
    ));

    // Payment details
    String payType = 'payment_method_cash_short'.tr();
    if (paymentMethod == 'qris') {
      payType = 'qris_4'.tr();
    } else if (paymentMethod == 'transfer') {
      payType = 'payment_method_transfer_short'.tr();
    }
    lines.add(_totalLine('${'receipt_payment_method'.tr()}:', payType, maxChar));
    if (paymentMethod == 'cash' && cashReceived != null) {
      lines.add(_totalLine('${'receipt_cash_received'.tr()}:', 'Rp${cashReceived.toStringAsFixed(0)}', maxChar));
      lines.add(_totalLine('${'receipt_change'.tr()}:', 'Rp${(cashChange ?? (cashReceived - total)).toStringAsFixed(0)}', maxChar));
    }

    if (memberName != null && memberName.isNotEmpty) {
      final pointsEarned = (total / 1000).floor();
      lines.add(_totalLine('${'receipt_points_earned'.tr()}:', '+$pointsEarned ${'receipt_points_unit'.tr()}', maxChar));
    }

    lines.add(const ReceiptLine.feed(1));
    for (final line in _wrapText('receipt_thanks_print'.tr(), maxChar)) {
      lines.add(ReceiptLine.text(line, align: ReceiptAlign.center));
    }
    for (final line in _wrapText('receipt_no_exchange'.tr(), maxChar)) {
      lines.add(ReceiptLine.text(line, align: ReceiptAlign.center));
    }

    // ZENVI POS branding di bawah
    lines.add(const ReceiptLine.feed(1));
    lines.add(ReceiptLine.text('Powered by Zenvi POS', align: ReceiptAlign.center));

    lines.add(const ReceiptLine.feed(3));

    return ReceiptDocument(
      paperWidthMm: paperWidth,
      maxChars: maxChar,
      lines: lines,
      logo: logo,
    );
  }

  /// Terjemahkan dokumen struk ke perintah printer sesuai [mode].
  static Future<List<int>> encodeReceipt(ReceiptDocument doc, PrintMode mode) async {
    if (mode.render == PrintRender.image) {
      final image = renderReceiptImage(
        doc,
        dotWidth: imageDotWidth(doc.paperWidthMm, mode.language),
      );
      switch (mode.language) {
        case PrintLanguage.tspl:
          return LabelPrinterService.buildTsplImage(image);
        case PrintLanguage.cpcl:
          return LabelPrinterService.buildCpclImage(image);
        case PrintLanguage.escPos:
          return LabelPrinterService.buildEscPosImage(image, ReceiptPaper.toPaperSize(doc.paperWidthMm));
      }
    }

    switch (mode.language) {
      case PrintLanguage.escPos:
        return _encodeEscPosText(doc);
      case PrintLanguage.tspl:
        return LabelPrinterService.buildTsplText(toPlainLines(doc));
      case PrintLanguage.cpcl:
        return LabelPrinterService.buildCpclText(toPlainLines(doc));
    }
  }

  /// Lebar bitmap struk dalam dot.
  ///
  /// Perintah raster ESC/POS tidak mengenal kertas di atas 80mm, jadi 110mm
  /// dipangkas ke lebar terbesar yang masih dimengerti; TSPL/CPCL memakai
  /// lebar kertas apa adanya.
  static int imageDotWidth(int paperWidthMm, PrintLanguage language) {
    final int normalized = ReceiptPaper.normalize(paperWidthMm);
    if (language == PrintLanguage.escPos && normalized > 80) {
      return ReceiptPaper.dotWidth(80);
    }
    return ReceiptPaper.dotWidth(normalized);
  }

  static Future<List<int>> _encodeEscPosText(ReceiptDocument doc) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(ReceiptPaper.toPaperSize(doc.paperWidthMm), profile);
    List<int> bytes = [];

    bytes += generator.reset();

    final logo = doc.logo;
    if (logo != null) {
      bytes += generator.imageRaster(logo, align: PosAlign.center);
      bytes += generator.feed(1);
    }

    for (final line in doc.lines) {
      switch (line.kind) {
        case ReceiptLineKind.rule:
          bytes += generator.hr();
          break;
        case ReceiptLineKind.feed:
          bytes += generator.feed(line.count);
          break;
        case ReceiptLineKind.text:
          bytes += generator.text(
            line.text,
            styles: PosStyles(
              align: _toPosAlign(line.align),
              bold: line.bold,
              height: line.doubleHeight ? PosTextSize.size2 : PosTextSize.size1,
              width: line.doubleWidth ? PosTextSize.size2 : PosTextSize.size1,
            ),
          );
          break;
      }
    }

    return bytes;
  }

  /// Struk sebagai baris teks polos, untuk printer label yang mencetak memakai
  /// font bawaannya sendiri (TSPL TEXT / CPCL TEXT).
  ///
  /// Logo tidak ikut di sini karena perintah teks tidak mengenal bitmap - itu
  /// harga yang dibayar mode teks demi payload kecil yang tidak rawan putus.
  static List<String> toPlainLines(ReceiptDocument doc) {
    final out = <String>[];
    for (final line in doc.lines) {
      switch (line.kind) {
        case ReceiptLineKind.rule:
          out.add('-' * doc.maxChars);
          break;
        case ReceiptLineKind.feed:
          out.addAll(List<String>.filled(line.count, ''));
          break;
        case ReceiptLineKind.text:
          out.add(line.align == ReceiptAlign.center
              ? _centerPad(line.text, doc.maxChars)
              : line.text);
          break;
      }
    }
    // Baris kosong di ekor hanya memakan label; printer label memberi jarak
    // sendiri lewat perintah FORM/PRINT.
    while (out.isNotEmpty && out.last.trim().isEmpty) {
      out.removeLast();
    }
    return out;
  }

  /// Render struk jadi bitmap, untuk printer yang tidak punya font yang cocok
  /// atau yang hanya mau menerima gambar.
  ///
  /// Barisnya digambar monospace: seluruh perataan kolom di struk ini dibangun
  /// dari padding spasi, dan font proporsional akan merusak kolom harganya.
  static img.Image renderReceiptImage(ReceiptDocument doc, {required int dotWidth}) {
    const int margin = 8;
    final int contentWidth = dotWidth - margin * 2;
    final int cellWidth = (contentWidth ~/ doc.maxChars).clamp(4, 64);
    final baseFont = _fontForCell(cellWidth);
    final bigFont = _nextFontUp(baseFont);

    img.Image? logo = doc.logo;
    if (logo != null && logo.width > contentWidth) {
      logo = img.copyResize(logo, width: contentWidth);
    }

    final renderLines = _foldToPaper(doc);

    int height = margin;
    if (logo != null) height += logo.height + margin;
    for (final line in renderLines) {
      height += _lineHeight(line, baseFont, bigFont);
    }
    height += margin;

    final canvas = img.Image(width: dotWidth, height: height);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    final black = img.ColorRgb8(0, 0, 0);

    int y = margin;
    if (logo != null) {
      img.compositeImage(canvas, logo, dstX: (dotWidth - logo.width) ~/ 2, dstY: y);
      y += logo.height + margin;
    }

    for (final line in renderLines) {
      final int lineHeight = _lineHeight(line, baseFont, bigFont);
      switch (line.kind) {
        case ReceiptLineKind.feed:
          break;
        case ReceiptLineKind.rule:
          final int ruleY = y + lineHeight ~/ 2;
          img.fillRect(
            canvas,
            x1: margin,
            y1: ruleY,
            x2: dotWidth - margin - 1,
            y2: ruleY + 1,
            color: black,
          );
          break;
        case ReceiptLineKind.text:
          if (line.doubleWidth) {
            // Baris besar ini berdiri sendiri (nama toko), jadi tidak perlu
            // ikut kisi monospace - cukup ditengahkan apa adanya.
            final int width = _measureText(bigFont, line.text);
            final int x = line.align == ReceiptAlign.center
                ? ((dotWidth - width) ~/ 2).clamp(0, dotWidth)
                : margin;
            _drawText(canvas, line.text, bigFont, x, y, black, bold: line.bold);
          } else {
            final font = line.doubleHeight ? bigFont : baseFont;
            _drawMonospace(canvas, line.text, font, margin, y, cellWidth, black, bold: line.bold);
          }
          break;
      }
      y += lineHeight;
    }

    return canvas;
  }

  /// Lipat baris yang lebih lebar dari kertas, seperti yang dilakukan printer
  /// ESC/POS sendiri.
  ///
  /// Pada bitmap tidak ada yang melipatkan otomatis: kelebihannya cuma jatuh di
  /// luar tepi kertas dan hilang tanpa jejak. Nama produk yang panjang adalah
  /// kasus yang paling sering kena.
  static List<ReceiptLine> _foldToPaper(ReceiptDocument doc) {
    final out = <ReceiptLine>[];
    for (final line in doc.lines) {
      if (line.kind != ReceiptLineKind.text) {
        out.add(line);
        continue;
      }

      // Huruf ganda lebar memakan dua sel per karakter. Kalau tidak muat,
      // baris itu turun pangkat jadi tinggi-ganda saja supaya tetap terbaca
      // utuh - lebih baik daripada nama toko yang terpenggal.
      final bool doubleWidthFits = line.text.length * 2 <= doc.maxChars;
      if (line.doubleWidth && doubleWidthFits) {
        out.add(line);
        continue;
      }

      if (!line.doubleWidth && line.text.length <= doc.maxChars) {
        out.add(line);
        continue;
      }

      for (int i = 0; i < line.text.length; i += doc.maxChars) {
        final int end =
            (i + doc.maxChars < line.text.length) ? i + doc.maxChars : line.text.length;
        out.add(ReceiptLine.text(
          line.text.substring(i, end),
          align: line.align,
          bold: line.bold,
          doubleHeight: line.doubleHeight || line.doubleWidth,
        ));
      }
    }
    return out;
  }

  static int _lineHeight(ReceiptLine line, img.BitmapFont base, img.BitmapFont big) {
    switch (line.kind) {
      case ReceiptLineKind.feed:
        return base.lineHeight * line.count;
      case ReceiptLineKind.rule:
        return base.lineHeight;
      case ReceiptLineKind.text:
        return (line.doubleHeight || line.doubleWidth) ? big.lineHeight : base.lineHeight;
    }
  }

  /// Font terbesar yang satu karakternya masih muat dalam satu sel.
  static img.BitmapFont _fontForCell(int cellWidth) {
    if (_advance(img.arial24) <= cellWidth) return img.arial24;
    return img.arial14;
  }

  static img.BitmapFont _nextFontUp(img.BitmapFont font) {
    return font == img.arial14 ? img.arial24 : img.arial48;
  }

  /// Lebar maju satu digit, dipakai sebagai lebar sel monospace.
  static int _advance(img.BitmapFont font) {
    return font.characters[0x30]?.xAdvance ?? (font.size ~/ 2);
  }

  static int _measureText(img.BitmapFont font, String text) {
    int width = 0;
    for (final code in text.codeUnits) {
      width += font.characters[code]?.xAdvance ?? (font.size ~/ 2);
    }
    return width;
  }

  static void _drawText(
    img.Image canvas,
    String text,
    img.BitmapFont font,
    int x,
    int y,
    img.Color color, {
    bool bold = false,
  }) {
    img.drawString(canvas, text, font: font, x: x, y: y, color: color);
    if (bold) {
      // Paket image tidak punya varian tebal; ditimpa 1px ke kanan, meniru
      // double-strike pada printer dot matrix.
      img.drawString(canvas, text, font: font, x: x + 1, y: y, color: color);
    }
  }

  static void _drawMonospace(
    img.Image canvas,
    String text,
    img.BitmapFont font,
    int x,
    int y,
    int cellWidth,
    img.Color color, {
    bool bold = false,
  }) {
    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == ' ') continue;
      _drawText(canvas, ch, font, x + i * cellWidth, y, color, bold: bold);
    }
  }

  static String _centerPad(String text, int maxChar) {
    if (text.length >= maxChar) return text;
    return ' ' * ((maxChar - text.length) ~/ 2) + text;
  }

  static PosAlign _toPosAlign(ReceiptAlign align) {
    switch (align) {
      case ReceiptAlign.left:
        return PosAlign.left;
      case ReceiptAlign.center:
        return PosAlign.center;
      case ReceiptAlign.right:
        return PosAlign.right;
    }
  }

  static ReceiptLine _totalLine(String label, String value, int maxChar) {
    return ReceiptLine.text(_formatTotalLine(label, value, maxChar), align: ReceiptAlign.right);
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
