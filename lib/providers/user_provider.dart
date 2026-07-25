import 'package:flutter/foundation.dart';
import '../services/auth_result.dart';

/// Provider untuk menyimpan data user yang sedang login.
/// Dipakai oleh seluruh widget tree untuk akses username, namaLengkap, role.
class UserProvider extends ChangeNotifier {
  AuthResult? _user;

  AuthResult? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  String get username => _user?.username ?? '';
  String get namaLengkap => _user?.namaLengkap ?? '';

  void setUser(AuthResult? user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
