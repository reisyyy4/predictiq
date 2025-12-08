import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paket Berlangganan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Paket Free
          _buildSubscriptionCard(
            context: context,
            title: 'Free',
            price: 'Rp 0',
            period: '/bulan',
            features: [
              'Dashboard sederhana',
              'Upload data manual',
              'Prediksi 7 hari ke depan',
              'Export PDF (watermark)',
            ],
            color: Colors.grey,
            isActive: false,
          ),
          const SizedBox(height: 16),

          // Paket Premium (Active)
          _buildSubscriptionCard(
            context: context,
            title: 'Premium',
            price: 'Rp 99.000',
            period: '/bulan',
            features: [
              'Dashboard lengkap + AI Insight',
              'Auto-sync data',
              'Prediksi 30 hari ke depan',
              'Customer analytics',
              'Export unlimited',
              'Priority support',
            ],
            color: Colors.teal,
            isActive: true,
            qrData: 'PREDICTIQ_PREMIUM_USER123',
          ),
          const SizedBox(height: 16),

          // Paket Enterprise
          _buildSubscriptionCard(
            context: context,
            title: 'Enterprise',
            price: 'Rp 299.000',
            period: '/bulan',
            features: [
              'Semua fitur Premium',
              'Multi-store support',
              'API Integration',
              'Custom reporting',
              'Dedicated account manager',
              'Training & onboarding',
            ],
            color: Colors.purple,
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required BuildContext context,
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required Color color,
    required bool isActive,
    String? qrData,
  }) {
    return Card(
      elevation: isActive ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'AKTIF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          period,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isActive && qrData != null)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'QR Code Langganan',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: 250,
                                  backgroundColor: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Tutup'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 60,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isActive ? null : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? Colors.grey : color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(isActive ? 'Paket Aktif' : 'Pilih Paket'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}