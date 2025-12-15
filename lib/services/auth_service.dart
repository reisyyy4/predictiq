import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyEmail = 'userEmail';
  static const String _keyName = 'userName';

  // Cek Status Login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Ambil Data User (dari Cache HP)
  Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyEmail) ?? '',
      'name': prefs.getString(_keyName) ?? '',
    };
  }

  // --- REGISTRASI ---
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Daftar ke Supabase Auth (Sistem Keamanan)
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // 2. Simpan Biodata ke Tabel Manual 'users'
      if (res.user != null) {
        try {
           await _supabase.from('users').insert({
             'id': res.user!.id,  // ID dari Auth
             'nama': name,        // <--- Sesuai kolom database Anda ('nama')
             'email': email,
             // Note: Password tidak perlu disimpan di sini demi keamanan
           });
        } catch (e) {
          print("Error simpan ke tabel users: $e");
        }
        return true; 
      }
      return false;
    } catch (e) {
      print("Register Error: $e");
      return false;
    }
  }

  // --- LOGIN ---
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. Cek Password ke Supabase Auth
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // 2. Jika Password Benar (Login Sukses)
      if (res.session != null) {
        String userName = 'User';

        try {
          // Ambil nama dari tabel 'users'
          final data = await _supabase
              .from('users')         // <--- Nama Tabel: users
              .select('nama')        // <--- Nama Kolom: nama (JANGAN 'name')
              .eq('id', res.user!.id)
              .single();
          
          userName = data['nama'];   // <--- Ambil datanya juga pakai 'nama'
          
        } catch (e) {
          print("Gagal ambil nama: $e");
        }

        // 3. Simpan ke HP (SharedPreferences)
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyEmail, email);
        await prefs.setString(_keyName, userName);
        
        return true;
      }
      
      return false;
    } catch (e) {
      print("Login Gagal: $e");
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _supabase.auth.signOut();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
  }
}