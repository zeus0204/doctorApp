import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:doctor_app/Pages/Patient/patient_details.dart';

class ScanQR extends StatefulWidget {
  const ScanQR({super.key});

  @override
  State<ScanQR> createState() => _ScanQRState();
}

class _ScanQRState extends State<ScanQR> {
  @override
  void initState() {
    super.initState();
    _scanQR();
  }

  void _scanQR() async {
    try {
      var result = await BarcodeScanner.scan(
        options: ScanOptions(
          strings: {
            'cancel': 'Cancel',
            'flash_on': 'Flash on',
            'flash_off': 'Flash off',
          },
          restrictFormat: [BarcodeFormat.qr],
          useCamera: -1,
          android: const AndroidOptions(
            aspectTolerance: 0.00,
            useAutoFocus: true,
          ),
        ),
      );

      if (result.rawContent.isNotEmpty) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetails(qrData: result.rawContent),
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error scanning QR code: $e');
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
