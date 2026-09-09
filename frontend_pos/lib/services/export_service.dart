import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Membuat berkas laporan lengkap dalam format CSV (terbuka di Excel) dan PDF.
///
/// Sengaja dibuat di sisi aplikasi, bukan di server. Alasannya bukan kemudahan:
/// backend berjalan di shared hosting dengan kuota CPU terbatas, dan membangun
/// PDF di sana akan menahan salah satu dari 60 PHP worker selama beberapa detik
/// per permintaan. Di perangkat, biayanya nol bagi server.
///
/// Seluruh angka diambil apa adanya dari respons `/api/reports/financial` dan
/// `/api/reports/employee-performance` supaya isi berkas tidak pernah berbeda
/// dari yang tampil di layar. Tidak ada satu pun angka yang dihitung ulang di
/// sini - kalau berkas dan layar berbeda, itu bug di server, bukan di ekspor.
///
/// Kedua respons diambil untuk RENTANG TANGGAL YANG SAMA, yaitu rentang yang
/// sudah dipulangkan laporan keuangan (`start_date`/`end_date`). Rentang itu
/// sudah dipangkas server sesuai batas riwayat paket, jadi bagian karyawan tidak
/// bisa memuat tanggal yang bagian keuangannya sendiri tidak boleh menampilkan.
class ExportService {
  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String _money(dynamic v) => _rupiah.format(_num(v));

