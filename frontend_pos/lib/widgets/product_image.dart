import 'dart:io';

import 'package:flutter/material.dart';

import '../services/product_image_cache.dart';

/// Menampilkan foto produk dari file lokal kalau sudah tersimpan, sehingga
/// gambar tetap muncul saat POS dipakai offline.
///
/// Urutan sumbernya: file lokal -> jaringan (sambil diunduh untuk pemakaian
/// berikutnya) -> [fallback].
class ProductImage extends StatefulWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final Widget fallback;
  final BoxFit fit;

  @override
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _localPath = null;
      _resolve();
    }
  }

  void _resolve() {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) return;

    // Pencarian sinkron dulu supaya gambar yang sudah tersimpan langsung
    // tampil di frame pertama, tanpa kedip.
    final cached = ProductImageCache.instance.localPathFor(url);
    if (cached != null) {
      _localPath = cached;
      return;
    }

    // Belum ada: unduh di latar belakang agar tersedia offline nanti.
    ProductImageCache.instance.download(url).then((path) {
      if (!mounted || path == null) return;
      setState(() => _localPath = path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) return widget.fallback;

    final path = _localPath;
    if (path != null) {
      return Image.file(
        File(path),
        fit: widget.fit,
        errorBuilder: (_, _, _) => Image.network(
          url,
          fit: widget.fit,
          errorBuilder: (_, _, _) => widget.fallback,
        ),
      );
    }

    return Image.network(
      url,
      fit: widget.fit,
      errorBuilder: (_, _, _) => widget.fallback,
    );
  }
}
