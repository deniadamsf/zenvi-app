import 'package:flutter/material.dart';

enum ZenviLogoVariant {
  solid,     // Latar belakang kotak hijau, segitiga putih
  iconOnly,  // Tanpa latar belakang, segitiga hijau
}

/// Widget dasar untuk menggambar Logo Zenvi
class ZenviLogo extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final ZenviLogoVariant variant;

  const ZenviLogo({
    super.key,
    this.size = 100.0,
    this.primaryColor = const Color(0xFF0D7C83), // Zenvi Teal
    this.variant = ZenviLogoVariant.solid,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ZenviLogoPainter(
          primaryColor: primaryColor,
          variant: variant,
        ),
      ),
    );
  }
}

class _ZenviLogoPainter extends CustomPainter {
  final Color primaryColor;
  final ZenviLogoVariant variant;

  _ZenviLogoPainter({
    required this.primaryColor,
    required this.variant,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Gambar Background (Kotak Membulat) jika varian solid
    if (variant == ZenviLogoVariant.solid) {
      final bgPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;
      
      final radius = size.width * 0.2; // 20% border radius
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      );
      canvas.drawRRect(rrect, bgPaint);
    }

    // 2. Gambar Foreground (Segitiga Terpotong)
    final fgPaint = Paint()
      ..color = variant == ZenviLogoVariant.solid ? Colors.white : primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeJoin = StrokeJoin.miter;

    final path = Path();
    
    // Padding dari tepi
    final paddingX = size.width * 0.25;
    final paddingY = size.height * 0.25;

    // Titik sudut segitiga
    final topLeft = Offset(paddingX, paddingY);
    final topRight = Offset(size.width - paddingX, paddingY);
    final bottomCenter = Offset(size.width / 2, size.height - paddingY * 1.15);

    final topWidth = topRight.dx - topLeft.dx;
    
    // Celah (gap) pada garis atas
    final gapStart = topLeft.dx + topWidth * 0.22;
    final gapEnd = topLeft.dx + topWidth * 0.38;

    // Gambar dengan satu path utuh agar miter join rapi
    path.moveTo(gapStart, topLeft.dy);
    path.lineTo(topLeft.dx, topLeft.dy);
    path.lineTo(bottomCenter.dx, bottomCenter.dy);
    path.lineTo(topRight.dx, topRight.dy);
    path.lineTo(gapEnd, topRight.dy);

    canvas.drawPath(path, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ----------------------------------------------------
/// 1. Animasi Loading Logo Zenvi (Efek Pulse / Berdetak)
/// ----------------------------------------------------
class ZenviLoadingAnimation extends StatefulWidget {
  final double size;
  final ZenviLogoVariant variant;

  const ZenviLoadingAnimation({
    super.key, 
    this.size = 80.0,
    this.variant = ZenviLogoVariant.solid,
  });

  @override
  State<ZenviLoadingAnimation> createState() => _ZenviLoadingAnimationState();
}

class _ZenviLoadingAnimationState extends State<ZenviLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: ZenviLogo(size: widget.size, variant: widget.variant),
    );
  }
}

/// ----------------------------------------------------
/// 2. Ikon Notifikasi Logo Zenvi dengan Badge
/// ----------------------------------------------------
class ZenviNotificationIcon extends StatelessWidget {
  final int notificationCount;
  final double size;
  final VoidCallback? onTap;

  const ZenviNotificationIcon({
    super.key,
    this.notificationCount = 0,
    this.size = 32.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 8, // Ekstra space untuk badge
        height: size + 8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Logo Utama
            ZenviLogo(size: size, variant: ZenviLogoVariant.iconOnly),
            
            // Badge Notifikasi (hanya tampil jika > 0)
            if (notificationCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      notificationCount > 99 ? '99+' : '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1, // Agar teks benar-benar di tengah
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
