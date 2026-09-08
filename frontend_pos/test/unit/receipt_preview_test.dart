import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_pos/services/label_printer_service.dart';
import 'package:frontend_pos/services/printer_service.dart';
import 'package:image/image.dart' as img;

/// Menggambar struk mode bitmap ke PNG di `build/receipt_preview/`.
///
/// Mode gambar (TSPL/CPCL/raster ESC-POS) hanya bisa dibuktikan benar dengan
/// melihat hasilnya, dan tidak semua orang punya printer label di meja. Berkas
/// PNG ini adalah bitmap yang persis sama dengan yang dikirim ke printer, jadi
/// masalah tata letak - kolom melenceng, baris terpotong, teks tumpang tindih -
/// ketahuan tanpa perlu mencetak selembar pun.
///
///   flutter test test/unit/receipt_preview_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render pratinjau struk bitmap', () async {
    final map = jsonDecode(File('assets/translations/id.json').readAsStringSync())
        as Map<String, dynamic>;
    Localization.load(const Locale('id'), translations: Translations(map));

    final outDir = Directory('build/receipt_preview');
    outDir.createSync(recursive: true);

    for (final mm in [58, 72, 80, 110]) {
      final doc = await PrinterService.buildReceiptDocument(
        {'name': 'Kopi Senja', 'location': 'Jl. Melati 12, Bandung', 'phone': '08123456789'},
        [
          {'product_name': 'Nasi Goreng Spesial Seafood Komplit Telur', 'qty': 2, 'subtotal': 36000},
          {'product_name': 'Croissant Almond', 'qty': 1, 'subtotal': 22000},
        ],
        63800,
        58000,
        5800,
        'Rani',
        'INV-000123',
        transactionTime: DateTime.utc(2026, 9, 8, 10, 30),
        paymentMethod: 'cash',
        cashReceived: 70000,
        cashChange: 6200,
        memberName: 'Budi',
        memberPhone: '08987654321',
        memberDiscountAmount: 2000,
        paperWidthMm: mm,
        includeLogo: false,
      );

      final image = PrinterService.renderReceiptImage(
        doc,
        dotWidth: PrinterService.imageDotWidth(mm, PrintLanguage.tspl),
      );

      File('${outDir.path}/struk_${mm}mm.png').writeAsBytesSync(img.encodePng(image));
      expect(image.width, PrinterService.imageDotWidth(mm, PrintLanguage.tspl));
    }
  });
}
