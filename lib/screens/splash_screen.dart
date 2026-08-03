import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main_nav_screen.dart';
import 'admin/admin_home_screen.dart';
import '../services/auth_result.dart';

/// Animated splash screen with 3-phase sequence animation (horizontal layout)
class SplashScreen extends StatefulWidget {
  final AuthResult? currentUser;

  const SplashScreen({super.key, this.currentUser});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controller 1: Logo scale + rotation
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotation;

  // Controller 2: Gold line grow (vertical)
  late final AnimationController _lineController;
  late final Animation<double> _lineHeight;

  // Controller 3: Text slide from left
  late final AnimationController _textController;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // Controller 1: Logo animation (0-600ms)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoRotation = Tween<double>(begin: -15 * math.pi / 180, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // Controller 2: Line grow vertical (starts at 300ms, duration 400ms)
    _lineController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _lineHeight = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.easeOutCubic),
    );

    // Controller 3: Text slide from left (starts at 500ms, duration 500ms)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Start sequence
    _runSequence();
  }

  Future<void> _runSequence() async {
    // Phase 1: Logo appears
    await _logoController.forward();

    // Phase 2: Line grows vertically
    await Future.delayed(const Duration(milliseconds: 100));
    await _lineController.forward();

    // Phase 3: Text slides in from left
    await Future.delayed(const Duration(milliseconds: 100));
    await _textController.forward();

    // Hold final state briefly
    await Future.delayed(const Duration(milliseconds: 300));

    // Navigate based on session
    if (!mounted) return;
    _navigateToHome();
  }

  void _navigateToHome() {
    Widget destination;
    final user = widget.currentUser;

    if (user == null) {
      destination = const LoginScreen();
    } else if (user.isAdmin) {
      destination = const AdminHomeScreen();
    } else {
      destination = MainNavScreen(user: user);
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _lineController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.white;
    const goldColor = Color(0xFFC9A227);
    const greenColor = Color(0xFF0D3B36);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _logoController,
            _lineController,
            _textController,
          ]),
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                // Phase 1: Logo with scale + rotation
                Transform.scale(
                  scale: _logoScale.value,
                  child: Transform.rotate(
                    angle: _logoRotation.value,
                    child: Image.asset(
                      'assets/logo_cp.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Phase 2: Gold vertical line
                AnimatedBuilder(
                  animation: _lineHeight,
                  builder: (context, child) {
                    return SizedBox(
                      width: 2,
                      height: 80 * _lineHeight.value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: goldColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 24),

                // Phase 3: Text "CodePath" with slide from left
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: const ClipRect(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Code',
                            style: TextStyle(
                              color: greenColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Path',
                            style: TextStyle(
                              color: goldColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
