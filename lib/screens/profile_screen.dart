import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/auth_result.dart';
import 'login_screen.dart';

/// Halaman profil user — lihat & edit profil, ganti password, logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _savingProfile = false;
  bool _changingPassword = false;
  String? _profileError;
  String? _passwordError;
  String? _profileSuccess;
  String? _passwordSuccess;

  late TextEditingController _namaCtrl;
  late TextEditingController _oldPassCtrl;
  late TextEditingController _newPassCtrl;
  late TextEditingController _confirmPassCtrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _namaCtrl = TextEditingController(text: user?.namaLengkap ?? '');
    _oldPassCtrl = TextEditingController();
    _newPassCtrl = TextEditingController();
    _confirmPassCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  SupabaseClient get _client => Supabase.instance.client;

  /// Inisial dari nama lengkap untuk avatar.
  String _getInitials() {
    final nama = context.read<UserProvider>().namaLengkap;
    if (nama.isEmpty) return '?';
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return nama[0].toUpperCase();
  }

  Future<void> _updateProfile() async {
    final newName = _namaCtrl.text.trim();
    if (newName.isEmpty) {
      setState(() => _profileError = 'Nama tidak boleh kosong.');
      return;
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _savingProfile = true;
      _profileError = null;
      _profileSuccess = null;
    });

    try {
      await _client
          .from('profiles')
          .update({'nama_lengkap': newName}).eq('id', userId);

      // Update UserProvider agar nama langsung berubah di UI
      if (mounted) {
        final user = context.read<UserProvider>().user;
        if (user != null) {
          context.read<UserProvider>().setUser(AuthResult(
                userId: user.userId,
                role: user.role,
                username: user.username,
                namaLengkap: newName,
              ));
        }
        setState(() {
          _savingProfile = false;
          _profileSuccess = 'Profil berhasil diperbarui.';
        });
      }
    } catch (e) {
      setState(() {
        _savingProfile = false;
        _profileError = 'Gagal memperbarui profil.';
      });
    }
  }

  Future<void> _changePassword() async {
    final oldPass = _oldPassCtrl.text;
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _passwordError = 'Semua field password harus diisi.');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _passwordError = 'Password baru minimal 6 karakter.');
      return;
    }
    if (newPass != confirmPass) {
      setState(
          () => _passwordError = 'Konfirmasi password baru tidak cocok.');
      return;
    }

    setState(() {
      _changingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPass),
      );
      if (mounted) {
        setState(() {
          _changingPassword = false;
          _passwordSuccess = 'Password berhasil diganti.';
        });
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
      }
    } catch (e) {
      setState(() {
        _changingPassword = false;
        _passwordError = 'Gagal mengganti password. Pastikan password lama benar.';
      });
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yakin ingin keluar?',
            style: TextStyle(
                color: AppColors.maroon, fontWeight: FontWeight.w700)),
        content: const Text('Kamu akan kembali ke halaman login.',
            style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.maroon,
                foregroundColor: Colors.white,
                shape: const StadiumBorder()),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      if (!mounted) return;
      context.read<UserProvider>().clearUser();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final displayName =
        user?.namaLengkap ?? user?.username ?? 'Pengguna';
    final username = user?.username ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Avatar besar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryTeal,
                child: Text(
                  _getInitials(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nama & username
            Text(
              displayName,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textMuted),
            ),

            const SizedBox(height: 32),

            // === UPDATE PROFIL ===
            _sectionTitle('Update Profil'),
            const SizedBox(height: 12),
            if (_profileSuccess != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_profileSuccess!,
                    style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
            if (_profileError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.maroon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_profileError!,
                    style: const TextStyle(
                        color: AppColors.maroon,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
            TextField(
              controller: _namaCtrl,
              decoration: const InputDecoration(
                hintText: 'Nama Lengkap',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingProfile ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                ),
                child: _savingProfile
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan Perubahan'),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // === GANTI PASSWORD ===
            _sectionTitle('Ganti Password'),
            const SizedBox(height: 12),
            if (_passwordSuccess != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_passwordSuccess!,
                    style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
            if (_passwordError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.maroon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_passwordError!,
                    style: const TextStyle(
                        color: AppColors.maroon,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
            TextField(
              controller: _oldPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password Lama',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password Baru (min. 6 karakter)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Konfirmasi Password Baru',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _changingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                ),
                child: _changingPassword
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Ganti Password'),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // === LOGOUT ===
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.maroon,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryTeal,
        ),
      ),
    );
  }
}
