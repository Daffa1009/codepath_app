import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

/// Data model untuk setiap tab di liquid navigation bar.
class LiquidNavItem {
  final IconData icon;
  final String label;
  const LiquidNavItem({required this.icon, required this.label});
}

/// Bottom navigation bar dengan efek "liquid/cair":
/// - Cekungan bezier smooth di posisi tab aktif
/// - Icon aktif naik ke atas dalam lingkaran putih
/// - Icon tidak aktif tetap di dalam navbar, warna redup
/// - Animasi perpindahan cekungan smooth (300ms easeInOut)
class LiquidNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidNavItem> items;

  const LiquidNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<LiquidNavBar> createState() => _LiquidNavBarState();
}

class _LiquidNavBarState extends State<LiquidNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  /// Posisi cekungan animasi (0.0 - 1.0), interpolasi dari tab lama → baru.
  late double _activePosition;

  @override
  void initState() {
    super.initState();
    _activePosition = _indexToPosition(widget.currentIndex);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _animation.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(LiquidNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animateTo(widget.currentIndex);
    }
  }

  /// Konversi index tab → posisi normalisasi (0.0 - 1.0).
  /// Menggunakan tengah setiap slot: (index + 0.5) / count,
  /// agar cekungan segaris dengan icon yang menggunakan Expanded.
  double _indexToPosition(int index) {
    final count = widget.items.length;
    if (count == 0) return 0;
    return (index + 0.5) / count;
  }

  /// Animasikan cekungan dari posisi sekarang ke posisi tab baru.
  void _animateTo(int newIndex) {
    final startPos = _activePosition;
    final endPos = _indexToPosition(newIndex);

    _controller.reset();
    _animation = Tween<double>(begin: startPos, end: endPos).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _animation.addListener(() {
      _activePosition = _animation.value;
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    HapticFeedback.lightImpact();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    // Padding bawah untuk safe area (notch HP)
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double horizontalPadding = 16.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Background navbar dengan cekungan (CustomPaint) ──
        CustomPaint(
          painter: _LiquidNavPainter(
            activePosition: _activePosition,
            color: AppColors.primaryTeal,
            horizontalPadding: horizontalPadding,
          ),
          child: SizedBox(
            height: 70 + bottomPadding,
            width: double.infinity,
          ),
        ),

        // ── Row icon-icon navbar ──
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: SizedBox(
              height: 70,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: List.generate(widget.items.length, (index) {
                    final item = widget.items[index];
                    final isActive = index == widget.currentIndex;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabTapped(index),
                        behavior: HitTestBehavior.translucent,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          transform: Matrix4.translationValues(
                            0,
                            isActive ? -28 : 0,
                            0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Lingkaran putih untuk icon aktif
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                width: isActive ? 52 : 0,
                                height: isActive ? 52 : 0,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primaryTeal.withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                child: isActive
                                    ? Icon(
                                        item.icon,
                                        color: AppColors.primaryTeal,
                                        size: 24,
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              // Icon kecil untuk tab tidak aktif
                              if (!isActive) ...[
                                Icon(
                                  item.icon,
                                  color: Colors.white60,
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.label,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],

                              // Label tab aktif (di bawah lingkaran)
                              if (isActive)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter yang menggambar bentuk navbar dengan cekungan bezier smooth
/// di posisi tab aktif. Cekungan berbentuk kurva sinusoidal/bezier.
class _LiquidNavPainter extends CustomPainter {
  final double activePosition; // 0.0 - 1.0
  final Color color;
  final double horizontalPadding;

  _LiquidNavPainter({
    required this.activePosition,
    required this.color,
    this.horizontalPadding = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = _buildPath(size);
    canvas.drawPath(path, paint);
  }

  /// Membangun path navbar dengan cekungan bezier smooth.
  ///
  /// Struktur path:
  /// 1. Mulai dari kiri atas (dengan rounded corner)
  /// 2. Garis lurus sampai mendekati cekungan
  /// 3. Kurva bezier turun (cekungan) di posisi tab aktif
  /// 4. Kurva bezier naik lagi
  /// 5. Garis lurus ke kanan (dengan rounded corner)
  /// 6. Tutup path ke bawah
  Path _buildPath(Size size) {
    final path = Path();

    const double topRadius = 16.0;
    const double notchRadius = 34.0;
    const double smoothSpan = 18.0;
    const double depth = 30.0;

    final double contentWidth = size.width - (horizontalPadding * 2);
    final double cx = horizontalPadding + (contentWidth * activePosition);

    final double p1 = (cx - notchRadius - smoothSpan).clamp(0.0, size.width);
    final double p2 = (cx + notchRadius + smoothSpan).clamp(0.0, size.width);

    // ── 1. Titik awal sisi kiri ──
    if (p1 > topRadius) {
      path.moveTo(0, topRadius);
      path.quadraticBezierTo(0, 0, topRadius, 0);
      path.lineTo(p1, 0);
    } else {
      path.moveTo(0, 0);
      if (p1 > 0) {
        path.lineTo(p1, 0);
      }
    }

    // ── 2. Cekungan liquid bezier smooth ──
    // Turun dari (p1, 0) menuju (cx, depth)
    path.cubicTo(
      cx - notchRadius,
      0,
      cx - (notchRadius * 0.55),
      depth,
      cx,
      depth,
    );

    // Naik dari (cx, depth) menuju (p2, 0)
    path.cubicTo(
      cx + (notchRadius * 0.55),
      depth,
      cx + notchRadius,
      0,
      p2,
      0,
    );

    // ── 3. Sisi kanan ──
    if (p2 < size.width - topRadius) {
      path.lineTo(size.width - topRadius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, topRadius);
    } else {
      path.lineTo(size.width, 0);
    }

    // ── 4. Tutup path di bagian bawah ──
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(_LiquidNavPainter oldDelegate) {
    return oldDelegate.activePosition != activePosition ||
        oldDelegate.color != color ||
        oldDelegate.horizontalPadding != horizontalPadding;
  }
}
