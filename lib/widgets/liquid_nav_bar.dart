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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Background navbar dengan cekungan (CustomPaint) ──
        CustomPaint(
          painter: _LiquidNavPainter(
            activePosition: _activePosition,
            color: AppColors.primaryTeal,
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
      ],
    );
  }
}

/// CustomPainter yang menggambar bentuk navbar dengan cekungan bezier smooth
/// di posisi tab aktif. Cekungan berbentuk kurva sinusoidal/bezier.
class _LiquidNavPainter extends CustomPainter {
  final double activePosition; // 0.0 - 1.0
  final Color color;

  _LiquidNavPainter({
    required this.activePosition,
    required this.color,
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

    const double cornerRadius = 20;
    const double notchRadius = 36;
    final double notchCenter = size.width * activePosition;

    // Rounded corner kiri atas
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Garis ke awal cekungan
    path.lineTo(notchCenter - notchRadius - 20, 0);

    // Kurva masuk cekungan (bezier cubic)
    path.cubicTo(
      notchCenter - notchRadius, 0,
      notchCenter - notchRadius, notchRadius * 0.8,
      notchCenter, notchRadius * 0.85,
    );

    // Kurva keluar cekungan
    path.cubicTo(
      notchCenter + notchRadius, notchRadius * 0.8,
      notchCenter + notchRadius, 0,
      notchCenter + notchRadius + 20, 0,
    );

    // Garis ke kanan (sebelum rounded corner)
    path.lineTo(size.width - cornerRadius, 0);

    // Rounded corner kanan atas
    path.quadraticBezierTo(
      size.width, 0,
      size.width, cornerRadius,
    );

    // Tutup ke bawah
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(_LiquidNavPainter oldDelegate) {
    return oldDelegate.activePosition != activePosition ||
        oldDelegate.color != color;
  }
}
