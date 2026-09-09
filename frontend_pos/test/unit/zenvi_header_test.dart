import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_pos/widgets/zenvi_header.dart';

/// Jatah tinggi slot aksi. Sekaligus ukuran minimum sasaran sentuh yang nyaman,
/// jadi aksi setinggi ini harus tergambar utuh - bukan dipangkas diam-diam.
const double kActionSlotHeight = 44;

Widget wrap(Widget action, {double width = 392}) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(padding: EdgeInsets.only(top: 40)),
      child: SizedBox(
        width: width,
        child: Scaffold(
          appBar: ZenviHeader(
            title: 'Antrean Pesanan',
            actions: [action],
          ),
          body: const SizedBox(),
        ),
      ),
    ),
  );
}

Widget block(double height) => SizedBox(
      key: const Key('aksi'),
      height: height,
      width: 120,
      child: const ColoredBox(color: Color(0xFF0D7C83)),
    );

void main() {
  group('Slot aksi header tidak memotong isinya', () {
    testWidgets('aksi setinggi jatah slot tergambar utuh', (tester) async {
      // Regresi: slot aksi dulu dikunci maxHeight 38. Chip mode di layar KDS
      // tingginya 46,4px (ikon+teks 18,4 + padding 12 + margin 16), jadi 8,4px
      // terbawahnya hilang - tepi bawah dan separuh hurufnya terpotong, tanpa
      // satu pun peringatan overflow yang menunjukkan penyebabnya.
      await tester.pumpWidget(wrap(block(kActionSlotHeight)));

      expect(tester.getSize(find.byKey(const Key('aksi'))).height, kActionSlotHeight);
    });

    testWidgets('tidak melempar overflow', (tester) async {
      await tester.pumpWidget(wrap(block(kActionSlotHeight)));

      expect(tester.takeException(), isNull);
    });

    testWidgets('aksi setinggi jatah slot masih di dalam header', (tester) async {
      // Kalau tidak, masalahnya cuma pindah dari chip yang terpotong ke header
      // yang jebol.
      await tester.pumpWidget(wrap(block(kActionSlotHeight)));

      final actionBottom = tester.getRect(find.byKey(const Key('aksi'))).bottom;
      final headerBottom = tester.getRect(find.byType(ZenviHeader)).bottom;

      expect(actionBottom, lessThanOrEqualTo(headerBottom));
    });

    testWidgets('aksi yang jauh lebih tinggi tetap dibatasi, header tidak ikut molor',
        (tester) async {
      // Batas itu memang ada gunanya: satu aksi kelewat tinggi tidak boleh
      // menarik seluruh header ikut memanjang.
      await tester.pumpWidget(wrap(block(200)));

      expect(tester.getSize(find.byKey(const Key('aksi'))).height, kActionSlotHeight);
    });
  });
}
