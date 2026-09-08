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
  /// ESC/POS — standar printer struk.
  escPos,

  /// TSPL / TSPL2 — Xprinter, Eppos, TSC label printer.
  tspl,

  /// CPCL — Zebra dan sebagian printer label mobile.
  cpcl,
}

/// Cara isi struk dikirim: sebagai perintah teks native printer, atau
/// dirender lebih dulu jadi gambar bitmap lalu dikirim sebagai satu blok.
enum PrintRender { text, image }

/// Kombinasi bahasa + cara render yang dipakai printer.
class PrintMode {
  final PrintLanguage language;
  final PrintRender render;

  const PrintMode(this.language, this.render);

  static const PrintMode escPosText = PrintMode(PrintLanguage.escPos, PrintRender.text);
  static const PrintMode escPosImage = PrintMode(PrintLanguage.escPos, PrintRender.image);
  static const PrintMode tsplText = PrintMode(PrintLanguage.tspl, PrintRender.text);
  static const PrintMode tsplImage = PrintMode(PrintLanguage.tspl, PrintRender.image);
  static const PrintMode cpclText = PrintMode(PrintLanguage.cpcl, PrintRender.text);
  static const PrintMode cpclImage = PrintMode(PrintLanguage.cpcl, PrintRender.image);

  /// Urutan tampil di layar pengaturan.
  static const List<PrintMode> all = [
    escPosText,
    escPosImage,
    tsplText,
    tsplImage,
    cpclText,
    cpclImage,
  ];

  String get storageKey => '${language.name}_${render.name}';

  static PrintMode fromStorage(String? value) {
    return all.firstWhere(
      (mode) => mode.storageKey == value,
      orElse: () => escPosText,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PrintMode && other.language == language && other.render == render;

  @override
  int get hashCode => Object.hash(language, render);
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

  /// Perintah TSPL memakai font bawaan printer (tanpa bitmap).
  ///
  /// Payload-nya hanya puluhan byte, jadi tes ini bebas dari masalah
  /// pengiriman data bitmap yang besar — kalau ini tercetak, bahasa printer
  /// sudah pasti TSPL.
  static List<int> buildTsplText(List<String> lines) {
    final List<int> bytes = [];
    bytes.addAll(latin1.encode('CLS\r\n'));

    int y = 24;
    for (final line in lines) {
      final safe = line.replaceAll('"', "'");
      bytes.addAll(latin1.encode('TEXT 24,$y,"3",0,1,1,"$safe"\r\n'));
      y += 40;
    }

    bytes.addAll(latin1.encode('PRINT 1,1\r\n'));
    return bytes;
  }

  /// Perintah CPCL memakai font bawaan printer (tanpa bitmap).
  static List<int> buildCpclText(List<String> lines, {int dpi = 200}) {
    final int formHeight = 40 + lines.length * 40;
    final List<int> bytes = [];
    bytes.addAll(latin1.encode('! 0 $dpi $dpi $formHeight 1\r\n'));

    int y = 20;
    for (final line in lines) {
      bytes.addAll(latin1.encode('TEXT 4 0 24 $y $line\r\n'));
      y += 40;
    }

    bytes.addAll(latin1.encode('FORM\r\n'));
    bytes.addAll(latin1.encode('PRINT\r\n'));
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

}
