import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/data/db_helper.dart';
import 'package:doctor_app/data/session.dart';
import 'add_appointment.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  List<Map<String, dynamic>> patients = [];

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      List<Map<String, dynamic>> getpatients = await DBHelper().getAllpatients();
      setState(() {
        patients = getpatients;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching patients: $e')),
      );
    }
  }

  Stream<List<Map<String, dynamic>>> _getAppointmentsStream() async* {
    try {
      String? doctorEmail = await SessionManager.getUserSession();
      if (doctorEmail == null) {
        throw Exception('No user session found. Please log in again.');
      }

      yield* FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorEmail', isEqualTo: doctorEmail)
          .snapshots()
          .map((snapshot) {
        final appointments = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            ...data,
            'id': doc.id,
          };
        }).toList();
        return appointments;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching appointments: $e')),
      );
      yield [];
    }
  }

  String getPatientName(String? userEmail) {
    if (userEmail == null) return 'Unknown Patient';
    final patient = patients.firstWhere(
      (pat) => pat['email'] == userEmail,
      orElse: () => {'fullName': 'Unknown Patient'},
    );
    return patient['fullName'] ?? 'Unknown Patient';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Appointments',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(33, 158, 80, 1),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search (0 Appoint..)',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.green),
                      onPressed: () {
                        // Filter functionality can be added here
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Flexible(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getAppointmentsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Set loading indicator color to white
                    ),
                  );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final appointments = snapshot.data ?? [];
                  
                  if (appointments.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No appointments yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: appointments.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      final date = DateTime.tryParse(appointment['day'] ?? '');
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            getPatientName(appointment['userEmail']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Day: ${DateFormat('dd/MM/yyyy').format(date ?? DateTime.now())}\n'
                            'Time: ${appointment['time']}\n'
                            'Hospital: ${appointment['hospitalName']}\n'
                            'Status: ${appointment['status']}\n',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddAppointment(
                                      id: appointment['id'],
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('appointments')
                                        .doc(appointment['id'])
                                        .delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Appointment deleted successfully'),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error deleting appointment: $e')),
                                    );
                                  } finally {
                                    
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAppointment()),
          ).then((result) {
            if (result == true) {
              _fetchPatients();
            }
          });
        },
        backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}
