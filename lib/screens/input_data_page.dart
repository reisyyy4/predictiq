import 'package:flutter/material.dart';

class InputDataPage extends StatelessWidget {
  const InputDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Data")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder Image (Ganti URL jika perlu)
            const Icon(Icons.cloud_upload_outlined,
                size: 100, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              "Mulai Analisis Bisnis Anda",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Unggah file transaksi (Excel/CSV) untuk mendapatkan prediksi instan.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Membuka File Manager...")),
                  );
                },
                icon: const Icon(Icons.upload_file),
                label: const Text("Pilih File Excel / CSV"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text("Riwayat Upload",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text("Data_Penjualan_Nov.xlsx"),
                    subtitle: Text("Sukses dianalisis • 2 Jam lalu"),
                  ),
                  ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text("Data_Stok_Barang.csv"),
                    subtitle: Text("Sukses dianalisis • Kemarin"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}