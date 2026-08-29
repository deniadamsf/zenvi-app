import 'dart:convert';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

/// Bahasa perintah printer thermal.
///
/// Printer struk (58/80mm) umumnya ESC/POS, sedangkan printer label/resi
/// (Eppos, Xprinter, TSC, Zebra — kertas 100-110mm) umumnya TSPL atau CPCL.
/// Perintah ESC/POS yang dikirim ke printer TSPL/CPCL tidak dikenali, sehingga
/// kertas tetap jalan tapi tidak ada tulisan yang tercetak.
enum PrintLanguage {
  /// ESC/POS command teks (default printer struk).
  escPosText,

  /// ESC/POS tapi struk dirender jadi gambar raster (GS v 0).
  /// Dipakai kalau printer ESC/POS-nya tidak merender command teks.
  escPosImage,

  /// TSPL / TSPL2 — Eppos, Xprinter, TSC label printer.
  tspl,

  /// CPCL — Zebra dan sebagian printer label mobile.
  cpcl,
}

extension PrintLanguageCodec on PrintLanguage {
  String get storageKey => name;

  static PrintLanguage fromStorage(String? value) {
    return PrintLanguage.values.firstWhere(
      (lang) => lang.name == value,
      orElse: () => PrintLanguage.escPosText,
    );
  }
}

/// Builder perintah cetak berbasis bitmap untuk printer label (TSPL/CPCL)
/// dan mode raster ESC/POS.
class LabelPrinterService {
  /// Ubah gambar jadi baris-baris bit 1bpp.
  ///
  /// [setBitMeansBlack] mengikuti konvensi masing-masing bahasa printer:
  /// pada TSPL bit bernilai 0 = titik hitam, sedangkan pada CPCL EG
  /// bit bernilai 1 = titik hitam.
  static List<int> packMonochrome(img.Image src, {required bool setBitMeansBlack}) {
    final int widthBytes = (src.width + 7) >> 3;
    final List<int> data = List<int>.filled(
      widthBytes * src.height,
      setBitMeansBlack ? 0x00 : 0xFF,
    );

    for (int y = 0; y < src.height; y++) {
      final int rowOffset = y * widthBytes;
      for (int x = 0; x < src.width; x++) {
        final pixel = src.getPixel(x, y);
        // Piksel transparan dianggap putih (tidak dicetak).
        final bool isBlack = pixel.a >= 128 && pixel.luminance < 128;
        if (!isBlack) continue;

        final int index = rowOffset + (x >> 3);
        final int mask = 0x80 >> (x & 7);
        if (setBitMeansBlack) {
          data[index] |= mask;
        } else {
          data[index] &= (~mask) & 0xFF;
        }
      }
    }
    return data;
  }

  /// Perintah TSPL untuk mencetak satu gambar.
  ///
  /// Sengaja tidak mengirim SIZE/GAP supaya printer memakai kalibrasi label
  /// yang sudah tersimpan di firmware (kalibrasi yang sama dipakai aplikasi
  /// resi ekspedisi), jadi tidak perlu tahu ukuran label persisnya.
  static List<int> buildTsplImage(img.Image image, {int x = 0, int y = 0}) {
    final int widthBytes = (image.width + 7) >> 3;
    final List<int> data = packMonochrome(image, setBitMeansBlack: false);

    final List<int> bytes = [];
    bytes.addAll(latin1.encode('CLS\r\n'));
    bytes.addAll(latin1.encode('BITMAP $x,$y,$widthBytes,${image.height},0,'));
    bytes.addAll(data);
    bytes.addAll(latin1.encode('\r\n'));
    bytes.addAll(latin1.encode('PRINT 1,1\r\n'));
    return bytes;
  }

  /// Perintah CPCL untuk mencetak satu gambar.
  static List<int> buildCpclImage(img.Image image, {int x = 0, int y = 0, int dpi = 200}) {
    final int widthBytes = (image.width + 7) >> 3;
    final List<int> data = packMonochrome(image, setBitMeansBlack: true);

    final StringBuffer hex = StringBuffer();
    for (final byte in data) {
      hex.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
    }

    final int formHeight = image.height + y + 16;
    final List<int> bytes = [];
    bytes.addAll(latin1.encode('! 0 $dpi $dpi $formHeight 1\r\n'));
    bytes.addAll(latin1.encode('EG $widthBytes ${image.height} $x $y ${hex.toString()}\r\n'));
    bytes.addAll(latin1.encode('FORM\r\n'));
    bytes.addAll(latin1.encode('PRINT\r\n'));
    return bytes;
  }

  /// Perintah ESC/POS raster (GS v 0) untuk mencetak satu gambar.
  static Future<List<int>> buildEscPosImage(img.Image image, PaperSize paperSize) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final List<int> bytes = [];
    bytes.addAll(generator.reset());
    bytes.addAll(generator.imageRaster(image, align: PosAlign.center));
    bytes.addAll(generator.feed(3));
    return bytes;
  }

  /// Gambar sampel untuk mengetes bahasa printer.
  ///
  /// Isinya sengaja menyebut nama mode supaya user tahu perintah mana yang
  /// dimengerti printernya ketika salah satu tes berhasil tercetak.
  static img.Image buildDiagnosticImage({
    required String modeLabel,
    required int dotWidth,
    required String storeName,
    required String timestamp,
  }) {
    const int height = 260;
    final image = img.Image(width: dotWidth, height: height);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    final black = img.ColorRgb8(0, 0, 0);

    img.drawRect(
      image,
      x1: 2,
      y1: 2,
      x2: dotWidth - 3,
      y2: height - 3,
      color: black,
      thickness: 3,
    );

    img.drawString(image, storeName, font: img.arial48, x: 20, y: 22, color: black);
    img.drawString(image, modeLabel, font: img.arial24, x: 20, y: 96, color: black);
    img.drawString(image, timestamp, font: img.arial24, x: 20, y: 132, color: black);
    img.drawString(image, 'Lebar cetak: $dotWidth dot', font: img.arial24, x: 20, y: 168, color: black);

    // Garis penuh sebagai penanda batas kanan area cetak.
    img.drawRect(
      image,
      x1: 20,
      y1: 210,
      x2: dotWidth - 21,
      y2: 226,
      color: black,
      thickness: 16,
    );

    return image;
  }
}
