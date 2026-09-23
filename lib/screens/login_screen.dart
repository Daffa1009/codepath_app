import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/auth_result.dart';
import 'main_nav_screen.dart';
import 'admin/admin_home_screen.dart';

enum _AuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _AuthMode _mode = _AuthMode.signIn;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _namaLengkapController = TextEditingController();
  final _konfirmasiPasswordController = TextEditingController();

  // Error state
  String? _errorMessage;
  bool _shake = false;
  bool _usernameError = false;
  bool _passwordError = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _namaLengkapController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  /// Validasi form sebelum submit.
  String? _validate() {
    final username = _usernameController.text;

    if (username.contains(' ') || username.length < 3) {
      return 'Username minimal 3 karakter dan tidak boleh mengandung spasi.';
    }
    if (_passwordController.text.length < 6) {
      return 'Password minimal 6 karakter.';
    }
    if (_mode == _AuthMode.signUp) {
      if (_namaLengkapController.text.trim().isEmpty) {
        return 'Nama Lengkap tidak boleh kosong.';
      }
      if (_passwordController.text != _konfirmasiPasswordController.text) {
        return 'Konfirmasi password tidak cocok.';
      }
    }
    return null;
  }

  /// Memicu shake animation dan tampilkan pesan error di UI
  /// (bukan SnackBar — sekarang inline di atas tombol).
  void _showInlineError(String message) {
    setState(() {
      _errorMessage = message;
      _shake = true;

      // Deteksi field mana yang salah
      final lower = message.toLowerCase();
      if (lower.contains('password') && lower.contains('salah')) {
        // Username atau password salah → keduanya merah
        _usernameError = true;
        _passwordError = true;
      } else if (lower.contains('tidak terdaftar') ||
          lower.contains('tidak ditemukan')) {
        // Akun tidak ada → username saja
        _usernameError = true;
        _passwordError = false;
      } else if (lower.contains('password minimal')) {
        _passwordError = true;
      } else {
        _usernameError = false;
        _passwordError = false;
      }
    });

    // Hentikan shake setelah animasi selesai
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _shake = false);
      }
    });
  }

  void _clearError() {
    if (_errorMessage != null || _usernameError || _passwordError) {
      setState(() {
        _errorMessage = null;
        _usernameError = false;
        _passwordError = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final error = _validate();
    if (error != null) {
      _showInlineError(error);
      return;
    }

    setState(() {
      _loading = true;
      _clearError();
    });

    try {
      AuthResult result;

      if (_mode == _AuthMode.signUp) {
        result = await AuthService.register(
          username: _usernameController.text,
          password: _passwordController.text,
          namaLengkap: _namaLengkapController.text,
        );
      } else {
        result = await AuthService.login(
          username: _usernameController.text,
          password: _passwordController.text,
        );
      }

      if (!mounted) return;

      // Simpan user info ke UserProvider
      context.read<UserProvider>().setUser(result);

      // Navigasi berdasarkan role
      final destination = result.isAdmin
          ? const AdminHomeScreen()
          : MainNavScreen(user: result);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    } on AuthException catch (e) {
      setState(() => _loading = false);
      _showInlineError(e.message);
    } catch (e) {
      setState(() => _loading = false);
      _showInlineError('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await AuthService.signInWithGoogle();
      // Web: redirect otomatis oleh Supabase — halaman berpindah, tidak perlu
      // navigasi manual. Mobile: deep link akan ditangani oleh onAuthStateChange.
      // Jika tidak redirect (error silent), pastikan loading state direset.
      if (mounted && !kIsWeb) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal login dengan Google: ${e.toString()}'),
            backgroundColor: AppColors.maroon,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final headerHeight = screenSize.height * 0.38;

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F2F1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Layer 1: Header melengkung
              ClipPath(
                clipper: _HeaderClipper(),
                child: Container(
                  height: headerHeight,
                  width: double.infinity,
                  color: AppColors.primaryTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SafeArea(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, -0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _mode == _AuthMode.signIn
                          ? _buildSignInHeader()
                          : _buildSignUpHeader(),
                    ),
                  ),
                ),
              ),

              // Layer 2: Form Panel
              Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, -5),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(30, 32, 30, 40),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: _mode == _AuthMode.signIn
                        ? _buildSignInForm()
                        : _buildSignUpForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInHeader() {
    return Column(
      key: const ValueKey('signInHeader'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hello, Welcome Back!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Belum punya akun? ',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _mode = _AuthMode.signUp;
                  _clearError();
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
              child: const Text('Register'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpHeader() {
    return Column(
      key: const ValueKey('signUpHeader'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Sudah punya akun? ',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _mode = _AuthMode.signIn;
                  _clearError();
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignInForm() {
    return Column(
      key: const ValueKey('signInForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Login',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),

        // Error message dengan shake animation
        _ErrorBanner(
          shake: _shake,
          message: _errorMessage,
          isRegister: false,
          onSignUpTap: () {
            setState(() {
              _mode = _AuthMode.signUp;
              _clearError();
            });
          },
        ),

        ShakeWidget(
          shake: _shake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _usernameController,
                onChanged: (_) => _clearError(),
                decoration: _inputDecoration(
                  'Username',
                  Icons.person_outline,
                  hasError: _usernameError,
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (_) => _clearError(),
                decoration: _inputDecoration(
                  'Password',
                  Icons.lock_outline,
                  isPassword: true,
                  obscure: _obscurePassword,
                  hasError: _passwordError,
                  onToggleObscure: () => setState(
                      () => _obscurePassword = !_obscurePassword),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleSubmit(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _buildGradientButton('Login', _handleSubmit),
        const SizedBox(height: 20),
        _buildGoogleDivider(),
        const SizedBox(height: 16),
        _buildGoogleButton(),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      key: const ValueKey('signUpForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Register',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),

        // Error message dengan shake animation
        _ErrorBanner(
          shake: _shake,
          message: _errorMessage,
          isRegister: true,
          onSignUpTap: () {},
        ),

        ShakeWidget(
          shake: _shake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _usernameController,
                onChanged: (_) => _clearError(),
                decoration: _inputDecoration(
                  'Username',
                  Icons.person_outline,
                  hasError: _usernameError,
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _namaLengkapController,
                decoration: _inputDecoration('Nama Lengkap', Icons.badge_outlined),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (_) => _clearError(),
                decoration: _inputDecoration(
                  'Password',
                  Icons.lock_outline,
                  isPassword: true,
                  obscure: _obscurePassword,
                  hasError: _passwordError,
                  onToggleObscure: () => setState(
                      () => _obscurePassword = !_obscurePassword),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _konfirmasiPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: _inputDecoration(
                  'Konfirmasi Password',
                  Icons.lock_outline,
                  isPassword: true,
                  obscure: _obscureConfirmPassword,
                  onToggleObscure: () => setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleSubmit(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
        _buildGradientButton('Register', _handleSubmit),
        const SizedBox(height: 20),
        _buildGoogleDivider(),
        const SizedBox(height: 16),
        _buildGoogleButton(),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String hintText,
    IconData suffixIcon, {
    bool isPassword = false,
    bool obscure = false,
    bool hasError = false,
    VoidCallback? onToggleObscure,
  }) {
    const errorColor = AppColors.maroon;
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey.shade100,
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: hasError ? errorColor : Colors.grey,
              ),
              onPressed: onToggleObscure,
            )
          : Icon(suffixIcon, color: hasError ? errorColor : Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: hasError
            ? const BorderSide(color: AppColors.maroon, width: 1.5)
            : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: hasError
            ? const BorderSide(color: AppColors.maroon, width: 1.5)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: hasError ? AppColors.maroon : AppColors.primaryTeal,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildGoogleDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'atau',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _loading ? null : _signInWithGoogle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" logo — SVG dari CDN resmi Google
            SizedBox(
              width: 20,
              height: 20,
              child: Image.network(
                'https://www.google.com/favicon.ico',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const CustomPaint(
                  painter: _GoogleLogoPainter(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Lanjutkan dengan Google',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: _loading ? null : onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryTeal, Color(0xFF1A8A70)],
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryTeal.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Header clipper untuk efek melengkung di bagian atas.
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    final controlPoint = Offset(size.width / 2, size.height + 20);
    final endPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
        controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Banner error dengan styling yang jelas dan animasi fade-in.
class _ErrorBanner extends StatelessWidget {
  final String? message;
  final bool shake;
  final bool isRegister;
  final VoidCallback onSignUpTap;

  const _ErrorBanner({
    required this.message,
    required this.shake,
    required this.isRegister,
    required this.onSignUpTap,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    final showSignUpCta = !isRegister &&
        (message!.toLowerCase().contains('tidak terdaftar') ||
            message!.toLowerCase().contains('tidak ditemukan'));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(message),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.maroon.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.maroon, width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.maroon,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message!,
                    style: const TextStyle(
                      color: AppColors.maroon,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (showSignUpCta) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onSignUpTap,
                  icon: const Icon(
                    Icons.person_add_alt_1,
                    size: 16,
                    color: AppColors.primaryTeal,
                  ),
                  label: const Text(
                    'Daftar sekarang →',
                    style: TextStyle(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget yang shake ke kiri-kanan saat [shake] = true.
/// Dipakai untuk efek visual saat error muncul.
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;

  const ShakeWidget({
    super.key,
    required this.child,
    required this.shake,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(covariant ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0);
    }
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
        // Oscillasi: -10 → 10 → -10 → 10 → 0
        double offset = 0;
        if (_controller.value < 0.2) {
          offset = -10 * (_controller.value / 0.2);
        } else if (_controller.value < 0.4) {
          offset = 10 * ((_controller.value - 0.2) / 0.2);
        } else if (_controller.value < 0.6) {
          offset = -10 * ((_controller.value - 0.4) / 0.2);
        } else if (_controller.value < 0.8) {
          offset = 10 * ((_controller.value - 0.6) / 0.2);
        } else {
          offset = -10 * (1 - (_controller.value - 0.8) / 0.2);
        }
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// CustomPainter logo Google "G" akurat — dipakai sebagai fallback
/// jika Image.network gagal load.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2 * 0.85;
    final double strokeW = r * 0.38;

    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Merah: kiri atas (225° → 90°) = -π*1.25 span π/2*2.0
    paint.color = red;
    canvas.drawArc(rect, -2.356, 1.833, false, paint);

    // Kuning: kiri bawah (135° → 90°) = π*0.75 span π/2
    paint.color = yellow;
    canvas.drawArc(rect, 2.356, 1.047, false, paint);

    // Hijau: bawah kanan (225° → 90°) = π*1.25 span π/2
    paint.color = green;
    canvas.drawArc(rect, 3.403, 0.785, false, paint);

    // Biru: kanan atas → kanan (315° → 135°)
    paint.color = blue;
    canvas.drawArc(rect, -0.785, 1.571, false, paint);

    // Bar horizontal kanan (garis mendatar G)
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r, cy),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
