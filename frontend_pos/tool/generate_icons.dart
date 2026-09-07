import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Menggambar ulang ikon aplikasi dan logo splash.
///
///   dart run tool/generate_icons.dart
///   dart run flutter_launcher_icons
///
/// Ikonnya digambar, bukan berkas desain, supaya bisa disetel dari angka -
/// ketebalan dan besarnya tinggal diubah di sini lalu dibangun ulang.
// Yang menentukan lambang terpotong atau tidak BUKAN lebarnya, tapi jarak
// sudut terjauhnya dari pusat ikon. Peluncur memasang maskernya sendiri -
// kotak membulat, lingkaran, dan lain-lain - dan segitiga punya sudut yang
// menjulur ke arah tepi, tidak seperti lambang yang bentuknya membulat.
//
// Acuan terukur, dalam persen radius ikon:
//   83% -> terpotong di peluncur MIUI
//   71% -> aman di kotak membulat maupun lingkaran  (setelan sekarang)
void main() {
  const size = 1024;

  // Teal ikon: #0D7C83, sesuai pilihan pemilik produk.
  final brandTeal = img.ColorRgba8(0x0D, 0x7C, 0x83, 255);
  final whiteColor = img.ColorRgba8(255, 255, 255, 255);
  final transparentColor = img.ColorRgba8(0, 0, 0, 0);

  Directory('assets/images').createSync(recursive: true);

  // 1. Logo penuh (dipakai iOS dan ikon legacy Android)
  final solidImage = img.Image(width: size, height: size, numChannels: 4);
  img.fill(solidImage, color: brandTeal);
  _drawZenviTriangle(solidImage, size, whiteColor, 0.30, 0.076);
  File('assets/images/logo.png').writeAsBytesSync(img.encodePng(solidImage));
  print('Generated assets/images/logo.png');

  // 2. Lapisan depan ikon adaptif Android.
  //
  // PENTING: angka di sini TIDAK boleh disamakan dengan ikon legacy di atas.
  // Peluncur lama memakai mipmap/ic_launcher.png apa adanya, sedangkan ikon
  // adaptif masih disusutkan ke 68% oleh inset 16% di ic_launcher.xml. Padding
  // dan ketebalan di sini karena itu jauh lebih kecil - keduanya dibagi 0,68 -
  // supaya hasil di layar depan sama besar dan sama tebal di kedua jenis
  // peluncur. Ukuran akhir diverifikasi 63x57% (legacy) dan 66x60% (adaptif),
  // sepadan dengan lambang Play Console yang dipakai sebagai patokan.
  //
  // ANGKA ACUAN kalau ukurannya perlu disetel lagi. `padding` di sini diukur
  // terhadap kanvas berkas ini, BUKAN terhadap ikon yang akhirnya terlihat -
  // ic_launcher.xml masih menyusutkannya lagi ke 68% lewat inset 16%. Jadi
  // tinggi akhir di layar depan = tinggi di kanvas ini x 0,68.
  //
  //   padding 0,34  -> 36% kanvas -> 25% ikon  (versi lama, terlalu kecil)
  //   padding 0,215 -> 68% kanvas -> 46% ikon  (terlalu besar)
  //   padding 0,295 -> 55% kanvas -> 38% ikon  (sekarang)
  //
  // Perhatikan: XML ikon adaptif menambahkan inset 16% LAGI di atas padding ini,
  // jadi angka di sini bukan ukuran akhir di layar depan. Percobaan menurunkan
  // padding ke 0,215 membuat lambangnya jauh terlalu besar - kembali ke sekitar
  // nilai semula, hanya sedikit lebih besar dan sedikit lebih tebal.
  final foregroundImage = img.Image(width: size, height: size, numChannels: 4);
  img.fill(foregroundImage, color: transparentColor);
  _drawZenviTriangle(foregroundImage, size, whiteColor, 0.175, 0.112);
  File('assets/images/logo_foreground.png').writeAsBytesSync(img.encodePng(foregroundImage));
  print('Generated assets/images/logo_foreground.png');

  // 3. Logo splash
  const splashSize = 512;
  final splashImage = img.Image(width: splashSize, height: splashSize, numChannels: 4);
  img.fill(splashImage, color: transparentColor);
  _drawZenviTriangle(splashImage, splashSize, whiteColor, 0.29, 0.080);

  final splashDir = Directory('android/app/src/main/res/drawable');
  if (!splashDir.existsSync()) splashDir.createSync(recursive: true);
  File('android/app/src/main/res/drawable/ic_splash_logo.png').writeAsBytesSync(img.encodePng(splashImage));
  print('Generated android/app/src/main/res/drawable/ic_splash_logo.png');

  File('assets/images/splash_logo.png').writeAsBytesSync(img.encodePng(splashImage));
  print('Done all icon generation!');
}

