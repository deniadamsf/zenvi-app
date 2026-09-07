import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Menyimpan gambar QRIS toko sebagai file di perangkat.
///
/// Kasir harus bisa menunjukkan kode QR meskipun internet sedang mati - justru
/// di saat itulah pembayaran non-tunai paling sering dipakai sebagai jalan
/// keluar. `Image.network` hanya punya cache memori, jadi kodenya hilang setiap
/// kali aplikasi ditutup.
///
/// Hanya ada satu QRIS per toko, jadi file lama langsung dibuang setiap kali
/// alamat gambarnya berubah.
class QrisImageCache {
  QrisImageCache._();

  static final QrisImageCache instance = QrisImageCache._();

  static const String _folderName = 'qris_image';
  static const Duration _downloadTimeout = Duration(seconds: 20);

  Directory? _dir;
  final Set<String> _files = <String>{};
  final Set<String> _inFlight = <String>{};

  /// Nama file deterministik dari URL (FNV-1a 32-bit): URL yang sama selalu
  /// memetakan ke file yang sama, dan QRIS yang diganti menghasilkan URL baru
  /// sehingga otomatis jadi file baru.
  String _fileNameFor(String url) {
    int hash = 0x811c9dc5;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return 'q_${hash.toRadixString(16)}${_extensionFor(url)}';
  }

  String _extensionFor(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '.img';
    final ext = path.substring(dot).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(ext) ? ext : '.img';
  }

  Future<Directory?> _ensureDir() async {
    if (_dir != null) return _dir;
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/$_folderName');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _dir = dir;
    } catch (e) {
      debugPrint('QrisImageCache: gagal menyiapkan folder: $e');
    }
    return _dir;
  }

  /// Membaca file yang sudah tersimpan ke memori supaya [localPathFor] bisa
  /// menjawab tanpa await di dalam build widget.
  Future<void> warmUp() async {
    final dir = await _ensureDir();
    if (dir == null) return;
    try {
      _files.clear();
      await for (final entity in dir.list()) {
        if (entity is File) {
          _files.add(entity.uri.pathSegments.last);
        }
      }
    } catch (e) {
      debugPrint('QrisImageCache: gagal membaca folder: $e');
    }
  }

  String? localPathFor(String? url) {
    if (url == null || url.isEmpty) return null;
    final dir = _dir;
    if (dir == null) return null;
    final name = _fileNameFor(url);
    return _files.contains(name) ? '${dir.path}/$name' : null;
  }

  /// Mengunduh QRIS kalau belum tersimpan, lalu membuang versi lamanya.
  Future<String?> download(String? url) async {
    if (url == null || url.isEmpty) return null;

    final dir = await _ensureDir();
    if (dir == null) return null;

    final name = _fileNameFor(url);
    final file = File('${dir.path}/$name');

    if (await file.exists()) {
      _files.add(name);
      return file.path;
    }

    if (!_inFlight.add(url)) return null;
    try {
      final response = await http.get(Uri.parse(url)).timeout(_downloadTimeout);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes, flush: true);
        _files.add(name);
        await _prune(keep: name);
        return file.path;
      }
      debugPrint('QrisImageCache: unduh gagal (${response.statusCode}) $url');
    } catch (e) {
      debugPrint('QrisImageCache: unduh gagal $url -> $e');
    } finally {
      _inFlight.remove(url);
    }
    return null;
  }

  Future<void> _prune({required String keep}) async {
    final dir = _dir;
    if (dir == null) return;
    try {
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name == keep) continue;
        await entity.delete();
        _files.remove(name);
      }
    } catch (e) {
      debugPrint('QrisImageCache: gagal membersihkan file lama: $e');
    }
  }

  /// Dipakai saat logout/ganti perusahaan: QRIS toko lama tidak boleh terbawa.
  Future<void> clear() async {
    final dir = await _ensureDir();
    if (dir == null) return;
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _files.clear();
      _dir = null;
    } catch (e) {
      debugPrint('QrisImageCache: gagal menghapus cache: $e');
    }
  }
}
