/// Hasil autentikasi dari AuthService.login() atau .register().
class AuthResult {
  final String userId;
  final String role; // 'user' atau 'admin'
  final String username;
  final String namaLengkap;

  const AuthResult({
    required this.userId,
    required this.role,
    required this.username,
    required this.namaLengkap,
  });

  bool get isAdmin => role == 'admin';
}
