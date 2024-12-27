import 'package:flutter/material.dart';

class PatientsDetails extends StatefulWidget {
  final String scannedData;

  const PatientsDetails({Key? key, required this.scannedData}) : super(key: key);

  @override
  _PatientsDetailsState createState() => _PatientsDetailsState();
}

class _PatientsDetailsState extends State<PatientsDetails> {
  late String scannedData;

  @override
  void initState() {
    super.initState();
    // Initialize scannedData from the widget's property
    scannedData = widget.scannedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'QR Code Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Scanned Data",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SelectableText(
            scannedData,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w400,
            ),
            cursorColor: Colors.red,
            showCursor: true,
          ),
        ],
      ),
    );
  }
}
