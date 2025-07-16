import 'package:flutter/material.dart';

class CopyrightWidget extends StatelessWidget {
  const CopyrightWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0), // Memberikan jarak di sekitar teks
      child: Column(
        mainAxisSize: MainAxisSize.min, // Mengambil ruang seminimal mungkin
        children: [
          Text(
            '© 2024 Nama Perusahaan Anda. All rights reserved.', // Ganti dengan nama perusahaan Anda
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4), // Jarak antar baris teks
          Text(
            'Dibuat dengan ❤️ di Jakarta, Indonesia', // Pesan tambahan
            style: TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
