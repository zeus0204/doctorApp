import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_app/data/db_helper.dart';
import 'package:doctor_app/data/session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PatientDetails extends StatefulWidget {
  final String qrData;

  const PatientDetails({Key? key, required this.qrData}) : super(key: key);

  @override
  State<PatientDetails> createState() => _PatientDetailsState();
}

class _PatientDetailsState extends State<PatientDetails> {
  Map<String, dynamic> patientData = {};
  String? errorMessage;
  List<Map<String, dynamic>> _records = [];
  
  @override
  void initState() {
    super.initState();
    _decodeQRData();
  }

  Future<List<Map<String, dynamic>>> _fetchRecords(String? email) async {
    List<Map<String, dynamic>> records = [];
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('records')
          .where('patientEmail', isEqualTo: email)
          .get();

      records =
          querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      setState(() {
        _records = records;
      });
    } catch (e) {
      // Handle error
    }
    return records;
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    
    try {
      // Parse the datetime string
      final DateTime date = DateTime.parse(dateStr);
      
      // Format it into the desired format (e.g., "DD/MM/YYYY")
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      // Return a default value if parsing fails
      return 'Invalid Date';
    }
  }

  Future<void> _decodeQRData() async {
    try {
      String rawData = widget.qrData;
      print(rawData);
      // Split the data based on lines or entries
      List<String> entries = rawData.split('\n');

      Map<String, dynamic> result = {};

      for (String entry in entries) {
        if (entry.isNotEmpty) {
          // Remove curly braces
          entry = entry.substring(1, entry.length - 1);

          // Check for presence of ': ' and split accordingly
          int index = entry.indexOf(': ');
          if (index != -1) {
            String key = entry.substring(0, index).trim();
            String value = entry.substring(index + 2).trim();

            if ((key == 'medicalHistory') &&
                value.startsWith('[') &&
                value.endsWith(']')) {
              // Parse list using RegExp to split by '}, {'
              value = value.substring(1, value.length - 1); // Trim brackets
              List<Map<String, dynamic>> itemList = [];

              if (value.isNotEmpty) {
                RegExp regExp = RegExp(r'\}, \{');
                List<String> items = value.split(regExp);
                for (String item in items) {
                  item = item.replaceAll('{', '').replaceAll('}', '');
                  Map<String, dynamic> itemMap = {};
                  List<String> itemPairs = item.split(', ');
                  for (String itemPair in itemPairs) {
                    int itemIndex = itemPair.indexOf(': ');
                    if (itemIndex != -1) {
                      String itemKey = itemPair.substring(0, itemIndex).trim();
                      String itemValue =
                          itemPair.substring(itemIndex + 2).trim();

                      if (itemKey == 'time') {
                        // Assuming the timestamp format is like "Timestamp(seconds=xxx, nanoseconds=yyy)"
                        final secondsRegEx = RegExp(r'seconds=(\d+)');
                        final match = secondsRegEx.firstMatch(itemValue);
                        if (match != null) {
                          int seconds = int.parse(match.group(1)!);
                          DateTime date =
                              DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                          itemValue = DateFormat('dd/MM/yyyy').format(date);
                        }
                      }

                      itemMap[itemKey] = itemValue;
                    }
                  }
                  itemList.add(itemMap);
                }
              }
              result[key] = itemList;
            } else {
              result[key] = value;
            }
          }
        }
      }

      // Fetch records after decoding QR data
      List<Map<String, dynamic>> records =
          await _fetchRecords(result['email']);

      // Set state after all async work is complete
      if (mounted) {
        setState(() {
          patientData = result;
          _records = records;
        });
      }
    } catch (e) {
      print('Error decoding QR data: $e');
      if (mounted) {
        setState(() {
          patientData = {
            'error': 'Failed to decode patient data',
            'message': e.toString(),
          };
          errorMessage = 'Error loading patient data: ${e.toString()}';
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showError(errorMessage!);
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
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
                      patientData['name'] ?? 'N/A',
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
                        _buildInfoItem('Birthday:', _formatDate(patientData['birthday'] ?? '')),
                        _buildInfoItem('Phone:', patientData['phoneNumber'] ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildMedicalHistorySection(
                'Medical History',
                (patientData['medicalHistory'] as List<Map<String, dynamic>>?) ?? [],
              ),
              const SizedBox(height: 24),
              _buildMedicalRecordSection(
                    'Medical Records',
                    _records,
                  ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showAddMedicalRecordsModal(context);
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
  void _showAddMedicalRecordsModal(BuildContext context, {Map<String, dynamic>? record}) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController subtitleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    if (record != null) {
      titleController.text = record['title'] ?? '';
      subtitleController.text = record['subtitle'] ?? '';
      descriptionController.text = record['description'] ?? '';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(record == null ? "Add Medical Record" : "Edit Medical Record", style: const TextStyle(color: Color.fromRGBO(33, 158, 80, 1), fontSize: 20),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(  
                  labelText: 'Title',  
                  labelStyle: const TextStyle(color: Color.fromRGBO(10, 62, 29, 1)),  
                  border: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1), width: 2.0),  
                  ),  
                  focusedBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                  enabledBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                            fillColor: Colors.white,  
                  filled: true,  
                ),
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subtitleController,
                decoration: InputDecoration(  
                  labelText: 'Subtitle',  
                  labelStyle: const TextStyle(color: Color.fromRGBO(10, 62, 29, 1)),  
                  border: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1), width: 2.0),  
                  ),  
                  focusedBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                  enabledBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                            fillColor: Colors.white,  
                  filled: true,  
                ),
                style: GoogleFonts.poppins(color: Colors.black),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: descriptionController,
                decoration: InputDecoration(  
                  labelText: 'Description',  
                  labelStyle: const TextStyle(color: Color.fromRGBO(10, 62, 29, 1)),  
                  border: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1), width: 2.0),  
                  ),  
                  focusedBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                  enabledBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                            fillColor: Colors.white,  
                  filled: true,  
                ),
                style: GoogleFonts.poppins(color: Colors.black),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),),
            ),
            TextButton(
              onPressed: () async {
                final String? doctorEmail = await SessionManager.getUserSession();
                final String patientEmail = patientData['email'] ?? '';
                final String title = titleController.text.trim();
                final String subtitle = subtitleController.text.trim();
                final String description = descriptionController.text.trim();
                if (title != '' && subtitle != '' && description != '') {
                  saveMedicalRecord(doctorEmail, patientEmail, title, subtitle, description);
                }
                else {
                  _showError('Please input correct information!');
                }
              },
              child: const Text("Save", style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveMedicalRecord (String? doctorEmail, String patientEmail, String title, String subtitle, String description) async {
    try {
      await FirebaseFirestore.instance.collection('records').add({
        'doctorEmail': doctorEmail,
        'patientEmail': patientEmail,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'time': Timestamp.now(),
      });
      _showError('Record saved successfully.');
      Navigator.pop(context); 
      setState(() {
        _fetchRecords(patientEmail);
      });
    } catch (e) {
      print('Error adding document: $e');
      _showError('Failed to save record: ${e.toString()}');
    }
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

  Widget _buildMedicalHistorySection(String title, List<Map<String, dynamic>> items) {
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
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['title'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(10, 62, 29, 1),
                          ),
                        ),
                      ]
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['description'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<String> getDoctornameByEmail(String doctorEmail) async {
    Map<String, dynamic>? userData = await DBHelper().getDoctorByEmail(doctorEmail);
    return userData?['fullName'] ?? 'Unknown Doctor';
  }

  Widget _buildMedicalRecordSection(String title, List<Map<String, dynamic>> items) {
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
        FutureBuilder<String?>(
          future: SessionManager.getUserSession(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // Show loading indicator while waiting
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Text('Error: ${snapshot.error ?? "No user session available"}');
            } else {
              final sessionEmail = snapshot.data;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  String formattedDate = 'N/A';
                  if (item['time'] is Timestamp) {
                    final timestamp = item['time'] as Timestamp;
                    DateTime date = timestamp.toDate();
                    formattedDate = DateFormat('dd/MM/yyyy').format(date);
                  }
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
                      subtitle: FutureBuilder<String>(
                        future: getDoctornameByEmail(item['doctorEmail']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['subtitle'] ?? 'N/A'),
                                Text(item['description'] ?? 'N/A'),
                                Text(snapshot.data ?? 'Unknown Doctor'),
                                Text(formattedDate),
                              ],
                            );
                          }
                        },
                      ),
                      trailing: (sessionEmail == item['doctorEmail'])
                          ? TextButton(
                              onPressed: () {
                                _showAddMedicalRecordsModal(context, record: item);
                              },
                              child: const Text(
                                'View',
                                style: TextStyle(
                                  color: Color.fromRGBO(33, 158, 80, 1),
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }
}
