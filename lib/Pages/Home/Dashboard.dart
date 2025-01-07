import 'dart:async';

import 'package:doctor_app/Pages/Home/ScanQR.dart';
import 'package:doctor_app/data/db_helper.dart';
import 'package:doctor_app/data/session.dart';
import 'package:doctor_app/models/schedule.dart';
import 'package:doctor_app/widgets/schedule_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add this import

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>>? _medicalHistory = [];
  List<Map<String, dynamic>> _patients = []; // Add this for storing patient info
  String? _fullName;
  String? _email;
  bool _isLoading = false;
  late AnimationController _animationController;

  final Map<String, dynamic> user = {
    'name': '',
    'age': 29,
  };

  void initState() {  
    super.initState();  
    _loadDoctorData();
    _loadPatients();
    _loadUserData();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1, milliseconds: 500), // 1.5 seconds duration
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // Dispose the controller when not needed
    super.dispose();
  }

  void _onButtonPressed() {
    setState(() {
      _isLoading = true;
    });

    _animationController.repeat();
    Timer(Duration(seconds: 1, milliseconds: 500), () {
      setState(() {
        _isLoading = false;
      });
      _showSuccessMessage();
      _animationController.stop();
    });
  }
  
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sync completed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _loadDoctorData() async {
    try {
      final email = await SessionManager.getUserSession();
      if (email != null) {
        final doctorData = await DBHelper().getDoctorByEmail(email);
        if (doctorData != null && mounted) {
          setState(() {
            _email = email;
            _fullName = doctorData['fullName'];
            user['name'] = doctorData['fullName'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading doctor data: $e')),
        );
      }
    }
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await DBHelper().getAllpatients();
      if (mounted) {
        setState(() {
          _patients = patients;
          _medicalHistory = patients.map((patient) => {
            'email': patient['email'],
            'fullName': patient['fullName'],
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patients: $e')),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      String? email = await SessionManager.getUserSession();
      if (email != null) {
        Map<String, dynamic>? userData = await DBHelper().getDoctorByEmail(email);
        if (userData != null) {
          setState(() {
            user['name'] = userData['fullName'];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your profile is lacked, Please login again!')),
      );
    }
  }
  final List<Map<String, String>> doctors = [
    {'name': 'Patient 1', 'updated_history': 'Last Updated: 2h ago', 'avatar': 'assets/patient1.png'},
    {'name': 'Patient 2', 'updated_history': 'Last Updated: 3h ago', 'avatar': 'assets/patient2.png'},
    {'name': 'Patient 3', 'updated_history': 'Last Updated: 5h ago', 'avatar': 'assets/patient3.png'},
    {'name': 'Patient 4', 'updated_history': 'Last Updated: 7h ago', 'avatar': 'assets/patient4.png'},
  ];

  final Map<String, dynamic> schedule = {
    'doctor': 'Ariana Grande',
    'address': 'Migraines',
    'day_time': 'Tuesday, 5 March',
    'start_time': '11:00 AM',
    'end_time': '12:00 PM',
    'avatar': 'assets/dr_jon.png',
  };

  Stream<List<Schedule>> _getSchedulesStream() async* {
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
        final schedules = snapshot.docs.map((doc) {
          final data = doc.data();
          final String appointmentId = doc.id;
          
          final String patientName = data['userEmail'] != null 
              ? _patients.firstWhere(
                  (patient) => patient['email'] == data['userEmail'],
                  orElse: () => {'fullName': 'Unknown Patient'},
                )['fullName'] ?? 'Unknown Patient'
              : data['patientName'] ?? 'Unknown Patient';

          final DateTime? appointmentDate = data['day'] != null 
              ? DateTime.parse(data['day'].toString())
              : null;

          DateTime? startTime;
          if (appointmentDate != null && data['time'] != null) {
            final timeStr = data['time'].toString();
            final timeParts = timeStr.toUpperCase().split(' ');
            if (timeParts.length == 2) {
              final time = timeParts[0].split(':');
              int hour = int.parse(time[0]);
              int minute = int.parse(time[1]);
              
              if (timeParts[1] == 'PM' && hour < 12) {
                hour += 12;
              } else if (timeParts[1] == 'AM' && hour == 12) {
                hour = 0;
              }
              
              startTime = DateTime(
                appointmentDate.year,
                appointmentDate.month,
                appointmentDate.day,
                hour,
                minute,
              );
            }
          }

          final DateTime? endTime = startTime?.add(const Duration(hours: 1));
          
          if (appointmentDate == null || startTime == null || endTime == null) {
            return null;
          }

          return Schedule(
            doctor: patientName, // Using patient name instead of doctor name
            address: data['hospitalName'] ?? 'Consultation',
            dayTime: _formatDate(appointmentDate),
            startTime: _formatTime(startTime),
            endTime: _formatTime(endTime),
            avatar: 'assets/images/avatar.png',
            id: appointmentId,
          );
        })
        .where((schedule) => schedule != null)
        .cast<Schedule>()
        .toList();
        
        return schedules;
      });
    } catch (e) {
      yield [];
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('EEEE, d MMMM').format(date);
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('h:mm a').format(time);
  }



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
      body: Column(
        children: [
          // Top Section (green)
          Container(
            color: const Color.fromRGBO(33, 158, 80, 1),
            padding: EdgeInsets.all(size.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: size.width * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hey, ${user['name']}",
                            style: GoogleFonts.poppins(
                              fontSize: size.width * 0.04,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            "Today is a busy day",
                            style: GoogleFonts.poppins(
                              fontSize: size.width * 0.025,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(right: size.width * 0.05),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: SizedBox(
                        width: 32, // Fixed width
                        height: 32, // Fixed height
                        child: IconButton(
                          iconSize: 15, // Ensures icon size doesn't change
                          padding: EdgeInsets.zero, // Removes extra padding
                          icon: RotationTransition(
                            turns: _animationController,
                            child: const Icon(
                              Icons.sync,
                              color: Color.fromRGBO(33, 158, 80, 1),
                            ),
                          ),
                          onPressed: _isLoading ? null : _onButtonPressed,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.02),
                _buildScheduleCard(size),
              ],
            ),
          ),

          // Body Section (white with border radius)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.01),
                    Expanded(
                      child: _buildRecentRecords(size),
                    ),
                    SizedBox(height: size.height * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Size size) {
    return StreamBuilder<List<Schedule>>(
      stream: _getSchedulesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        final schedules = snapshot.data ?? [];
        if (schedules.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No upcoming appointments',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }
        
        return ScheduleCard(
          schedules: schedules,
          size: Size(size.width, size.height * 0.25),
          patients: _patients,
          appointmentId: schedules.isNotEmpty ? schedules[0].id : '',
        );
      },
    );
  }

  Widget _buildRecentRecords(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.1, vertical: size.height * 0.02),
      child: Container(
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(33, 158, 80, 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recent Records",
              style: GoogleFonts.poppins(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = doctors[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage(doctor['avatar']!),
                        ),
                        title: Text(
                          doctor['name']!,
                          style: GoogleFonts.poppins(fontSize: size.width * 0.035),
                        ),
                        subtitle: Text(
                          doctor['updated_history']!,
                          style: GoogleFonts.poppins(fontSize: size.width * 0.03),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {},
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.03),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ScanQR()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(227, 243, 208, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.qr_code,
                              color: Color.fromRGBO(33, 158, 80, 1),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Scan QR Code",
                              style: GoogleFonts.poppins(color: Color.fromRGBO(33, 158, 80, 1)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
