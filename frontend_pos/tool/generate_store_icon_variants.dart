import 'dart:io';

import 'package:image/image.dart' as img;

import 'generate_icons.dart' show drawZenviTriangle;

/// Membuat beberapa pilihan ikon Play Store untuk dibandingkan.
///
///   dart run tool/generate_store_icon_variants.dart
///
/// Kenapa ikon toko boleh berbeda ukuran dari ikon peluncur: ikon 512x512 di
/// Play Store hanya dibulatkan sudutnya, sementara peluncur memasang masker
/// yang jauh lebih dalam (lingkaran, kotak membulat MIUI, dan lain-lain).
/// Zona aman 71% radius yang wajib dipatuhi ikon peluncur membuat lambang di
/// halaman toko tampak kekecilan - mengambang di tengah bidang teal yang luas.
///
/// Hasilnya dua macam:
///   - berkas 512x512 siap unggah, satu per pilihan
///   - satu lembar perbandingan, semuanya SUDAH DIPOTONG masker kotak-membulat
///     seperti di Play Console dan disertai contoh ukuran kecil, karena begitu
///     ikon ini benar-benar dilihat orang di daftar aplikasi.
///
/// Setelah satu pilihan disepakati, angkanya dipindahkan ke bagian ikon toko
/// di tool/generate_icons.dart.
void main() {
  final brandTeal = img.ColorRgba8(0x0D, 0x7C, 0x83, 255);
  final white = img.ColorRgba8(255, 255, 255, 255);

  final variants = <_Variant>[
    _Variant('A', 'Sekarang', 0.345, 0.068),
    _Variant('B', 'Lebih besar', 0.285, 0.072),
    _Variant('C', 'Besar & tegas', 0.265, 0.082),
    _Variant('D', 'Penuh', 0.225, 0.078),
    _Variant('E', 'Besar & ramping', 0.265, 0.056),
    _Variant('F', 'Terbalik', 0.265, 0.082, background: white, mark: brandTeal),
  ];

  final outDir = Directory('../playstore_assets/variants');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  const size = 512;
  final rendered = <String, img.Image>{};

  for (final variant in variants) {
    final image = img.Image(width: size, height: size, numChannels: 4);
    img.fill(image, color: variant.background ?? brandTeal);
    drawZenviTriangle(
      image,
      size,
      variant.mark ?? white,
      variant.padding,
      variant.thickness,
      heightRatio: variant.heightRatio,
    );
    rendered[variant.id] = image;
    File('${outDir.path}/icon_${variant.id}.png').writeAsBytesSync(img.encodePng(image));

    print('icon_${variant.id}.png  ${variant.label}  '
        '(lambang ${_markWidthPercent(image, variant).toStringAsFixed(0)}% lebar kanvas)');
  }

  _writeSheet(variants, rendered, '${outDir.path}/perbandingan.png');
  print('Generated ${outDir.path}/perbandingan.png');
}

class _Variant {
  const _Variant(
    this.id,
    this.label,
    this.padding,
    this.thickness, {
    this.heightRatio = 0.90,
    this.background,
    this.mark,
  });

  final String id;
  final String label;
  final double padding;
  final double thickness;
  final double heightRatio;
  final img.Color? background;
  final img.Color? mark;
}

/// Lebar lambang yang SEBENARNYA, diukur dari gambar jadinya.
///
/// Tidak dihitung dari `1 - padding * 2`: garis lambang digambar melebar ke
/// luar sejauh setengah ketebalannya, jadi angka nominal itu selalu lebih
/// kecil daripada yang terlihat - dan angka keterangan yang meleset lebih
/// menyesatkan daripada tidak ada angka sama sekali.
double _markWidthPercent(img.Image image, _Variant variant) {
  final background = variant.background;
  final isBackgroundWhite = background != null;

  var minX = image.width;
  var maxX = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      // Lambang putih di latar teal, atau sebaliknya pada varian terbalik.
      final isMark = isBackgroundWhite ? pixel.g < 160 : pixel.g > 200;
      if (!isMark) continue;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
    }
  }
  if (maxX < 0) return 0;
  return (maxX - minX + 1) / image.width * 100;
}

/// Lembar perbandingan: tiap sel berisi ikon besar bermasker, contoh ukuran
/// kecil di sampingnya, dan keterangannya.
void _writeSheet(
  List<_Variant> variants,
  Map<String, img.Image> rendered,
  String path,
) {
  const cellW = 340;
  const cellH = 320;
  const iconBig = 200;
  const iconSmall = 56;
  const cols = 3;
  final rows = (variants.length + cols - 1) ~/ cols;

  final sheet = img.Image(width: cellW * cols, height: cellH * rows, numChannels: 4);
  img.fill(sheet, color: img.ColorRgba8(0xF6, 0xF8, 0xFB, 255));

  for (var i = 0; i < variants.length; i++) {
    final variant = variants[i];
    final col = i % cols;
    final row = i ~/ cols;
    final originX = col * cellW + 26;
    final originY = row * cellH + 26;

    _drawMasked(
      sheet,
      img.copyResize(rendered[variant.id]!, width: iconBig, height: iconBig),
      originX,
      originY,
      iconBig,
    );

    // Contoh ukuran kecil: seperti yang terlihat di daftar aplikasi ponsel.
    _drawMasked(
      sheet,
      img.copyResize(rendered[variant.id]!, width: iconSmall, height: iconSmall),
      originX + iconBig + 26,
      originY + iconBig - iconSmall,
      iconSmall,
    );

    img.drawString(
      sheet,
      '${variant.id}. ${variant.label}',
      font: img.arial24,
      x: originX,
      y: originY + iconBig + 16,
      color: img.ColorRgba8(0x1A, 0x1A, 0x1A, 255),
    );

    img.drawString(
      sheet,
      'lambang ${_markWidthPercent(rendered[variant.id]!, variant).toStringAsFixed(0)}% lebar',
      font: img.arial14,
      x: originX,
      y: originY + iconBig + 44,
      color: img.ColorRgba8(0x60, 0x6A, 0x75, 255),
    );
  }

  File(path).writeAsBytesSync(img.encodePng(sheet));
}

/// Menempel ikon dengan sudut dibulatkan ~22% sisi, mendekati masker yang
/// dipakai Play Console.
void _drawMasked(img.Image sheet, img.Image icon, int originX, int originY, int size) {
  final radius = size * 0.22;

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      if (!_insideRounded(x.toDouble(), y.toDouble(), size.toDouble(), radius)) continue;
      final pixel = icon.getPixel(x, y);
      sheet.setPixelRgba(originX + x, originY + y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), 255);
    }
  }
}

bool _insideRounded(double x, double y, double size, double radius) {
  final cx = x < radius ? radius : (x > size - radius ? size - radius : x);
  final cy = y < radius ? radius : (y > size - radius ? size - radius : y);
  final dx = x - cx;
  final dy = y - cy;
  return dx * dx + dy * dy <= radius * radius;
}
