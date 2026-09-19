import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../providers/user_provider.dart';
import '../services/auth_result.dart';
import 'main_nav_screen.dart';
import 'login_screen.dart';

/// Layar pengaturan username untuk user yang login via Google
/// dan belum memiliki row di tabel profiles.
class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final _usernameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  SupabaseClient get _client => Supabase.instance.client;

  String? _validateUsername(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.length < 3) return 'Username minimal 3 karakter.';
    if (trimmed.contains(' ')) return 'Username tidak boleh mengandung spasi.';
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(trimmed)) {
      return 'Hanya huruf kecil, angka, dan underscore (_).';
    }
    return null;
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim().toLowerCase();
    final validationError = _validateUsername(username);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Session tidak ditemukan.');

      final fullName =
          (user.userMetadata?['full_name'] as String?) ??
          (user.userMetadata?['name'] as String?) ??
          '';
      final avatarUrl = user.userMetadata?['avatar_url'] as String?;

      // Cek apakah username sudah dipakai orang lain
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (existing != null) {
        setState(() {
          _loading = false;
          _error = 'Username "$username" sudah dipakai. Coba yang lain.';
        });
        return;
      }

      // Insert profile baru
      await _client.from('profiles').insert({
        'id': user.id,
        'username': username,
        'nama_lengkap': fullName,
        'role': 'user',
        'avatar_url': avatarUrl,
      });

      if (!mounted) return;

      final authResult = AuthResult(
        userId: user.id,
        role: 'user',
        username: username,
        namaLengkap: fullName,
        avatarUrl: avatarUrl,
      );

      context.read<UserProvider>().setUser(authResult);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainNavScreen(user: authResult)),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Terjadi kesalahan: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _cancelAndLogout() async {
    await _client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final fullName =
        (user?.userMetadata?['full_name'] as String?) ??
        (user?.userMetadata?['name'] as String?) ??
        '';

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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Ikon celebrasi
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🎉', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Satu langkah lagi!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryTeal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih username untuk akun CodePath kamu',
                  style: TextStyle(fontSize: 15, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Avatar Google user
                if (avatarUrl != null)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(avatarUrl),
                    backgroundColor: Colors.grey.shade200,
                  )
                else
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryTeal,
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'G',
                      style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ),

                if (fullName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    fullName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                ],

                const SizedBox(height: 32),

                // Error banner
                if (_error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.maroon.withValues(alpha: 0.08),
                      border:
                          Border.all(color: AppColors.maroon, width: 1.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.maroon, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: AppColors.maroon,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Username field
                TextField(
                  controller: _usernameCtrl,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    hintText: 'Username (misal: budi_123)',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: const Icon(Icons.alternate_email,
                        color: AppColors.primaryTeal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primaryTeal, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    helperText:
                        'Gunakan huruf kecil, angka, atau underscore (_)',
                    helperStyle: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  autocorrect: false,
                  enableSuggestions: false,
                ),

                const SizedBox(height: 28),

                // Tombol Mulai Belajar
                InkWell(
                  onTap: _loading ? null : _submit,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryTeal,
                          Color(0xFF1A8A70)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.primaryTeal.withValues(alpha: 0.3),
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
                          : const Text(
                              'Mulai Belajar 🚀',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Cancel — logout dan kembali ke login
                TextButton(
                  onPressed: _loading ? null : _cancelAndLogout,
                  child: const Text(
                    'Batal & kembali ke login',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
