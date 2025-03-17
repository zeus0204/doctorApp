import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './scanqr.dart';

class ScanQRDashboardPage extends StatelessWidget {
  const ScanQRDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Scan your QR Code',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                Image.asset('assets/images/QR.png', width: 346, height: 372),
              ],
            ),
          ),
          Positioned(
            bottom: 16.0,
            left: 30.0,
            right: 30.0,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScanQR()),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(52, 221, 90, 1),
                minimumSize: const Size(70, 50),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scan QR code',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
