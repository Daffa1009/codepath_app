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
  String? _errorMessage;

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
      setState(() => _errorMessage = error);
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
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
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryTeal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text('Hello', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                _mode == _AuthMode.signIn
                    ? 'Login untuk melanjutkan'
                    : 'Daftar akun baru',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 48),

              // Tab toggle Sign In / Sign Up
              Row(
                children: [
                  _tabButton('Sign In', _AuthMode.signIn),
                  const SizedBox(width: 12),
                  _tabButton('Sign Up', _AuthMode.signUp),
                ],
              ),
              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.maroon.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.maroon.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.maroon, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.maroon,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Username field
              _fieldLabel('Username'),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Masukkan username'),
              ),
              const SizedBox(height: 20),

              // Nama Lengkap (hanya saat sign up)
              if (_mode == _AuthMode.signUp) ...[
                _fieldLabel('Nama Lengkap'),
                const SizedBox(height: 8),
                TextField(
                  controller: _namaLengkapController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(hintText: 'Masukkan nama lengkap'),
                ),
                const SizedBox(height: 20),
              ],

              // Password field
              _fieldLabel('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: _mode == _AuthMode.signUp
                    ? TextInputAction.next
                    : TextInputAction.done,
                decoration: const InputDecoration(hintText: 'Masukkan password'),
              ),
              const SizedBox(height: 20),

              // Konfirmasi Password (hanya saat sign up)
              if (_mode == _AuthMode.signUp) ...[
                _fieldLabel('Konfirmasi Password'),
                const SizedBox(height: 8),
                TextField(
                  controller: _konfirmasiPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration:
                      const InputDecoration(hintText: 'Ulangi password'),
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryTeal,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _mode == _AuthMode.signIn ? 'Sign In' : 'Sign Up',
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, _AuthMode mode) {
    final active = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _mode = mode;
            _errorMessage = null;
          });
        },
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white24 : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: active ? Colors.white : Colors.white30,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.white60,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
    );
  }
}
