import 'dart:typed_data';
import 'dart:ui' as ui_img;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/auth_result.dart';
import 'login_screen.dart';

/// Halaman profil user — lihat & edit profil, ganti password, logout, upload foto.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _savingProfile = false;
  bool _changingPassword = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;
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
    _avatarUrl = user?.avatarUrl;
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

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    
    if (image == null) return;
    
    final rawBytes = await image.readAsBytes();
    
    if (!mounted) return;
    
    // Tampilkan Dialog Crop / Sesuaikan
    final Uint8List? croppedBytes = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CropDialog(imageBytes: rawBytes),
    );
    
    if (croppedBytes == null) return;
    
    setState(() => _uploadingAvatar = true);
    
    try {
      final userId = _client.auth.currentUser!.id;
      final fileName = '$userId.png'; // Di-crop & dieksport sebagai PNG
      
      // Upload ke Supabase Storage bucket "avatars"
      await _client.storage
        .from('avatars')
        .uploadBinary(
          fileName,
          croppedBytes,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: true,
          ),
        );
      
      // Ambil public URL
      final publicUrl = _client.storage
        .from('avatars')
        .getPublicUrl(fileName);
      
      // Tambahkan cache buster
      final urlWithCacheBuster = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      
      // Update tabel profiles
      await _client
        .from('profiles')
        .update({'avatar_url': urlWithCacheBuster})
        .eq('id', userId);
      
      if (mounted) {
        context.read<UserProvider>().updateAvatarUrl(urlWithCacheBuster);
        setState(() {
          _avatarUrl = urlWithCacheBuster;
          _uploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload foto: ${e.toString()}'),
            backgroundColor: AppColors.maroon,
          ),
        );
      }
    }
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

      if (mounted) {
        final user = context.read<UserProvider>().user;
        if (user != null) {
          context.read<UserProvider>().setUser(AuthResult(
                userId: user.userId,
                role: user.role,
                username: user.username,
                namaLengkap: newName,
                avatarUrl: user.avatarUrl,
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

            // Avatar Upload Stack
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: _avatarUrl != null 
                      ? NetworkImage(_avatarUrl!) 
                      : null,
                    backgroundColor: AppColors.primaryTeal,
                    child: _avatarUrl == null 
                      ? Text(_getInitials(), style: const TextStyle(fontSize: 32, color: Colors.white))
                      : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  if (_uploadingAvatar)
                    const Positioned.fill(
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.black45,
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
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
                hintText: 'Password Baru',
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _changingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
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
            const SizedBox(height: 24),

            // === LOGOUT ===
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.maroon),
                  foregroundColor: AppColors.maroon,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Keluar Aplikasi'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTeal),
      ),
    );
  }
}

class _CropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  const _CropDialog({required this.imageBytes});

  @override
  State<_CropDialog> createState() => _CropDialogState();
}

class _CropDialogState extends State<_CropDialog> {
  final GlobalKey _repaintKey = GlobalKey();

  Future<void> _cropAndSave() async {
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // Beri sedikit delay agar rendering selesai
      await Future.delayed(const Duration(milliseconds: 100));
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui_img.ImageByteFormat.png);
      if (!mounted) return;
      if (byteData != null) {
        Navigator.pop(context, byteData.buffer.asUint8List());
      } else {
        Navigator.pop(context, null);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Sesuaikan Foto Profil',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryTeal,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Geser & cubit/scroll untuk memperbesar atau menggeser gambar agar pas di dalam lingkaran.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black12,
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(50),
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.cover,
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _cropAndSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
          child: const Text('Simpan & Crop'),
        ),
      ],
    );
  }
}

