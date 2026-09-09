import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_pos/services/export_service.dart';

/// Tanpa terjemahan yang dimuat, `.tr()` memulangkan kuncinya sendiri. Itu
/// justru memudahkan tes ini: yang diperiksa adalah KEPUTUSAN mana yang diambil
/// (lupa logout / belum logout / tepat waktu), bukan kalimat yang tampil - dan
/// kalimatnya boleh diubah kapan saja tanpa membuat tes ini merah.
const kForgotLogout = 'export_att_forgot_logout';
const kStillOpen = 'export_att_still_open';
const kOnTime = 'export_att_ontime';
const kLate = 'export_att_late_minutes';
const kExcused = 'export_att_excused';
const kNoShift = 'export_att_no_shift';

Map<String, dynamic> employeeReport(List<Map<String, dynamic>> shifts,
    {String name = 'Rani'}) {
  return {
    'employees': [
      {'name': name, 'recent_shifts': shifts},
    ],
  };
}

Map<String, dynamic> shift({
  required String start,
  String? end,
  String status = 'closed',
  bool isLate = false,
  bool isExcused = false,
  int lateMinutes = 0,
  String? excuseReason,
  String shiftName = 'Shift Pagi',
}) {
  return {
    'start_time': start,
    'end_time': end,
    'status': status,
    'is_late': isLate,
    'is_excused': isExcused,
    'late_minutes': lateMinutes,
    'excuse_reason': excuseReason,
    'shift_name': shiftName,
  };
}

void main() {
  group('Absensi menandai shift yang tidak pernah ditutup', () {
    test('shift yang ditutup paksa server ditandai lupa logout', () {
      final rows = ExportService.attendanceDetailRows(employeeReport([
        shift(
          start: '2026-09-01T08:00:00+07:00',
          end: '2026-09-01T20:00:00+07:00',
          status: 'auto_closed',
        ),
      ]));

      expect(rows, hasLength(1));
      expect(rows.single.last, kForgotLogout);
    });

    test('shift yang masih terbuka ditandai belum logout, tanpa jam keluar', () {
      final rows = ExportService.attendanceDetailRows(employeeReport([
        shift(start: '2026-09-01T08:00:00+07:00', status: 'active'),
      ]));

      expect(rows.single.last, kStillOpen);
      // Jam keluar harus kosong. Shift aktif tidak punya `end_time`, dan
      // memakai jam "sekarang" sebagai penggantinya akan terbaca di laporan
      // seolah karyawan itu sudah logout - persis kesalahan yang ingin
      // ditangkap kolom ini.
      expect(rows.single[3], '-');
    });

    test('shift normal tidak diberi keterangan apa pun', () {
      final rows = ExportService.attendanceDetailRows(employeeReport([
        shift(
          start: '2026-09-01T08:00:00+07:00',
          end: '2026-09-01T16:00:00+07:00',
        ),
      ]));

      expect(rows.single.last, '-');
    });

    test('karyawan tanpa shift tetap muncul satu baris', () {
      // Karyawan yang tidak pernah masuk adalah informasi absensi juga.
      // Menghilangkannya dari laporan membuat ketidakhadiran tidak terlihat.
      final rows = ExportService.attendanceDetailRows(employeeReport([]));

      expect(rows, hasLength(1));
      expect(rows.single.last, kNoShift);
    });
  });

  group('Kolom ketepatan waktu', () {
    test('telat tanpa izin memuat jumlah menitnya', () {
      final rows = ExportService.attendanceDetailRows(employeeReport([
        shift(
          start: '2026-09-01T08:25:00+07:00',
          end: '2026-09-01T16:00:00+07:00',
          isLate: true,
          lateMinutes: 25,
        ),
      ]));

      expect(rows.single[6], kLate);
    });

    test('telat yang sudah diizinkan tidak dihitung sebagai pelanggaran', () {
      final rows = ExportService.attendanceDetailRows(employeeReport([
        shift(
          start: '2026-09-01T08:25:00+07:00',
          end: '2026-09-01T16:00:00+07:00',
          isExcused: true,
          lateMinutes: 25,
          excuseReason: 'Ban bocor',
        ),
      ]));

      expect(rows.single[6], kExcused);
      // Alasan izinnya ikut terbawa supaya owner tidak perlu membuka layar lain
      // untuk tahu kenapa keterlambatannya dimaafkan.
      expect(rows.single.last, contains('Ban bocor'));
    });

    test('masuk tepat waktu ditandai tepat waktu', () {
      final rows = ExportService.attendanceDetailRows(employeeReport([
        shift(
          start: '2026-09-01T08:00:00+07:00',
          end: '2026-09-01T16:00:00+07:00',
        ),
      ]));

      expect(rows.single[6], kOnTime);
    });
  });

  group('Profit harian', () {
    test('satu baris per hari, lengkap dengan HPP dan laba bersihnya', () {
      final rows = ExportService.profitRows({
        'start_date': '2026-09-01',
        'end_date': '2026-09-02',
        'chart_data': [
          {
            'label': '01 Sep',
            'sales': 500000,
            'cogs': 200000,
            'gross_profit': 300000,
            'expense': 50000,
            'profit': 250000,
            'orders': 12,
          },
          {
            'label': '02 Sep',
            'sales': 0,
            'cogs': 0,
            'gross_profit': 0,
            'expense': 0,
            'profit': 0,
            'orders': 0,
          },
        ],
      });

      expect(rows, hasLength(2));
      expect(rows.first.first, '01 Sep');
      expect(rows.first.last, '12');
      // Hari tanpa penjualan tetap ditulis. Melewatinya membuat pembaca laporan
      // mengira hari itu tidak ada dalam rentang, bukan bahwa tokonya sepi.
      expect(rows.last.last, '0');
    });

    test('laporan tanpa chart_data menghasilkan bagian kosong, bukan galat', () {
      expect(ExportService.profitRows(const {}), isEmpty);
    });
  });
}
