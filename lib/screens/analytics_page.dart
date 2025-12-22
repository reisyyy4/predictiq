import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Tambahan Import
import '../services/api_services.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final ApiService _apiService = ApiService();
  final SupabaseClient _supabase =
      Supabase.instance.client; // Tambahan Client Supabase

  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _carts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _apiService.getProducts();
      final carts = await _apiService.getCarts();
      setState(() {
        _products = products;
        _carts = carts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // --- TAMBAHAN: FUNGSI HAPUS TRANSAKSI ---
  Future<void> _deleteTransaction(int cartId) async {
    try {
      // Hapus dari database Supabase
      await _supabase.from('carts').delete().eq('id', cartId);

      // Hapus dari tampilan lokal tanpa refresh loading
      setState(() {
        _carts.removeWhere((item) => item['id'] == cartId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _calculateTotalRevenue() {
    double total = 0;
    for (var cart in _carts) {
      total += (cart['total'] ?? 0).toDouble();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Analisis Prediktif"),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Prediksi Penjualan"),
              Tab(text: "Data Produk"),
              Tab(text: "Transaksi"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildPredictionTab(),
                  _buildProductsTab(),
                  _buildTransactionsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildPredictionTab() {
    final totalRevenue = _calculateTotalRevenue();
    final avgPerTransaction = _carts.isEmpty ? 0 : totalRevenue / _carts.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Penjualan',
                '\$${totalRevenue.toStringAsFixed(2)}',
                Colors.blue,
                Icons.attach_money,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Transaksi',
                '${_carts.length}',
                Colors.green,
                Icons.shopping_cart,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Rata-rata',
                '\$${avgPerTransaction.toStringAsFixed(2)}',
                Colors.orange,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Produk',
                '${_products.length}',
                Colors.purple,
                Icons.inventory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        const Text(
          "Proyeksi 30 Hari Kedepan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.show_chart, size: 60, color: Colors.blue),
                const SizedBox(height: 8),
                Text(
                  'Prediksi: \$${(totalRevenue * 1.15).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Text(
                  '+15% dari bulan ini',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          "Produk Paling Berpotensi Laris:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ..._products.take(5).map((product) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(product['thumbnail'] ?? ''),
                backgroundColor: Colors.grey[300],
              ),
              title: Text(product['title'] ?? 'Unknown'),
              subtitle: Text(
                'Stock: ${product['stock']} | \$${product['price']}',
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      color: Colors.green,
                      size: 16,
                    ),
                    Text(
                      '${product['rating'] ?? 0}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildProductsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product['thumbnail'] ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            title: Text(
              product['title'] ?? 'Unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              product['category'] ?? 'N/A',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${product['price']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Stock: ${product['stock']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            onTap: () => _showProductDetail(product),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _carts.length,
      itemBuilder: (context, index) {
        final cart = _carts[index];
        final products = cart['products'] as List<dynamic>? ?? [];

        // Logic Perhitungan
        final double originalPrice = (cart['total'] ?? 0).toDouble();
        final double finalPrice = (cart['discountedTotal'] ?? 0).toDouble();
        final double discountAmount = originalPrice - finalPrice;

        // --- TAMBAHAN: DISMISSIBLE UNTUK SLIDE DELETE ---
        return Dismissible(
          key: Key(cart['id'].toString()), // Key unik wajib ada
          direction: DismissDirection.endToStart, // Geser Kanan ke Kiri
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            color: Colors.red, // Warna latar saat digeser
            child: const Icon(Icons.delete, color: Colors.white, size: 30),
          ),
          confirmDismiss: (direction) async {
            // Dialog Konfirmasi sebelum hapus
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Hapus Transaksi?"),
                  content: const Text(
                    "Data yang dihapus tidak dapat dikembalikan.",
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        "Hapus",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            // Panggil fungsi hapus
            _deleteTransaction(cart['id']);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal,
                child: Text('#${cart['id']}'),
              ),
              title: Text('User ID: ${cart['userId']}'),
              subtitle: Text(
                'Total: \$${finalPrice.toStringAsFixed(1)} | ${products.length} items',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Produk:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),

                      ...products.map((product) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Product ID: ${product['id']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                '${product['quantity']}x @ \$${product['price']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      const Divider(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '\$${originalPrice.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      if (discountAmount > 0.01)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Diskon',
                              style: TextStyle(color: Colors.green),
                            ),
                            Text(
                              '- \$${discountAmount.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                      const Divider(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Bayar:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '\$${finalPrice.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetail(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product['thumbnail'] ?? '',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product['title'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['description'] ?? 'No description',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Price', style: TextStyle(fontSize: 12)),
                          Text(
                            '\$${product['price']}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Stock', style: TextStyle(fontSize: 12)),
                          Text(
                            '${product['stock']}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Rating', style: TextStyle(fontSize: 12)),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              Text(
                                ' ${product['rating']}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
