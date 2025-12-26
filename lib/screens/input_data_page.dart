import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InputDataPage extends StatefulWidget {
  const InputDataPage({super.key});

  @override
  State<InputDataPage> createState() => _InputDataPageState();
}

class _InputDataPageState extends State<InputDataPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- VARIABLES FOR TRANSACTION TAB ---
  bool _isLoadingTransaction = false;
  List<Map<String, dynamic>> _availableProducts = [];
  Map<String, dynamic>? _selectedProduct;
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final List<Map<String, dynamic>> _cartItems = [];

  // --- VARIABLES FOR ADD PRODUCT TAB ---
  bool _isLoadingProduct = false;
  final _formKeyProduct = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  // 1. Controller Baru untuk Deskripsi
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _imgUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    // 2. Dispose Controller Deskripsi
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imgUrlController.dispose();
    super.dispose();
  }

  // ==========================================
  // LOGIC
  // ==========================================

  Future<void> _fetchProducts() async {
    try {
      final data = await _supabase
          .from('products')
          .select('id, title, price, stock, thumbnail')
          .order('title');

      if (mounted) {
        setState(() {
          _availableProducts = List<Map<String, dynamic>>.from(data);

          if (_selectedProduct != null) {
            try {
              _selectedProduct = _availableProducts.firstWhere(
                (element) => element['id'] == _selectedProduct!['id'],
              );
            } catch (e) {
              _selectedProduct = null;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  void _addToCart() {
    if (_selectedProduct == null || _qtyController.text.isEmpty) return;

    final int qty = int.tryParse(_qtyController.text) ?? 1;
    final double price = (_selectedProduct!['price'] ?? 0).toDouble();
    final int currentStock = _selectedProduct!['stock'] ?? 0;

    if (qty > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok tidak cukup! Sisa stok: $currentStock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _cartItems.add({
        'product_id': _selectedProduct!['id'],
        'title': _selectedProduct!['title'],
        'thumbnail': _selectedProduct!['thumbnail'],
        'price': price,
        'quantity': qty,
        'subtotal': price * qty,
      });
      _selectedProduct = null;
      _qtyController.text = '1';
    });
  }

  Future<void> _submitTransaction() async {
    if (_cartItems.isEmpty) return;
    setState(() => _isLoadingTransaction = true);

    try {
      double total = 0;
      for (var item in _cartItems) total += item['subtotal'];

      final cartResponse = await _supabase
          .from('carts')
          .insert({
            'user_id': _supabase.auth.currentUser?.id,
            'total': total,
            'discounted_total': total,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final int newCartId = cartResponse['id'];

      for (var item in _cartItems) {
        final int productId = item['product_id'];
        final int qtySold = item['quantity'];

        await _supabase.from('cart_items').insert({
          'cart_id': newCartId,
          'product_id': productId,
          'quantity': qtySold,
        });

        final productData = await _supabase
            .from('products')
            .select('stock')
            .eq('id', productId)
            .single();

        final int currentStock = productData['stock'];
        int newStock = currentStock - qtySold;
        if (newStock < 0) newStock = 0;

        await _supabase
            .from('products')
            .update({'stock': newStock})
            .eq('id', productId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi Berhasil & Stok Berkurang! ✅'),
          ),
        );
        setState(() {
          _cartItems.clear();
        });
        _fetchProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoadingTransaction = false);
    }
  }

  Future<void> _submitNewProduct() async {
    if (!_formKeyProduct.currentState!.validate()) return;

    setState(() => _isLoadingProduct = true);

    try {
      final String title = _nameController.text;
      final String category = _categoryController.text;
      // Ambil teks deskripsi
      final String description = _descriptionController.text;
      final double price = double.tryParse(_priceController.text) ?? 0;
      final int stock = int.tryParse(_stockController.text) ?? 0;
      final String thumbnail = _imgUrlController.text.isNotEmpty
          ? _imgUrlController.text
          : 'https://via.placeholder.com/150';

      await _supabase.from('products').insert({
        'title': title,
        'category': category,
        'description': description, // 3. Masukkan ke database
        'price': price,
        'stock': stock,
        'thumbnail': thumbnail,
        'rating': 5.0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk Baru Berhasil Ditambahkan! 🎉')),
        );
        // 4. Bersihkan Form
        _nameController.clear();
        _categoryController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _stockController.clear();
        _imgUrlController.clear();

        _fetchProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal tambah produk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingProduct = false);
    }
  }

  // ==========================================
  // UI BUILDER
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Input Data",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: [
              Tab(icon: Icon(Icons.point_of_sale), text: "Transaksi"),
              Tab(icon: Icon(Icons.add_box), text: "Produk Baru"),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildTransactionTab(), _buildAddProductTab()],
        ),
      ),
    );
  }

  Widget _buildTransactionTab() {
    double currentTotal = 0;
    for (var item in _cartItems) currentTotal += item['subtotal'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "Pilih Produk",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Cari Barang...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    value: _selectedProduct,
                    hint: const Text("Pilih item..."),
                    items: _availableProducts.map((product) {
                      return DropdownMenuItem(
                        value: product,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                product['thumbnail'] ?? '',
                                width: 30,
                                height: 30,
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, s) => const Icon(
                                  Icons.image,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "${product['title']}",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Text(
                              " \$${product['price']} (Stok: ${product['stock']})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedProduct = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Jumlah',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _addToCart,
                        icon: const Icon(Icons.add),
                        label: const Text("Tambah"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Keranjang Belanja",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          _cartItems.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text("Belum ada barang")),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            item['thumbnail'] ?? '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (c, o, s) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        title: Text(
                          item['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "${item['quantity']}x @ \$${item['price']}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "\$${item['subtotal']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _cartItems.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "\$${currentTotal.toStringAsFixed(1)}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoadingTransaction || _cartItems.isEmpty
                  ? null
                  : _submitTransaction,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: _isLoadingTransaction
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "SIMPAN TRANSAKSI",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyProduct,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Masukkan Detail Produk",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                hintText: 'Contoh: Keyboard',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.coffee),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                hintText: 'Contoh: Accesories ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Kategori wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // 5. Input Field Deskripsi Baru
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Produk',
                hintText: 'Jelaskan detail produk...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Harga (\$)',
                      hintText: '150',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stok Awal',
                      hintText: '50',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imgUrlController,
              decoration: const InputDecoration(
                labelText: 'Link Gambar (URL)',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "*Kosongkan link gambar jika belum ada (akan pakai gambar default).",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoadingProduct ? null : _submitNewProduct,
                icon: const Icon(Icons.save),
                label: _isLoadingProduct
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SIMPAN PRODUK BARU",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