/// Menggambar lambang Zenvi: segitiga terbalik bergaris tebal dengan celah di
/// sisi atas.
///
/// Dirasterkan per piksel, bukan dengan `drawLine` bertebal. `drawLine`
/// memberi ujung rata, jadi di tiap sudut tersisa tangga yang ikut membesar
/// begitu garisnya dipertebal - terlihat jelas pada ikon peluncur. Menguji
/// tiap piksel terhadap dua segitiga sebangun menghasilkan sudut yang benar
/// tanpa perlu menambal apa pun.
void _drawZenviTriangle(
  img.Image image,
  int size,
  img.Color color,
  double paddingFraction,
  double thicknessFraction,
) {
  final padding = size * paddingFraction;
  final thickness = size * thicknessFraction;

  // Tinggi lambang relatif terhadap lebarnya.
  //
  // Sempat disetel 1,3 (jangkung) dan hasilnya justru terlihat kurus. Patokan
  // sekarang lambang Play Console: sedikit lebih lebar daripada tinggi.
  const heightRatio = 0.90;
  final halfWidth = (size - padding * 2) / 2;
  final height = halfWidth * 2 * heightRatio;
  final top = (size - height) / 2;

  // Ujung bawah dulu ditaruh di `size - padding * 1.15`, jadi jarak ke tepi
  // bawah lebih lebar daripada ke tepi atas. Sekarang simetris, lalu seluruh
  // bentuk digeser TURUN sedikit.
  //
  // Geseran itu penyeimbang optis, bukan koreksi hitungan: segitiga terbalik
  // berat di bagian atas - sisi atasnya satu garis penuh, bawahnya cuma satu
  // titik. Ditaruh persis di tengah secara geometris, mata tetap membacanya
  // duduk terlalu tinggi di dalam petak peluncur.
  // Geseran halus untuk keseimbangan optis. Nilainya NEGATIF - menaikkan, bukan
  // menurunkan - karena ujung bawah yang lancip menjulur jauh lebih panjang dari
  // titik sudutnya daripada sisi atas yang tumpul, sehingga bentuk yang dipusatkan
  // secara hitungan tetap terlihat melorot. Diukur dari hasil jadinya: ruang atas
  // ~21%, ruang bawah ~17%.
  final nudge = size * -0.015;

  final ax = padding, ay = top + nudge;                    // sudut kiri atas
  final bx = size - padding, by = top + nudge;             // sudut kanan atas
  final cx = size / 2.0, cy = top + height + nudge;        // ujung bawah

  // Segitiga luar dan dalam adalah segitiga yang sama, diperbesar dan
  // diperkecil terhadap titik pusat lingkaran dalam. Menggeser tiap sudut ke
  // arah titik itu sama artinya dengan menggeser ketiga sisinya sejauh jarak
  // yang sama - itulah yang membuat tebal garisnya rata di semua sisi.
  final sa = _dist(bx, by, cx, cy);
  final sb = _dist(cx, cy, ax, ay);
  final sc = _dist(ax, ay, bx, by);
  final perimeter = sa + sb + sc;
  final ix = (sa * ax + sb * bx + sc * cx) / perimeter;
  final iy = (sa * ay + sb * by + sc * cy) / perimeter;
  final area = ((bx - ax) * (cy - ay) - (cx - ax) * (by - ay)).abs() / 2;
  final inradius = area / (perimeter / 2);

  final outer = (inradius + thickness / 2) / inradius;
  final inner = (inradius - thickness / 2) / inradius;

  double ox(double x) => ix + (x - ix) * outer;
  double oy(double y) => iy + (y - iy) * outer;
  double nx(double x) => ix + (x - ix) * inner;
  double ny(double y) => iy + (y - iy) * inner;

  final topWidth = bx - ax;
  final gapStart = ax + topWidth * 0.22;
  final gapEnd = ax + topWidth * 0.42;
  final gapBottom = ny(ay);

  // Tiga sampel per sumbu: tepi miringnya jadi halus tanpa membuat berkasnya
  // berat untuk dihitung.
  const samples = 3;
  const step = 1.0 / samples;

  for (var py = 0; py < size; py++) {
    for (var px = 0; px < size; px++) {
      var hits = 0;
      for (var sy = 0; sy < samples; sy++) {
        for (var sx = 0; sx < samples; sx++) {
          final x = px + (sx + 0.5) * step;
          final y = py + (sy + 0.5) * step;

          final inOuter = _inTriangle(x, y, ox(ax), oy(ay), ox(bx), oy(by), ox(cx), oy(cy));
          if (!inOuter) continue;
          final inInner = _inTriangle(x, y, nx(ax), ny(ay), nx(bx), ny(by), nx(cx), ny(cy));
          if (inInner) continue;
          // Celah di sisi atas - yang membedakan lambang ini dari segitiga biasa.
          if (x >= gapStart && x <= gapEnd && y <= gapBottom) continue;
          hits++;
        }
      }
      if (hits == 0) continue;

      final coverage = hits / (samples * samples);
      final existing = image.getPixel(px, py);
      image.setPixelRgba(
        px,
        py,
        color.r.toInt(),
        color.g.toInt(),
        color.b.toInt(),
        (existing.a + (255 - existing.a) * coverage).round().clamp(0, 255),
      );
    }
  }
}

double _dist(double x1, double y1, double x2, double y2) {
  final dx = x2 - x1, dy = y2 - y1;
  return math.sqrt(dx * dx + dy * dy);
}

bool _inTriangle(double px, double py, double ax, double ay, double bx, double by, double cx, double cy) {
  double sign(double x1, double y1, double x2, double y2, double x3, double y3) =>
      (x1 - x3) * (y2 - y3) - (x2 - x3) * (y1 - y3);

  final d1 = sign(px, py, ax, ay, bx, by);
  final d2 = sign(px, py, bx, by, cx, cy);
  final d3 = sign(px, py, cx, cy, ax, ay);
  final hasNeg = d1 < 0 || d2 < 0 || d3 < 0;
  final hasPos = d1 > 0 || d2 > 0 || d3 > 0;
  return !(hasNeg && hasPos);
}
