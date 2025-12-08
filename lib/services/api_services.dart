import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://dummyjson.com';

  // Get products (simulasi data transaksi)
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products?limit=10'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['products']);
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get single product detail
  Future<Map<String, dynamic>> getProductDetail(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$id'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load product detail');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get carts (simulasi data penjualan)
  Future<List<Map<String, dynamic>>> getCarts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/carts?limit=5'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['carts']);
      } else {
        throw Exception('Failed to load carts');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get users (simulasi data pelanggan)
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users?limit=10'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['users']);
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}