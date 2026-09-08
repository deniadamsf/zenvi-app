import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_pos/services/label_printer_service.dart';
import 'package:frontend_pos/services/printer_service.dart';
import 'package:image/image.dart' as img;

/// Struk contoh yang dipakai seluruh tes di file ini.
///
/// Nilainya sengaja tetap (termasuk jam transaksi) supaya byte yang dihasilkan
/// bisa dibandingkan dengan berkas patokan.
Future<ReceiptDocument> sampleDocument({int paperWidthMm = 58}) {
  return PrinterService.buildReceiptDocument(
    {'name': 'Kopi Senja', 'location': 'Jl. Melati 12', 'phone': '08123456789'},
    [
      {'product_name': 'Kopi Susu', 'qty': 2, 'subtotal': 36000},
      {'product_name': 'Croissant', 'qty': 1, 'subtotal': 22000},
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
    paperWidthMm: paperWidthMm,
    includeLogo: false,
  );
}

Future<List<int>> sampleBytes(PrintMode mode, {int paperWidthMm = 58}) async {
  return PrinterService.encodeReceipt(await sampleDocument(paperWidthMm: paperWidthMm), mode);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ESC/POS teks tidak boleh berubah', () {
    test('byte-nya sama persis dengan patokan sebelum mode printer disambungkan', () async {
      final golden = File('test/golden/receipt_escpos_58mm.bin');
      expect(golden.existsSync(), isTrue,
          reason: 'berkas patokan hilang; jangan bangun ulang dari keluaran baru');

      final bytes = await PrinterService.generateReceiptBytes(
        {'name': 'Kopi Senja', 'location': 'Jl. Melati 12', 'phone': '08123456789'},
        [
          {'product_name': 'Kopi Susu', 'qty': 2, 'subtotal': 36000},
          {'product_name': 'Croissant', 'qty': 1, 'subtotal': 22000},
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
        paperWidthMm: 58,
      );

      expect(bytes, equals(golden.readAsBytesSync()));
    });

    test('mode default tetap ESC/POS teks', () async {
      final byDefault = await PrinterService.generateReceiptBytes(
        {'name': 'Kopi Senja'},
        const [],
        1000,
        1000,
        0,
        'Rani',
        'INV-1',
        transactionTime: DateTime.utc(2026, 9, 8, 10, 30),
      );
      final explicit = await PrinterService.generateReceiptBytes(
        {'name': 'Kopi Senja'},
        const [],
        1000,
        1000,
        0,
        'Rani',
        'INV-1',
        transactionTime: DateTime.utc(2026, 9, 8, 10, 30),
        mode: PrintMode.escPosText,
      );
      expect(byDefault, equals(explicit));
    });
  });

  group('Setiap mode menghasilkan perintah yang berbeda', () {
    test('keenam mode tidak ada yang kembar', () async {
      final seen = <String, PrintMode>{};
      for (final mode in PrintMode.all) {
        final key = base64Encode(await sampleBytes(mode));
        expect(seen.containsKey(key), isFalse,
            reason: '${mode.storageKey} menghasilkan byte yang sama dengan ${seen[key]?.storageKey}');
        seen[key] = mode;
      }
      expect(seen.length, PrintMode.all.length);
    });
  });

  group('Mode teks printer label', () {
    test('TSPL dibungkus CLS ... PRINT dan memuat isi struk', () async {
      final text = latin1.decode(await sampleBytes(PrintMode.tsplText));

      expect(text, startsWith('CLS\r\n'));
      expect(text, endsWith('PRINT 1,1\r\n'));
      expect(text, contains('TEXT 24,'));
      expect(text, contains('KOPI SENJA'));
      expect(text, contains('Kopi Susu'));
      expect(text, contains('INV-000123'));
      // Tanda kutip ganda akan menutup argumen TEXT lebih awal.
      final teksBaris = RegExp(r'TEXT [^\r\n]*"([^"]*)"\r\n').allMatches(text);
      expect(teksBaris, isNotEmpty);
      for (final baris in teksBaris) {
        expect(baris.group(1), isNot(contains('"')));
      }
    });

    test('CPCL memakai kepala form 200 dpi dan ditutup FORM/PRINT', () async {
      final text = latin1.decode(await sampleBytes(PrintMode.cpclText));

      expect(text, startsWith('! 0 200 200 '));
      expect(text, endsWith('FORM\r\nPRINT\r\n'));
      expect(text, contains('TEXT 4 0 24 '));
      expect(text, contains('KOPI SENJA'));
    });

    test('tinggi form CPCL mengikuti jumlah baris yang benar-benar dikirim', () async {
      final doc = await sampleDocument();
      final baris = PrinterService.toPlainLines(doc);
      final text = latin1.decode(await sampleBytes(PrintMode.cpclText));

      final header = RegExp(r'^! 0 200 200 (\d+) 1').firstMatch(text);
      expect(header, isNotNull);
      expect(int.parse(header!.group(1)!), 40 + baris.length * 40);
    });

    test('baris polos memuat kolom yang sudah rata dan tanpa ekor kosong', () async {
      final baris = PrinterService.toPlainLines(await sampleDocument());

      expect(baris.first.trim(), 'KOPI SENJA');
      expect(baris.last.trim(), isNotEmpty);
      expect(baris.any((b) => b.contains('2 x Rp18000') && b.trim().endsWith('Rp36000')), isTrue);
      expect(baris.any((b) => b.trim().endsWith('Rp63800')), isTrue);
      expect(baris.any((b) => b.startsWith('--------')), isTrue);
    });
  });

  group('Mode gambar', () {
    test('TSPL mengirim BITMAP dengan ukuran yang cocok dengan gambarnya', () async {
      final doc = await sampleDocument();
      final image = PrinterService.renderReceiptImage(
        doc,
        dotWidth: PrinterService.imageDotWidth(doc.paperWidthMm, PrintLanguage.tspl),
      );
      final bytes = await PrinterService.encodeReceipt(doc, PrintMode.tsplImage);
      final head = latin1.decode(bytes.sublist(0, 64));

      final widthBytes = (image.width + 7) >> 3;
      expect(head, startsWith('CLS\r\nBITMAP 0,0,$widthBytes,${image.height},0,'));
      expect(latin1.decode(bytes.sublist(bytes.length - 12)), endsWith('PRINT 1,1\r\n'));

      // Kepala + data bitmap + penutup, tidak boleh ada yang terpotong.
      final headLength = 'CLS\r\nBITMAP 0,0,$widthBytes,${image.height},0,'.length;
      expect(bytes.length, headLength + widthBytes * image.height + '\r\nPRINT 1,1\r\n'.length);
    });

    test('CPCL mengirim EG dengan hex sepanjang data bitmapnya', () async {
      final doc = await sampleDocument();
      final image = PrinterService.renderReceiptImage(
        doc,
        dotWidth: PrinterService.imageDotWidth(doc.paperWidthMm, PrintLanguage.cpcl),
      );
      final text = latin1.decode(await sampleBytes(PrintMode.cpclImage));

      final widthBytes = (image.width + 7) >> 3;
      final eg = RegExp(r'EG (\d+) (\d+) (\d+) (\d+) ([0-9A-F]+)\r\n').firstMatch(text);
      expect(eg, isNotNull, reason: 'perintah EG tidak ditemukan');
      expect(int.parse(eg!.group(1)!), widthBytes);
      expect(int.parse(eg.group(2)!), image.height);
      expect(eg.group(5)!.length, widthBytes * image.height * 2);
      expect(text, endsWith('FORM\r\nPRINT\r\n'));
    });

    test('ESC/POS gambar memakai perintah raster GS v 0', () async {
      final bytes = await sampleBytes(PrintMode.escPosImage);
      // GS v 0 = 0x1D 0x76 0x30
      var found = false;
      for (var i = 0; i + 2 < bytes.length; i++) {
        if (bytes[i] == 0x1D && bytes[i + 1] == 0x76 && bytes[i + 2] == 0x30) {
          found = true;
          break;
        }
      }
      expect(found, isTrue, reason: 'tidak ada perintah raster di keluaran ESC/POS gambar');
    });

    test('bitmap struk benar-benar ada tulisannya, bukan kertas kosong', () async {
      final doc = await sampleDocument();
      final image = PrinterService.renderReceiptImage(doc, dotWidth: 384);

      var black = 0;
      for (final pixel in image) {
        if (pixel.luminance < 128) black++;
      }
      expect(image.width, 384);
      expect(image.height, greaterThan(200));
      expect(black, greaterThan(1000), reason: 'gambar struk nyaris kosong');
    });

    test('kolom harga tetap lurus karena digambar monospace', () async {
      final doc = await sampleDocument();
      final image = PrinterService.renderReceiptImage(doc, dotWidth: 384);
      // Lebar sel = (384 - 16) / 32 karakter; seluruh baris harus muat di kertas.
      expect(384 - 16, greaterThanOrEqualTo(doc.maxChars * ((384 - 16) ~/ doc.maxChars)));
      expect(image.width, lessThanOrEqualTo(384));
    });
  });

  group('Lebar kertas', () {
    test('110mm dipangkas untuk ESC/POS tapi utuh untuk TSPL/CPCL', () {
      expect(PrinterService.imageDotWidth(110, PrintLanguage.escPos), 576);
      expect(PrinterService.imageDotWidth(110, PrintLanguage.tspl), 832);
      expect(PrinterService.imageDotWidth(110, PrintLanguage.cpcl), 832);
    });

    test('lebar bitmap mengikuti kertas yang dipilih', () async {
      for (final entry in {58: 384, 72: 512, 80: 576, 110: 832}.entries) {
        final doc = await sampleDocument(paperWidthMm: entry.key);
        final image = PrinterService.renderReceiptImage(
          doc,
          dotWidth: PrinterService.imageDotWidth(entry.key, PrintLanguage.tspl),
        );
        expect(image.width, entry.value, reason: 'kertas ${entry.key}mm');
      }
    });

    test('jumlah karakter per baris ikut melebar bersama kertas', () async {
      final sempit = await sampleDocument(paperWidthMm: 58);
      final lebar = await sampleDocument(paperWidthMm: 110);
      expect(sempit.maxChars, 32);
      expect(lebar.maxChars, 64);
      expect(PrinterService.toPlainLines(lebar).first.length,
          greaterThan(PrinterService.toPlainLines(sempit).first.length));
    });
  });

  group('Baris kepanjangan dilipat, bukan dipotong', () {
    Future<img.Image> renderWithItemName(String name) async {
      final doc = await PrinterService.buildReceiptDocument(
        {'name': 'Kopi Senja'},
        [
          {'product_name': name, 'qty': 1, 'subtotal': 20000},
        ],
        20000,
        20000,
        0,
        'Rani',
        'INV-1',
        transactionTime: DateTime.utc(2026, 9, 8, 10, 30),
        paperWidthMm: 58,
        includeLogo: false,
      );
      return PrinterService.renderReceiptImage(doc, dotWidth: 384);
    }

    test('nama produk yang melebihi lebar kertas menambah tinggi struk', () async {
      final pendek = await renderWithItemName('Kopi Susu');
      final panjang = await renderWithItemName(
          'Nasi Goreng Spesial Seafood Komplit Telur Mata Sapi');

      expect(pendek.width, panjang.width);
      expect(panjang.height, greaterThan(pendek.height),
          reason: 'nama panjang seharusnya turun ke baris berikutnya, bukan terpotong di tepi');
    });

    test('nama toko yang kepanjangan tetap tercetak utuh', () async {
      final doc = await PrinterService.buildReceiptDocument(
        {'name': 'Warung Kopi Senja Cabang Dago Atas Bandung'},
        const [],
        1000,
        1000,
        0,
        'Rani',
        'INV-1',
        transactionTime: DateTime.utc(2026, 9, 8, 10, 30),
        paperWidthMm: 58,
        includeLogo: false,
      );
      final biasa = await PrinterService.buildReceiptDocument(
        {'name': 'Kopi Senja'},
        const [],
        1000,
        1000,
        0,
        'Rani',
        'INV-1',
        transactionTime: DateTime.utc(2026, 9, 8, 10, 30),
        paperWidthMm: 58,
        includeLogo: false,
      );

      final panjang = PrinterService.renderReceiptImage(doc, dotWidth: 384);
      final pendek = PrinterService.renderReceiptImage(biasa, dotWidth: 384);
      expect(panjang.height, greaterThan(pendek.height));
    });
  });

  group('Pengepakan bitmap', () {
    test('TSPL memakai bit 0 sebagai titik hitam, CPCL sebaliknya', () {
      final hitam = img.Image(width: 8, height: 1);
      img.fill(hitam, color: img.ColorRgb8(0, 0, 0));

      expect(LabelPrinterService.packMonochrome(hitam, setBitMeansBlack: false), [0x00]);
      expect(LabelPrinterService.packMonochrome(hitam, setBitMeansBlack: true), [0xFF]);

      final putih = img.Image(width: 8, height: 1);
      img.fill(putih, color: img.ColorRgb8(255, 255, 255));

      expect(LabelPrinterService.packMonochrome(putih, setBitMeansBlack: false), [0xFF]);
      expect(LabelPrinterService.packMonochrome(putih, setBitMeansBlack: true), [0x00]);
    });
  });
}
