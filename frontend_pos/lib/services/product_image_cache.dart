import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/product_model.dart';

/// Menyimpan foto produk sebagai file di perangkat supaya POS tetap
/// menampilkan gambar saat offline.
///
/// Sebelumnya foto dirender lewat `Image.network`, yang hanya punya cache
/// memori: begitu aplikasi ditutup, foto hilang dan kasir cuma melihat ikon
/// kategori. Tabel `local_products` memang sudah menyimpan `image_url`, tapi
/// itu cuma alamatnya, bukan filenya.
class ProductImageCache {
  ProductImageCache._();

  static final ProductImageCache instance = ProductImageCache._();

  static const String _folderName = 'product_images';
  static const int _maxParallelDownloads = 3;
  static const Duration _downloadTimeout = Duration(seconds: 20);

  Directory? _dir;

  /// Nama file yang sudah ada di disk. Disimpan di memori supaya pencarian
  /// saat build widget bisa sinkron (build tidak boleh menunggu Future).
  final Set<String> _files = <String>{};

  final Set<String> _inFlight = <String>{};

  bool _warmedUp = false;
  bool get isWarmedUp => _warmedUp;

  /// Nama file deterministik dari URL memakai FNV-1a 32-bit.
  ///
  /// Deterministik berarti tidak perlu tabel indeks: URL yang sama selalu
  /// memetakan ke file yang sama, dan foto yang diganti menghasilkan URL baru
  /// sehingga otomatis jadi file baru. Dipakai 32-bit (bukan 64) supaya
  /// perhitungannya aman di semua platform termasuk web.
  String _fileNameFor(String url) {
    int hash = 0x811c9dc5;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return 'p_${hash.toRadixString(16)}${_extensionFor(url)}';
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
      debugPrint('ProductImageCache: gagal menyiapkan folder: $e');
    }
    return _dir;
  }

  /// Membaca daftar file yang sudah tersimpan ke memori. Dipanggil sekali saat
  /// aplikasi start supaya [localPathFor] bisa menjawab tanpa await.
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
      _warmedUp = true;
      debugPrint('ProductImageCache: ${_files.length} foto produk siap offline.');
    } catch (e) {
      debugPrint('ProductImageCache: gagal membaca folder: $e');
    }
  }

  /// Path file lokal untuk [url], atau null kalau belum terunduh.
  /// Sengaja sinkron supaya bisa dipakai langsung di dalam build widget.
  String? localPathFor(String? url) {
    if (url == null || url.isEmpty) return null;
    final dir = _dir;
    if (dir == null) return null;
    final name = _fileNameFor(url);
    return _files.contains(name) ? '${dir.path}/$name' : null;
  }

  /// Mengunduh satu foto kalau belum ada. Mengembalikan path lokalnya.
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

    // Cegah dua widget mengunduh URL yang sama bersamaan.
    if (!_inFlight.add(url)) return null;
    try {
      final response = await http.get(Uri.parse(url)).timeout(_downloadTimeout);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes, flush: true);
        _files.add(name);
        return file.path;
      }
      debugPrint('ProductImageCache: unduh gagal (${response.statusCode}) $url');
    } catch (e) {
      debugPrint('ProductImageCache: unduh gagal $url -> $e');
    } finally {
      _inFlight.remove(url);
    }
    return null;
  }

  /// Menyelaraskan cache dengan daftar produk terbaru: unduh yang belum ada,
  /// lalu hapus file milik produk/foto yang sudah tidak dipakai.
  ///
  /// Dipanggil tanpa await dari [SyncService.pullProducts] supaya membuka POS
  /// tidak perlu menunggu semua foto selesai diunduh.
  Future<void> syncProducts(List<ProductModel> products) async {
    final dir = await _ensureDir();
    if (dir == null) return;

    final wanted = <String>{};
    final urls = <String>[];
    for (final product in products) {
      final url = product.imageUrl;
      if (url == null || url.isEmpty) continue;
      wanted.add(_fileNameFor(url));
      if (!_files.contains(_fileNameFor(url))) urls.add(url);
    }

    // Dibatasi beberapa unduhan sekaligus supaya tidak membanjiri koneksi
    // kasir yang sedang dipakai untuk transaksi.
    for (var i = 0; i < urls.length; i += _maxParallelDownloads) {
      final chunk = urls.skip(i).take(_maxParallelDownloads);
      await Future.wait(chunk.map(download));
    }

    await _prune(wanted);
  }

  Future<void> _prune(Set<String> wanted) async {
    final dir = _dir;
    if (dir == null) return;
    try {
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (wanted.contains(name)) continue;
        await entity.delete();
        _files.remove(name);
      }
    } catch (e) {
      debugPrint('ProductImageCache: gagal membersihkan file lama: $e');
    }
  }

  /// Menghapus seluruh foto tersimpan (dipakai saat logout/ganti perusahaan).
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
      debugPrint('ProductImageCache: gagal menghapus cache: $e');
    }
  }
}