  static double _num(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  static int _int(dynamic v) =>
      v == null ? 0 : (int.tryParse(v.toString()) ?? _num(v).round());

  static String _percent(dynamic v) => '${_num(v).toStringAsFixed(1)}%';

  static String _text(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? '-' : s;
  }

  static String _stamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

  static List<Map<String, dynamic>> _rows(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Selisih dua waktu sebagai "3j 20m".
  ///
  /// Dihitung di sini, bukan memakai `duration_formatted` dari server: satuan
  /// jam/menit di sana tertulis dalam Bahasa Indonesia, dan berkas ekspor harus
  /// ikut bahasa yang sedang dipakai aplikasi.
  static String _duration(DateTime? start, DateTime? end) {
    if (start == null) return '-';
    final minutes = (end ?? DateTime.now()).difference(start).inMinutes;
    if (minutes < 0) return '-';
    return 'export_duration_hm'.tr(namedArgs: {
      'h': '${minutes ~/ 60}',
      'm': '${minutes % 60}',
    });
  }

  static DateTime? _parseTime(dynamic v) {
    final s = v?.toString();
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  static String _clock(DateTime? t) =>
      t == null ? '-' : DateFormat('HH:mm').format(t);

  static String _day(DateTime? t) =>
      t == null ? '-' : DateFormat('dd/MM/yyyy').format(t);

  // ------------------------------------------------------------ bagian ----
  //
  // Setiap bagian dibangun sekali di sini lalu dipakai CSV maupun PDF, supaya
  // keduanya tidak pernah menyimpang isinya. Bagian yang tidak punya data
  // mengembalikan daftar kosong dan dilewati di kedua format - lebih baik
  // hilang daripada muncul sebagai tabel berisi nol yang menyesatkan.

  static List<List<String>> _summaryRows(Map<String, dynamic> r) => [
        ['export_row_total_sales'.tr(), _money(r['total_sales'])],
        ['export_row_cogs'.tr(), _money(r['total_cogs'])],
        ['export_row_gross_profit'.tr(), _money(r['gross_profit'])],
        ['export_row_gross_margin'.tr(), _percent(r['gross_margin_percent'])],
        ['export_row_total_expenses'.tr(), _money(r['total_expenses'])],
        ['export_row_net_profit'.tr(), _money(r['net_profit'])],
        ['export_row_net_margin'.tr(), _percent(r['net_margin_percent'])],
        ['export_row_total_orders'.tr(), '${_int(r['total_orders'])}'],
        ['export_row_avg_order'.tr(), _money(r['avg_order_value'])],
      ];

  /// Profit per hari - atau per jam kalau rentang yang dipilih hanya satu hari,
  /// karena itulah bentuk `chart_data` yang dikirim server untuk rentang sehari.
  @visibleForTesting
  static List<List<String>> profitRows(Map<String, dynamic> r) =>
      _rows(r['chart_data'])
          .map((d) => [
                _text(d['label'] ?? d['date']),
                _money(d['sales']),
                _money(d['cogs']),
                _money(d['gross_profit']),
                _money(d['expense']),
                _money(d['profit'] ?? d['net_profit']),
                '${_int(d['orders'])}',
              ])
          .toList();

  static bool _isHourly(Map<String, dynamic> r) {
    final start = r['start_date']?.toString();
    final end = r['end_date']?.toString();
    return start != null && start == end;
  }

  static List<String> _profitHeaders(Map<String, dynamic> r) => [
        _isHourly(r) ? 'export_col_hour'.tr() : 'export_col_date'.tr(),
        'export_col_sales'.tr(),
        'export_col_cogs'.tr(),
        'export_col_gross_profit'.tr(),
        'export_col_expense'.tr(),
        'export_col_net_profit'.tr(),
        'export_col_orders'.tr(),
      ];

  static List<List<String>> _topProductRows(Map<String, dynamic> r) =>
      _rows(r['top_products'])
          .map((p) => [
                _text(p['name']),
                '${_int(p['qty'] ?? p['total_qty'])}',
                _money(p['revenue'] ?? p['total']),
              ])
          .toList();

  static List<List<String>> _paymentRows(Map<String, dynamic> r) =>
      _rows(r['payment_methods'])
          .map((p) => [
                _text(p['label'] ?? p['method']),
                '${_int(p['count'])}',
                _money(p['total'] ?? p['amount']),
              ])
          .toList();

  static List<List<String>> _expenseRows(Map<String, dynamic> r) =>
      _rows(r['expense_breakdown'])
          .map((e) => [
                _text(e['label']),
                '${_int(e['count'])}',
                _money(e['amount'] ?? e['total']),
              ])
          .toList();

  static List<Map<String, dynamic>> _employees(Map<String, dynamic>? emp) =>
      emp == null ? const [] : _rows(emp['employees']);

  /// Omzet per karyawan, sudah dipecah per metode bayar.
  ///
  /// `total_sales` di sini mencakup transaksi yang dia kasiri MAUPUN yang dia
  /// layani - itu ukuran keterlibatannya. Kontribusi persennya dihitung server
  /// terhadap omzet kasir saja supaya satu transaksi tidak terhitung dua kali
  /// saat seluruh karyawan dijumlahkan.
  static List<List<String>> _employeeSalesRows(Map<String, dynamic>? emp) =>
      _employees(emp)
          .map((e) => [
                _text(e['name']),
                _text(e['job_title'] ?? e['role']),
                _money(e['total_sales']),
                '${_int(e['total_orders'])}',
                _money(e['average_order_value']),
                _money(e['cash_sales']),
                _money(e['qris_sales']),
                _money(e['transfer_sales']),
                _percent(e['sales_contribution_percent']),
              ])
          .toList();

  static List<List<String>> _attendanceRecapRows(Map<String, dynamic>? emp) =>
      _employees(emp)
          .map((e) => [
                _text(e['name']),
                '${_int(e['total_shifts'])}',
                _num(e['total_work_hours']).toStringAsFixed(1),
                '${_int(e['on_time_shifts_count'])}',
                '${_int(e['late_shifts_count'])}',
                '${_int(e['total_late_minutes'])}',
                '${_int(e['excused_late_shifts_count'])}',
                '${_int(e['approved_leaves_count'])}',
                _percent(e['accuracy_percentage']),
                _money(e['total_cash_variance']),
              ])
          .toList();

  /// Satu baris per shift, inilah yang membuat "lupa logout" terbaca.
  ///
  /// Dua keadaan yang sama-sama berarti karyawan tidak menutup shiftnya:
  /// `auto_closed` (server sudah menutupnya paksa setelah 12 jam) dan `active`
  /// yang tanggal masuknya bukan hari ini. Keduanya diberi keterangan, karena
  /// tanpa itu jam kerjanya terbaca wajar padahal tidak pernah ada logout.
  @visibleForTesting
  static List<List<String>> attendanceDetailRows(Map<String, dynamic>? emp) {
    final rows = <List<String>>[];
    for (final e in _employees(emp)) {
      final shifts = _rows(e['recent_shifts']);
      final name = _text(e['name']);

      if (shifts.isEmpty) {
        rows.add([name, '-', '-', '-', '-', '-', '-', 'export_att_no_shift'.tr()]);
        continue;
      }

      for (final s in shifts) {
        final start = _parseTime(s['start_time']);
        final end = _parseTime(s['end_time']);
        final status = s['status']?.toString() ?? '';

        String punctuality;
        if (s['is_excused'] == true) {
          punctuality = 'export_att_excused'.tr();
        } else if (s['is_late'] == true) {
          punctuality = 'export_att_late_minutes'.tr(args: ['${_int(s['late_minutes'])}']);
        } else {
          punctuality = 'export_att_ontime'.tr();
        }

        String note = '';
        if (status == 'auto_closed') {
          note = 'export_att_forgot_logout'.tr();
        } else if (status == 'active') {
          note = 'export_att_still_open'.tr();
        }
        final excuse = s['excuse_reason']?.toString().trim() ?? '';
        if (excuse.isNotEmpty) {
          note = note.isEmpty ? excuse : '$note; $excuse';
        }

        rows.add([
          name,
          _day(start),
          _clock(start),
          // Shift yang belum ditutup tidak punya jam keluar. Menampilkan jam
          // "sekarang" di kolom ini akan terbaca seolah dia sudah logout.
          status == 'active' ? '-' : _clock(end),
          _duration(start, end),
          _text(s['shift_name']),
          punctuality,
          note.isEmpty ? '-' : note,
        ]);
      }
    }
    return rows;
  }

  static List<String> get _attendanceDetailHeaders => [
        'export_col_employee'.tr(),
        'export_col_date'.tr(),
        'export_col_check_in'.tr(),
        'export_col_check_out'.tr(),
        'export_col_duration'.tr(),
        'export_col_shift_name'.tr(),
        'export_col_punctuality'.tr(),
        'export_col_note'.tr(),
      ];

  static String _periodLabel(Map<String, dynamic> r) {
    final start = r['start_date']?.toString() ?? '-';
    final end = r['end_date']?.toString() ?? '-';
    return start == end ? start : '$start s/d $end';
  }

  // ---------------------------------------------------------------- CSV ----

  /// CSV, bukan .xlsx sungguhan.
  ///
  /// Excel, Google Sheets, dan LibreOffice semuanya membukanya langsung, tanpa
  /// menambah satu pun dependensi. Dua detail yang membuatnya benar-benar rapi
  /// di komputer Indonesia: baris `sep=;` di awal (Excel lokal ID memakai titik
  /// koma sebagai pemisah kolom, bukan koma) dan BOM UTF-8 supaya huruf beraksen
  /// tidak berantakan.
  static Future<void> fullReportToCsv(
    Map<String, dynamic> report, {
    Map<String, dynamic>? employeeReport,
    String storeName = 'Zenvi',
  }) async {
    final rows = <List<String>>[
      ['export_doc_title'.tr(), storeName],
      ['export_period'.tr(), _periodLabel(report)],
      [
        'export_generated'.tr(),
        DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now()),
      ],
    ];

    void section(String title, List<String> headers, List<List<String>> data) {
      if (data.isEmpty) return;
      rows
        ..add([])
        ..add([title])
        ..add(headers)
        ..addAll(data);
    }

    section('export_sec_pnl'.tr(),
        ['export_col_description'.tr(), 'export_col_value'.tr()], _summaryRows(report));
    section(
      _isHourly(report) ? 'export_sec_hourly_profit'.tr() : 'export_sec_daily_profit'.tr(),
      _profitHeaders(report),
      profitRows(report),
    );
    section(
      'export_sec_employee_sales'.tr(),
      [
        'export_col_employee'.tr(),
        'export_col_role'.tr(),
        'export_col_sales'.tr(),
        'export_col_orders'.tr(),
        'export_col_avg_per_order'.tr(),
        'export_col_cash'.tr(),
        'export_col_qris'.tr(),
        'export_col_transfer'.tr(),
        'export_col_contribution'.tr(),
      ],
      _employeeSalesRows(employeeReport),
    );
    section(
      'export_sec_attendance_recap'.tr(),
      [
        'export_col_employee'.tr(),
        'export_col_shift_count'.tr(),
        'export_col_work_hours'.tr(),
        'export_col_ontime'.tr(),
        'export_col_late'.tr(),
        'export_col_late_minutes'.tr(),
        'export_col_excused'.tr(),
        'export_col_leave'.tr(),
        'export_col_cash_accuracy'.tr(),
        'export_col_cash_variance'.tr(),
      ],
      _attendanceRecapRows(employeeReport),
    );
    section('export_sec_attendance_detail'.tr(), _attendanceDetailHeaders,
        attendanceDetailRows(employeeReport));
    section(
      'export_sec_top_products'.tr(),
      ['export_col_product'.tr(), 'export_col_sold'.tr(), 'export_col_sales'.tr()],
      _topProductRows(report),
    );
    section(
      'export_sec_payment_methods'.tr(),
      ['export_col_method'.tr(), 'export_col_orders'.tr(), 'export_col_amount'.tr()],
      _paymentRows(report),
    );
    section(
      'export_sec_expenses'.tr(),
      ['export_col_type'.tr(), 'export_col_count'.tr(), 'export_col_amount'.tr()],
      _expenseRows(report),
    );

    final buffer = StringBuffer('sep=;\n');
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsv).join(';'));
    }

