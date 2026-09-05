import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Membuat berkas laporan keuangan dalam format CSV (terbuka di Excel) dan PDF.
///
/// Sengaja dibuat di sisi aplikasi, bukan di server. Alasannya bukan kemudahan:
/// backend berjalan di shared hosting dengan kuota CPU terbatas, dan membangun
/// PDF di sana akan menahan salah satu dari 60 PHP worker selama beberapa detik
/// per permintaan. Di perangkat, biayanya nol bagi server.
///
/// Seluruh angka diambil apa adanya dari respons /api/reports/financial supaya
/// isi berkas tidak pernah berbeda dari yang tampil di layar.
class ExportService {
  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String _money(dynamic v) => _rupiah.format(_num(v));

  static double _num(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  static String _stamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

  /// Baris ringkasan yang dipakai bersama oleh CSV maupun PDF, supaya keduanya
  /// tidak pernah menyimpang isinya.
  static List<List<String>> _summaryRows(Map<String, dynamic> r) => [
        ['Total Penjualan', _money(r['total_sales'])],
        ['Harga Pokok Penjualan (HPP)', _money(r['total_cogs'])],
        ['Laba Kotor', _money(r['gross_profit'])],
        ['Margin Kotor', '${_num(r['gross_margin_percent']).toStringAsFixed(1)}%'],
        ['Total Pengeluaran', _money(r['total_expenses'])],
        ['Laba Bersih', _money(r['net_profit'])],
        ['Margin Bersih', '${_num(r['net_margin_percent']).toStringAsFixed(1)}%'],
        ['Jumlah Transaksi', '${r['total_orders'] ?? 0}'],
        ['Rata-rata per Transaksi', _money(r['avg_order_value'])],
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
  static Future<void> financialReportToCsv(
    Map<String, dynamic> report, {
    String storeName = 'Zenvi',
  }) async {
    final rows = <List<String>>[
      ['Laporan Keuangan', storeName],
      ['Periode', _periodLabel(report)],
      ['Dibuat', DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now())],
      [],
      ['RINGKASAN', ''],
      ..._summaryRows(report),
    ];

    final topProducts = report['top_products'] as List<dynamic>? ?? [];
    if (topProducts.isNotEmpty) {
      rows.addAll([
        [],
        ['PRODUK TERLARIS', '', ''],
        ['Produk', 'Jumlah Terjual', 'Omzet'],
        ...topProducts.map((p) => [
              p['name']?.toString() ?? '-',
              '${p['qty'] ?? p['total_qty'] ?? 0}',
              _money(p['revenue'] ?? p['total'] ?? 0),
            ]),
      ]);
    }

    final payments = report['payment_methods'] as List<dynamic>? ?? [];
    if (payments.isNotEmpty) {
      rows.addAll([
        [],
        ['METODE PEMBAYARAN', '', ''],
        ['Metode', 'Jumlah Transaksi', 'Nilai'],
        ...payments.map((p) => [
              p['label']?.toString() ?? p['method']?.toString() ?? '-',
              '${p['count'] ?? 0}',
              _money(p['total'] ?? p['amount'] ?? 0),
            ]),
      ]);
    }

    final expenses = report['expense_breakdown'] as List<dynamic>? ?? [];
    if (expenses.isNotEmpty) {
      rows.addAll([
        [],
        ['RINCIAN PENGELUARAN', '', ''],
        ['Jenis', 'Jumlah', 'Nilai'],
        ...expenses.map((e) => [
              e['label']?.toString() ?? '-',
              '${e['count'] ?? 0}',
              _money(e['amount'] ?? e['total'] ?? 0),
            ]),
      ]);
    }

    final buffer = StringBuffer('sep=;\n');
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsv).join(';'));
    }

    // ﻿ = BOM UTF-8, penanda agar Excel membaca berkas sebagai UTF-8.
    final file = await _write('laporan_keuangan_${_stamp()}.csv',
        '﻿${buffer.toString()}');
    await _share(file, 'Laporan Keuangan $storeName');
  }

  static String _escapeCsv(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ---------------------------------------------------------------- PDF ----

  static Future<void> financialReportToPdf(
    Map<String, dynamic> report, {
    String storeName = 'Zenvi',
  }) async {
    final doc = pw.Document();
    final teal = PdfColor.fromInt(0xFF0D7C83);

    pw.Widget sectionTable(String title, List<String> headers, List<List<String>> data) {
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
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F1F1)),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
            },
          ),
        ],
      );
    }

    final topProducts = report['top_products'] as List<dynamic>? ?? [];
    final payments = report['payment_methods'] as List<dynamic>? ?? [];
    final expenses = report['expense_breakdown'] as List<dynamic>? ?? [];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
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
                  pw.Text('Laporan Keuangan',
                      style: pw.TextStyle(fontSize: 12, color: teal)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Periode', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text(_periodLabel(report), style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Dibuat ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: teal, thickness: 1.5),
          sectionTable('RINGKASAN', ['Keterangan', 'Nilai'], _summaryRows(report)),
          if (topProducts.isNotEmpty)
            sectionTable(
              'PRODUK TERLARIS',
              ['Produk', 'Terjual', 'Omzet'],
              topProducts
                  .map((p) => [
                        p['name']?.toString() ?? '-',
                        '${p['qty'] ?? p['total_qty'] ?? 0}',
                        _money(p['revenue'] ?? p['total'] ?? 0),
                      ])
                  .toList(),
            ),
          if (payments.isNotEmpty)
            sectionTable(
              'METODE PEMBAYARAN',
              ['Metode', 'Transaksi', 'Nilai'],
              payments
                  .map((p) => [
                        p['label']?.toString() ?? p['method']?.toString() ?? '-',
                        '${p['count'] ?? 0}',
                        _money(p['total'] ?? p['amount'] ?? 0),
                      ])
                  .toList(),
            ),
          if (expenses.isNotEmpty)
            sectionTable(
              'RINCIAN PENGELUARAN',
              ['Jenis', 'Jumlah', 'Nilai'],
              expenses
                  .map((e) => [
                        e['label']?.toString() ?? '-',
                        '${e['count'] ?? 0}',
                        _money(e['amount'] ?? e['total'] ?? 0),
                      ])
                  .toList(),
            ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/laporan_keuangan_${_stamp()}.pdf');
    await file.writeAsBytes(await doc.save());
    await _share(file, 'Laporan Keuangan $storeName');
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
