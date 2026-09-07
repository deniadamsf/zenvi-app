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
void main() {
  const size = 1024;

  // Teal merek yang sama dengan AppColors.brand. Sebelumnya berkas ini memakai
  // #00796B (teal Material lama) sementara pubspec memakai #0D7C83 dan aplikasi
  // memakai #0D9488 - tiga teal berbeda untuk satu lambang yang sama.
  final brandTeal = img.ColorRgba8(0x0D, 0x94, 0x88, 255);
  final whiteColor = img.ColorRgba8(255, 255, 255, 255);
  final transparentColor = img.ColorRgba8(0, 0, 0, 0);

  Directory('assets/images').createSync(recursive: true);

  // 1. Logo penuh (dipakai iOS dan ikon legacy Android)
  final solidImage = img.Image(width: size, height: size, numChannels: 4);
  img.fill(solidImage, color: brandTeal);
  _drawZenviTriangle(solidImage, size, whiteColor, 0.255, 0.098);
  File('assets/images/logo.png').writeAsBytesSync(img.encodePng(solidImage));
  print('Generated assets/images/logo.png');

  // 2. Lapisan depan ikon adaptif Android.
  //
  // Padding di sini sengaja KECIL. Zona aman sudah diurus di tempat lain:
  // mipmap-anydpi-v26/ic_launcher.xml membungkus lapisan ini dengan inset 16%,
  // yang menyisakan 68% kanvas - sudah di atas 66% yang dijamin selalu terlihat
  // oleh topeng peluncur. Memberi padding besar di sini berarti lambangnya
  // ter-inset DUA KALI, dan itu penyebab ikonnya terlihat kecil di layar depan.
  //
  // Garisnya juga dipertebal mengikuti lambang yang membesar: ketebalan diukur
  // terhadap kanvas, jadi kalau angkanya tidak ikut naik, lambang yang lebih
  // besar justru terlihat lebih kurus.
  final foregroundImage = img.Image(width: size, height: size, numChannels: 4);
  img.fill(foregroundImage, color: transparentColor);
  _drawZenviTriangle(foregroundImage, size, whiteColor, 0.215, 0.115);
  File('assets/images/logo_foreground.png').writeAsBytesSync(img.encodePng(foregroundImage));
  print('Generated assets/images/logo_foreground.png');

  // 3. Logo splash
  const splashSize = 512;
  final splashImage = img.Image(width: splashSize, height: splashSize, numChannels: 4);
  img.fill(splashImage, color: transparentColor);
  _drawZenviTriangle(splashImage, splashSize, whiteColor, 0.245, 0.10);

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

  final ax = padding, ay = padding;                    // sudut kiri atas
  final bx = size - padding, by = padding;             // sudut kanan atas
  final cx = size / 2.0, cy = size - padding * 1.15;   // ujung bawah

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
