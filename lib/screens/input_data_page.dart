import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InputDataPage extends StatefulWidget {
  const InputDataPage({super.key});

  @override
  State<InputDataPage> createState() => _InputDataPageState();
}

class _InputDataPageState extends State<InputDataPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableProducts = [];
  
  Map<String, dynamic>? _selectedProduct;
  final TextEditingController _qtyController = TextEditingController(text: '1');
  
  final List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // REVISI 1: Tambahkan 'thumbnail' di select query
  Future<void> _fetchProducts() async {
    try {
      final data = await _supabase
          .from('products')
          .select('id, title, price, stock, thumbnail') // <--- Ambil gambar
          .order('title');
      
      setState(() {
        _availableProducts = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  void _addToCart() {
    if (_selectedProduct == null || _qtyController.text.isEmpty) return;

    final int qty = int.tryParse(_qtyController.text) ?? 1;
    final double price = (_selectedProduct!['price'] ?? 0).toDouble();
    
    setState(() {
      _cartItems.add({
        'product_id': _selectedProduct!['id'],
        'title': _selectedProduct!['title'],
        'thumbnail': _selectedProduct!['thumbnail'], // <--- Simpan gambar ke keranjang
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
    setState(() => _isLoading = true);

    try {
      double total = 0;
      for (var item in _cartItems) total += item['subtotal'];

      final cartResponse = await _supabase.from('carts').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'total': total,
        'discounted_total': total,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final int newCartId = cartResponse['id'];

      for (var item in _cartItems) {
        await _supabase.from('cart_items').insert({
          'cart_id': newCartId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi Berhasil Disimpan! ✅')),
        );
        setState(() => _cartItems.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double currentTotal = 0;
    for (var item in _cartItems) currentTotal += item['subtotal'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("Pilih Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    
                    // REVISI 2: Dropdown dengan Gambar & Anti-Overflow
                    DropdownButtonFormField<Map<String, dynamic>>(
                      isExpanded: true, // <--- PENTING: Mencegah error garis kuning hitam
                      decoration: const InputDecoration(
                        labelText: 'Cari Barang...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      value: _selectedProduct,
                      items: _availableProducts.map((product) {
                        return DropdownMenuItem(
                          value: product,
                          child: Row(
                            children: [
                              // Tampilkan Gambar Kecil
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  product['thumbnail'] ?? '',
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => const Icon(Icons.image, size: 30, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Teks Nama Barang (Dibungkus Expanded agar tidak nabrak)
                              Expanded(
                                child: Text(
                                  "${product['title']}",
                                  overflow: TextOverflow.ellipsis, // Potong teks jika kepanjangan
                                  maxLines: 1,
                                ),
                              ),
                              Text(
                                " \$${product['price']}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedProduct = value),
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
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text("Keranjang Belanja", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                          // REVISI 3: Tampilkan Gambar di List Keranjang
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              item['thumbnail'] ?? '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => Container(width: 50, height: 50, color: Colors.grey[300], child: const Icon(Icons.image_not_supported)),
                            ),
                          ),
                          title: Text(item['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text("${item['quantity']}x @ \$${item['price']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("\$${item['subtotal']}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text("Total:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("\$${currentTotal.toStringAsFixed(1)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading || _cartItems.isEmpty ? null : _submitTransaction,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SIMPAN TRANSAKSI", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}