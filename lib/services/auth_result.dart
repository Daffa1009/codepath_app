/// Hasil autentikasi dari AuthService.login() atau .register().
class AuthResult {
  final String userId;
  final String role; // 'user' atau 'admin'
  final String username;
  final String namaLengkap;
  final String? avatarUrl;

  const AuthResult({
    required this.userId,
    required this.role,
    required this.username,
    required this.namaLengkap,
    this.avatarUrl,
  });

  bool get isAdmin => role == 'admin';
}
