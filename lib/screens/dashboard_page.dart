import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_services.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String _userName = "User";
  double _totalSales = 0;
  double _predictedSales = 0;
  List<FlSpot> _chartData = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Ambil Data User yang sedang Login
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Ambil nama dari tabel 'users' berdasarkan ID Auth
        final userData = await _supabase
            .from('users')
            .select('nama') // Pastikan kolomnya 'nama' sesuai database Anda
            .eq('id', user.id)
            .single();
        _userName = userData['nama'] ?? "Pelanggan";
      }

      // 2. Ambil Data Transaksi (Carts)
      final carts = await _apiService.getCarts();

      // 3. Hitung Total Penjualan
      double total = 0;
      List<FlSpot> tempSpots = [];

      // Mengambil 5 transaksi terakhir untuk grafik
      int index = 0;
      for (var cart in carts.take(5)) {
        double cartTotal = (cart['total'] ?? 0).toDouble();
        total += cartTotal;

        // Membuat titik grafik (X: index, Y: total belanja dibagi 1000 biar grafik rapi)
        tempSpots.add(FlSpot(index.toDouble(), cartTotal / 100));
        index++;
      }

      // 4. Hitung Prediksi Sederhana (Misal: +15% dari total sekarang)
      double prediction = total * 1.15;

      setState(() {
        _totalSales = total;
        _predictedSales = prediction;
        _userName = _userName;
        // Jika data kosong, kasih grafik dummy biar ga crash
        _chartData = tempSpots.isNotEmpty
            ? tempSpots
            : [const FlSpot(0, 0), const FlSpot(1, 1), const FlSpot(2, 0.5)];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading dashboard: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "PredictIQ Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sapaan User Dinamis
                  Text(
                    "Halo, $_userName 👋",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Berikut performa bisnis Anda hari ini.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 20),

                  // Kartu Metrik Dinamis
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          "Total Penjualan",
                          "\$${_totalSales.toStringAsFixed(0)}", // Format mata uang
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          "Prediksi Besok",
                          "\$${_predictedSales.toStringAsFixed(0)}",
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Tren Penjualan (5 Transaksi Terakhir)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Grafik Dinamis
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _chartData, // Data asli dari database
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Rekomendasi Cerdas (AI)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Bagian ini masih statis (karena butuh Logic AI yang lebih kompleks)
                  // Tapi bisa kita biarkan sebagai Mockup fitur masa depan
                  _buildInsightCard(
                    icon: Icons.trending_up,
                    color: Colors.green,
                    title: "Permintaan Produk Meningkat",
                    description:
                        "Data menunjukkan kenaikan penjualan $_userName minggu ini.",
                  ),
                  _buildInsightCard(
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                    title: "Cek Stok Barang",
                    description:
                        "Beberapa transaksi terakhir memiliki volume tinggi.",
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
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
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 8),
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

  Widget _buildInsightCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
