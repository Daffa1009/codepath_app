import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_result.dart';

/// Service autentikasi CodePath.
/// Menggunakan Supabase Auth dengan pendekatan username + password:
/// register/login via email sintetis '$username@codepath.local'.
class AuthService {
  AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Bersihkan username: lowercase, trim, hapus semua karakter selain
  /// huruf kecil, angka, underscore, dan strip.
  static String _sanitizeUsername(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '');
  }

  /// Generate email sintetis dari username.
  static String _emailFromUsername(String username) {
    return '${_sanitizeUsername(username)}@codepath.local';
  }

  /// REGISTER user baru.
  ///
  /// [username] — akan di-lowercase, di-trim, dan dibersihkan.
  /// [password] — password mentah dari form (min 6 karakter, divalidasi UI).
  /// [namaLengkap] — nama tampilan user.
  ///
  /// Throw [AuthException] dengan pesan Bahasa Indonesia jika gagal.
  static Future<AuthResult> register({
    required String username,
    required String password,
    required String namaLengkap,
  }) async {
    final cleanUsername = _sanitizeUsername(username);
    if (cleanUsername.isEmpty || cleanUsername.length < 3) {
      throw const AuthException('Username minimal 3 karakter (tanpa spasi).');
    }

    final email = _emailFromUsername(cleanUsername);

    // 1. Sign up via Supabase Auth dengan email sintetis.
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': cleanUsername,
        'nama_lengkap': namaLengkap.trim(),
      },
    );

    final user = authResponse.user;
    if (user == null) {
      throw const AuthException('Registrasi gagal. Silakan coba lagi.');
    }

    // 2. Update profiles row dengan username & nama_lengkap
    //    (trigger sudah buat row-nya, tapi mungkin dengan data kosong
    //     kalau raw_user_meta_data tidak langsung terbaca).
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'username': cleanUsername,
        'nama_lengkap': namaLengkap.trim(),
        'role': 'user',
      });
    } catch (_) {
      // Jika upsert gagal (misal karena RLS), profile mungkin sudah benar
      // dari trigger. Lanjutkan saja.
    }

    return AuthResult(
      userId: user.id,
      role: 'user',
      username: cleanUsername,
      namaLengkap: namaLengkap.trim(),
    );
  }

  /// LOGIN dengan username + password.
  ///
  /// Return [AuthResult] dengan role dari tabel profiles.
  /// Throw [AuthException] dengan pesan Bahasa Indonesia jika gagal.
  static Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final cleanUsername = _sanitizeUsername(username);
    final email = _emailFromUsername(cleanUsername);

    // 1. Sign in via Supabase Auth.
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) {
      throw const AuthException('Username atau password salah.');
    }

    // 2. Fetch role & nama_lengkap dari tabel profiles.
    final profileResponse = await _client
        .from('profiles')
        .select('username, nama_lengkap, role, avatar_url')
        .eq('id', user.id)
        .maybeSingle();

    final role = profileResponse?['role'] as String? ?? 'user';
    final dbUsername = profileResponse?['username'] as String? ?? cleanUsername;
    final namaLengkap =
        profileResponse?['nama_lengkap'] as String? ?? cleanUsername;
    final avatarUrl = profileResponse?['avatar_url'] as String?;

    return AuthResult(
      userId: user.id,
      role: role,
      username: dbUsername,
      namaLengkap: namaLengkap,
      avatarUrl: avatarUrl,
    );
  }

  /// LOGOUT — clear session.
  static Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Cek apakah ada session aktif (user sudah login sebelumnya).
  static bool get isLoggedIn => _client.auth.currentUser != null;

  /// Ambil AuthResult dari session yang sedang aktif.
  /// Return null jika tidak ada session.
  static Future<AuthResult?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final profileResponse = await _client
        .from('profiles')
        .select('username, nama_lengkap, role, avatar_url')
        .eq('id', user.id)
        .maybeSingle();

    if (profileResponse == null) return null;

    return AuthResult(
      userId: user.id,
      role: profileResponse['role'] as String? ?? 'user',
      username: profileResponse['username'] as String,
      namaLengkap: profileResponse['nama_lengkap'] as String? ?? '',
      avatarUrl: profileResponse['avatar_url'] as String?,
    );
  }
}

/// Exception dengan pesan Bahasa Indonesia untuk ditampilkan di UI.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
