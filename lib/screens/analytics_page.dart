import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_services.dart'; // Pastikan path ini sesuai

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final ApiService _apiService = ApiService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _carts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==========================================
  // 1. LOGIC LOAD DATA
  // ==========================================
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

  double _calculateTotalRevenue() {
    double total = 0;
    for (var cart in _carts) {
      total += (cart['total'] ?? 0).toDouble();
    }
    return total;
  }

  // ==========================================
  // 2. LOGIC TRANSAKSI (HAPUS)
  // ==========================================
  Future<void> _deleteTransaction(int cartId) async {
    try {
      await _supabase.from('carts').delete().eq('id', cartId);
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

  // ==========================================
  // 3. LOGIC PRODUK (EDIT & HAPUS ANTI-CRASH)
  // ==========================================

  Future<void> _deleteProduct(int productId) async {
    // Dialog Konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: const Text('Produk ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('products').delete().eq('id', productId);

      setState(() {
        _products.removeWhere((element) => element['id'] == productId);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Produk dihapus ✅')));
      }
    } catch (e) {
      // --- PERBAIKAN UTAMA DI SINI ---
      String errorMessage = 'Terjadi kesalahan: $e';

      // Deteksi Error Foreign Key (Data masih dipakai di transaksi)
      if (e is PostgrestException && e.code == '23503') {
        errorMessage =
            'Gagal: Produk ini pernah terjual! Hapus riwayat transaksinya dulu.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4), // Tampil lebih lama
          ),
        );
      }
    }
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final titleCtrl = TextEditingController(text: product['title']);
    final categoryCtrl = TextEditingController(text: product['category']);
    final priceCtrl = TextEditingController(text: product['price'].toString());
    final stockCtrl = TextEditingController(text: product['stock'].toString());
    final imgCtrl = TextEditingController(text: product['thumbnail']);

    showDialog(
      context: context,
      builder: (context) {
        bool isUpdating = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Produk'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Produk',
                      ),
                    ),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Harga',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Stok',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: imgCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                          setStateDialog(() => isUpdating = true);
                          try {
                            final updatedData = {
                              'title': titleCtrl.text,
                              'category': categoryCtrl.text,
                              'price': double.tryParse(priceCtrl.text) ?? 0,
                              'stock': int.tryParse(stockCtrl.text) ?? 0,
                              'thumbnail': imgCtrl.text,
                            };

                            await _supabase
                                .from('products')
                                .update(updatedData)
                                .eq('id', product['id']);

                            setState(() {
                              final index = _products.indexWhere(
                                (element) => element['id'] == product['id'],
                              );
                              if (index != -1) {
                                _products[index] = {
                                  ..._products[index],
                                  ...updatedData,
                                };
                              }
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Produk diupdate!'),
                                ),
                              );
                            }
                          } catch (e) {
                            setStateDialog(() => isUpdating = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                  child: isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 4. UI BUILDER
  // ==========================================

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
              Tab(text: "Prediksi"),
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

  // --- TAB 1: PREDIKSI ---
  Widget _buildPredictionTab() {
    final totalRevenue = _calculateTotalRevenue();
    final avgPerTransaction = _carts.isEmpty ? 0 : totalRevenue / _carts.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
          "Produk Berpotensi Laris:",
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
              trailing: const Icon(
                Icons.arrow_upward,
                color: Colors.green,
                size: 16,
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- TAB 2: DATA PRODUK (DENGAN EDIT & HAPUS) ---
  Widget _buildProductsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final int stock = product['stock'] ?? 0;
        final bool isLowStock = stock < 20;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product['thumbnail'] ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            title: Text(
              product['title'] ?? 'Unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['category'] ?? 'N/A',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: isLowStock
                      ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                      : EdgeInsets.zero,
                  decoration: isLowStock
                      ? BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        )
                      : null,
                  child: Text(
                    'Stock: $stock',
                    style: TextStyle(
                      color: isLowStock ? Colors.red : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: isLowStock
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${product['price']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _showEditProductDialog(product);
                    if (value == 'delete') _deleteProduct(product['id']);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => _showProductDetail(product),
          ),
        );
      },
    );
  }

  // --- TAB 3: TRANSAKSI (DENGAN SLIDE HAPUS) ---
  Widget _buildTransactionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _carts.length,
      itemBuilder: (context, index) {
        final cart = _carts[index];
        final products = cart['products'] as List<dynamic>? ?? [];
        final double finalPrice = (cart['discountedTotal'] ?? 0).toDouble();

        return Dismissible(
          key: Key(cart['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Hapus Transaksi?"),
                content: const Text("Data tidak bisa kembali."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Batal"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      "Hapus",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) => _deleteTransaction(cart['id']),
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
                      const Text(
                        'Detail Produk:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...products.map(
                        (p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('Product ID: ${p['id']}')),
                              Text(
                                '${p['quantity']}x @ \$${p['price']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total Bayar: \$${finalPrice.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.teal,
                          ),
                        ),
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

  // --- WIDGET HELPER ---
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
                          const Text('Price'),
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
                          const Text('Stock'),
                          Text(
                            '${product['stock']}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
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
