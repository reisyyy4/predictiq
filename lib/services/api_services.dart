import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  // Mengakses client Supabase yang sudah diinit di main.dart
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Get products
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('id', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getProducts: $e');
      throw Exception('Gagal memuat data produk');
    }
  }

  // 2. Get single product detail
  Future<Map<String, dynamic>> getProductDetail(int id) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', id)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error getProductDetail: $e');
      throw Exception('Gagal memuat detail produk');
    }
  }

  // 3. Get carts (Data Transaksi)
  // Fungsi ini "meratakan" struktur relasional SQL menjadi JSON sederhana
  Future<List<Map<String, dynamic>>> getCarts() async {
    try {
      // Query mengambil Cart -> Detail Item -> Info Produk
      final response = await _supabase.from('carts').select('''
        *,
        cart_items (
          quantity,
          products (
            id,
            title,
            price,
            thumbnail
          )
        )
      ''').order('id', ascending: false);

      final List<Map<String, dynamic>> formattedCarts = response.map((cart) {
        final List<dynamic> rawItems = cart['cart_items'] ?? [];
        
        // Memformat produk agar quantity masuk ke dalam object produk
        // (Sesuai ekspektasi UI AnalyticsPage)
        final List<Map<String, dynamic>> products = rawItems.map((item) {
          final productInfo = item['products'];
          final int quantity = item['quantity'];
          // Pastikan harga dianggap angka (num) agar aman dikalikan
          final double price = (productInfo['price'] as num).toDouble();
          
          return {
            'id': productInfo['id'],
            'title': productInfo['title'],
            'price': price,
            'quantity': quantity,
            'total': price * quantity, 
            'thumbnail': productInfo['thumbnail'],
            'discountPercentage': 0, // Default value
          };
        }).toList();

        // Mapping Header Cart (snake_case database ke camelCase Flutter)
        return {
          'id': cart['id'],
          'total': (cart['total'] ?? 0).toDouble(),
          // Mapping discounted_total (DB) ke discountedTotal (UI)
          'discountedTotal': (cart['discounted_total'] ?? cart['total']).toDouble(),
          'userId': cart['user_id'],
          'totalProducts': products.length,
          'totalQuantity': products.fold(0, (sum, item) => sum + (item['quantity'] as int)),
          'products': products, // List produk yang sudah dirapikan
        };
      }).toList();

      return formattedCarts;
    } catch (e) {
      debugPrint('Error getCarts: $e');
      throw Exception('Gagal memuat data transaksi');
    }
  }

  // 4. Get users (Disesuaikan dengan Database Anda)
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .limit(10);
      
      // Mapping khusus untuk tabel 'users' Anda
      final List<Map<String, dynamic>> formattedUsers = response.map((user) {
        return {
          'id': user['id'],
          
          // MAPPING KUNCI: 
          // Database Anda pakai kolom 'nama', tapi UI mungkin cari 'firstName'
          'firstName': user['nama'] ?? 'User', 
          'lastName': '', 
          'email': user['email'] ?? '',
          'phone': user['phone'] ?? '',
          
          // Generator Avatar jika gambar kosong
          'image': user['image'] ?? 'https://ui-avatars.com/api/?name=${user['nama']}&background=random',
        };
      }).toList();

      return formattedUsers;
    } catch (e) {
      debugPrint('Error getUsers: $e');
      // Return list kosong agar aplikasi tidak crash jika tabel user bermasalah
      return []; 
    }
  }
}