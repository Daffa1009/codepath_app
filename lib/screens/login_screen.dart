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

  Future<void> _handleSubmit() async {
    final error = _validate();
    if (error != null) {
      _showSnackBar(error, isError: true);
      return;
    }

    setState(() {
      _loading = true;
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
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar('Terjadi kesalahan. Silakan coba lagi.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.maroon : AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                          ? Column(
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
                            )
                          : Column(
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
                            ),
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
        TextField(
          controller: _usernameController,
          decoration: _inputDecoration('Username', Icons.person_outline),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: _inputDecoration('Password', Icons.lock_outline,
              isPassword: true,
              obscure: _obscurePassword,
              onToggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword)),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSubmit(),
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
        TextField(
          controller: _usernameController,
          decoration: _inputDecoration('Username', Icons.person_outline),
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
          decoration: _inputDecoration('Password', Icons.lock_outline,
              isPassword: true,
              obscure: _obscurePassword,
              onToggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword)),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _konfirmasiPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: _inputDecoration('Konfirmasi Password', Icons.lock_outline,
              isPassword: true,
              obscure: _obscureConfirmPassword,
              onToggleObscure: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword)),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSubmit(),
        ),
        const SizedBox(height: 28),
        _buildGradientButton('Register', _handleSubmit),
      ],
    );
  }

  InputDecoration _inputDecoration(String hintText, IconData suffixIcon,
      {bool isPassword = false,
      bool obscure = false,
      VoidCallback? onToggleObscure}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey.shade100,
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onToggleObscure,
            )
          : Icon(suffixIcon, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
