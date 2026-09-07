import 'dart:io';

import 'package:flutter/material.dart';

import '../services/qris_image_cache.dart';

/// Menampilkan QRIS toko dari file lokal kalau sudah tersimpan, sehingga kode
/// tetap bisa dipindai pelanggan saat POS sedang offline.
///
/// Urutan sumbernya: file lokal -> jaringan (sambil diunduh untuk pemakaian
/// berikutnya) -> [fallback].
class QrisImage extends StatefulWidget {
  const QrisImage({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.fit = BoxFit.contain,
  });

  final String? imageUrl;
  final Widget fallback;
  final BoxFit fit;

  @override
  State<QrisImage> createState() => _QrisImageState();
}

class _QrisImageState extends State<QrisImage> {
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant QrisImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _localPath = null;
      _resolve();
    }
  }

  void _resolve() {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) return;

    final cached = QrisImageCache.instance.localPathFor(url);
    if (cached != null) {
      _localPath = cached;
      return;
    }

    QrisImageCache.instance.download(url).then((path) {
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
