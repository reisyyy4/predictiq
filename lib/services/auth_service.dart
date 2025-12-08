import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Keys untuk SharedPreferences
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyEmail = 'userEmail';
  static const String _keyName = 'userName';
  static const String _keyUsersData = 'usersData';

  // Check apakah user sudah login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get user info
  Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyEmail) ?? '',
      'name': prefs.getString(_keyName) ?? '',
    };
  }

  // Register user baru
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Simulasi validasi email sudah terdaftar
    final existingUsers = prefs.getStringList(_keyUsersData) ?? [];
    if (existingUsers.any((user) => user.contains(email))) {
      return false; // Email sudah terdaftar
    }

    // Simpan user baru (format: "email|password|name")
    existingUsers.add('$email|$password|$name');
    await prefs.setStringList(_keyUsersData, existingUsers);
    
    return true;
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ambil data users
    final existingUsers = prefs.getStringList(_keyUsersData) ?? [];
    
    // Cari user yang cocok
    for (var userData in existingUsers) {
      final parts = userData.split('|');
      if (parts[0] == email && parts[1] == password) {
        // Login berhasil, simpan session
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyEmail, email);
        await prefs.setString(_keyName, parts[2]);
        return true;
      }
    }
    
    return false; // Login gagal
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
  }
}