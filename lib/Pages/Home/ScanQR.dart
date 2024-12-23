import 'package:barcode_scan2/barcode_scan2.dart';
import '../Home/QR_code/ScanQR.dart'; // Adjust the path as needed
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanQR extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Scan your QR Code',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: 346.28,
              height: 372.28,
              child: Image.asset(
                'assets/images/QR.png', // Ensure the image path is correct
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  // Perform QR Code scanning
                  ScanResult codeScanner = await BarcodeScanner.scan();

                  // Navigate to Scanner page with scanned data
                  if (codeScanner.rawContent.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Scanner(scannedData: codeScanner.rawContent),
                      ),
                    );
                  }
                } catch (e) {
                  // Handle scanning errors (e.g., user cancels scanning)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Scanning failed: $e")),
                  );
                }
              },
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: Text(
                'Scan QR Code',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(52, 221, 90, 1),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
