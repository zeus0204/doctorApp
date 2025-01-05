import 'package:flutter/material.dart';
import 'dart:convert';

class PatientDetails extends StatefulWidget {
  final String qrData;

  const PatientDetails({Key? key, required this.qrData}) : super(key: key);

  @override
  State<PatientDetails> createState() => _PatientDetailsState();
}

class _PatientDetailsState extends State<PatientDetails> {
  Map<String, dynamic> patientData = {};
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _decodeQRData();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _decodeQRData() {
    try {
      String decodedString = Uri.decodeFull(widget.qrData);
      // Remove the curly braces from the string
      decodedString = decodedString.substring(1, decodedString.length - 1);
      
      // Split the string into key-value pairs
      List<String> pairs = decodedString.split(', ');
      Map<String, dynamic> result = {};
      
      for (String pair in pairs) {
        List<String> keyValue = pair.split(': ');
        String key = keyValue[0].replaceAll("'", "");
        String value = keyValue[1].replaceAll("'", "");
        
        if (key == 'medicalHistory') {
          // Parse the medical history list
          value = value.substring(1, value.length - 1); // Remove brackets
          List<Map<String, dynamic>> historyList = [];
          if (value.isNotEmpty) {
            List<String> items = value.split('}, {');
            for (String item in items) {
              item = item.replaceAll('{', '').replaceAll('}', '');
              Map<String, dynamic> historyItem = {};
              List<String> itemPairs = item.split(', ');
              for (String itemPair in itemPairs) {
                List<String> itemKeyValue = itemPair.split(': ');
                historyItem[itemKeyValue[0].replaceAll("'", "")] = 
                    itemKeyValue[1].replaceAll("'", "");
              }
              historyList.add(historyItem);
            }
          }
          result[key] = historyList;
        } else {
          result[key] = value;
        }
      }
      
      setState(() {
        patientData = result;
      });
    } catch (e) {
      print('Error decoding QR data: $e');
      setState(() {
        patientData = {
          'error': 'Failed to decode patient data',
          'message': e.toString()
        };
        errorMessage = 'Error loading patient data: ${e.toString()}';
      });
      
      // Schedule the error message to be shown after the build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showError(errorMessage!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Patient Details',
          style: TextStyle(
            color: Color.fromRGBO(33, 158, 80, 1),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(226, 248, 227, 1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(33, 158, 80, 1)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(226, 248, 227, 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Color.fromRGBO(33, 158, 80, 1),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(33, 158, 80, 1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '15 years experience',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(33, 158, 80, 1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Focus: The impact of hormonal imbalances on dermatological conditions, specializing in acne, lipidism, and other skin disorders.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      patientData['fullName'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem('Contact:', patientData['contact'] ?? 'N/A'),
                        _buildInfoItem('Age:', _calculateAge(patientData['dateOfBirth'] ?? '')),
                        _buildInfoItem('Phone:', patientData['phoneNumber'] ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Medical Record',
                (patientData['medicalHistory'] as List<Map<String, dynamic>>?) ?? [],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Prescriptions',
                (patientData['medicalHistory'] as List<Map<String, dynamic>>?) ?? [],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle add record
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add Record',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(33, 158, 80, 1),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  item['title'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['subtitle'] ?? 'N/A'),
                    Text(item['description'] ?? 'N/A'),
                  ],
                ),
                trailing: TextButton(
                  onPressed: () {
                    // Handle view action
                  },
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Color.fromRGBO(33, 158, 80, 1),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _calculateAge(String dateOfBirth) {
    if (dateOfBirth.isEmpty) return 'N/A';
    try {
      final dob = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return '$age';
    } catch (e) {
      return 'N/A';
    }
  }
}