    // ﻿ = BOM UTF-8, penanda agar Excel membaca berkas sebagai UTF-8.
    final file = await _write('laporan_lengkap_${_stamp()}.csv', '﻿${buffer.toString()}');
    await _share(file, 'export_share_subject'.tr(args: [storeName]));
  }

  static String _escapeCsv(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ---------------------------------------------------------------- PDF ----

  static Future<void> fullReportToPdf(
    Map<String, dynamic> report, {
    Map<String, dynamic>? employeeReport,
    String storeName = 'Zenvi',
  }) async {
    final doc = pw.Document();
    final teal = PdfColor.fromInt(0xFF0D7C83);

    /// Kolom pertama selalu rata kiri (nama/tanggal), sisanya rata kanan karena
    /// isinya angka. [textColumns] menandai tabel yang isinya kalimat, bukan
    /// angka - rincian absensi - supaya keterangannya tidak menempel ke tepi
    /// kanan dan sulit dibaca berurutan ke bawah.
    pw.Widget sectionTable(
      String title,
      List<String> headers,
      List<List<String>> data, {
      bool textColumns = false,
    }) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 18),
          pw.Text(title,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: teal)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F1F1)),
            cellAlignments: {
              for (var i = 0; i < headers.length; i++)
                i: (textColumns || i == 0)
                    ? pw.Alignment.centerLeft
                    : pw.Alignment.centerRight,
            },
          ),
        ],
      );
    }

    final profitTable = profitRows(report);
    final employeeSales = _employeeSalesRows(employeeReport);
    final attendanceRecap = _attendanceRecapRows(employeeReport);
    final attendanceDetail = attendanceDetailRows(employeeReport);
    final topProducts = _topProductRows(report);
    final payments = _paymentRows(report);
    final expenses = _expenseRows(report);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'export_page_of'.tr(namedArgs: {
              'current': '${ctx.pageNumber}',
              'total': '${ctx.pagesCount}',
            }),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(storeName,
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('export_doc_title'.tr(),
                      style: pw.TextStyle(fontSize: 12, color: teal)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('export_period'.tr(),
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text(_periodLabel(report), style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${'export_generated'.tr()} '
                    '${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: teal, thickness: 1.5),
          sectionTable('export_sec_pnl'.tr(),
              ['export_col_description'.tr(), 'export_col_value'.tr()], _summaryRows(report)),
          if (profitTable.isNotEmpty)
            sectionTable(
              _isHourly(report)
                  ? 'export_sec_hourly_profit'.tr()
                  : 'export_sec_daily_profit'.tr(),
              _profitHeaders(report),
              profitTable,
            ),
          if (employeeSales.isNotEmpty)
            sectionTable(
              'export_sec_employee_sales'.tr(),
              [
                'export_col_employee'.tr(),
                'export_col_role'.tr(),
                'export_col_sales'.tr(),
                'export_col_orders'.tr(),
                'export_col_avg_per_order'.tr(),
                'export_col_cash'.tr(),
                'export_col_qris'.tr(),
                'export_col_transfer'.tr(),
                'export_col_contribution'.tr(),
              ],
              employeeSales,
            ),
          if (attendanceRecap.isNotEmpty)
            sectionTable(
              'export_sec_attendance_recap'.tr(),
              [
                'export_col_employee'.tr(),
                'export_col_shift_count'.tr(),
                'export_col_work_hours'.tr(),
                'export_col_ontime'.tr(),
                'export_col_late'.tr(),
                'export_col_late_minutes'.tr(),
                'export_col_excused'.tr(),
                'export_col_leave'.tr(),
                'export_col_cash_accuracy'.tr(),
                'export_col_cash_variance'.tr(),
              ],
              attendanceRecap,
            ),
          if (attendanceDetail.isNotEmpty)
            sectionTable('export_sec_attendance_detail'.tr(), _attendanceDetailHeaders,
                attendanceDetail,
                textColumns: true),
          if (topProducts.isNotEmpty)
            sectionTable(
              'export_sec_top_products'.tr(),
              ['export_col_product'.tr(), 'export_col_sold'.tr(), 'export_col_sales'.tr()],
              topProducts,
            ),
          if (payments.isNotEmpty)
            sectionTable(
              'export_sec_payment_methods'.tr(),
              ['export_col_method'.tr(), 'export_col_orders'.tr(), 'export_col_amount'.tr()],
              payments,
            ),
          if (expenses.isNotEmpty)
            sectionTable(
              'export_sec_expenses'.tr(),
              ['export_col_type'.tr(), 'export_col_count'.tr(), 'export_col_amount'.tr()],
              expenses,
            ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/laporan_lengkap_${_stamp()}.pdf');
    await file.writeAsBytes(await doc.save());
    await _share(file, 'export_share_subject'.tr(args: [storeName]));
  }

  // ------------------------------------------------------------- helper ----

  static Future<File> _write(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  static Future<void> _share(File file, String subject) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: subject),
    );
  }
}
