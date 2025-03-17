import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_app/data/session.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:doctor_app/data/db_helper.dart';

class AddAppointment extends StatefulWidget {
  final String? id;
  final List<Map<String, dynamic>>? patients;

  const AddAppointment({Key? key, this.id, this.patients}) : super(key: key);

  @override
  State<AddAppointment> createState() => _AddAppointmentState();
}

class _AddAppointmentState extends State<AddAppointment> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String? _selectedPatientEmail;
  String? _selectedHospitalName;
  bool _isInitialized = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _patients = [];
  Set<String> _bookedTimeSlots = {};
  bool _allSlotsBooked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load patients if not provided
      if (widget.patients == null) {
        final dbHelper = DBHelper();
        _patients = await dbHelper.getAllpatients();
      } else {
        _patients = widget.patients!;
      }

      // Load appointment data if editing
      if (widget.id != null) {
        final appointment =
            await FirebaseFirestore.instance
                .collection('appointments')
                .doc(widget.id)
                .get();

        if (!mounted) return;

        if (appointment.exists) {
          final data = appointment.data()!;
          setState(() {
            _selectedDate = DateTime.parse(data['day']);
            _selectedPatientEmail = data['userEmail'];
            _selectedHospitalName = data['hospitalName'];
            _selectedTime = data['time'];
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTimeForIndex(int index) {
    final hour = 6 + index ~/ 2;
    final minute = (index % 2) * 30;
    var period = 'AM';
    if (hour >= 12) {
      period = 'PM';
    }
    return '${hour > 12 ? hour - 12 : hour}:${minute == 0 ? '00' : '30'} $period';
  }

  Future<void> _showHospitalSelectionModal() async {
    try {
      final dbHelper = DBHelper();
      final doctorEmail = await SessionManager.getUserSession();
      if (doctorEmail == null) throw Exception('No doctor session found');

      final availableHospitals = await dbHelper.getHospitalsByEmail(
        doctorEmail,
      );

      if (!mounted) return;

      if (availableHospitals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hospitals available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String? selectedHospitalName;

      await showDialog(
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder: (context, setModalState) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text(
                    'Select Hospital',
                    style: TextStyle(
                      color: Color.fromRGBO(33, 158, 80, 1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        availableHospitals.map((hosp) {
                          return ListTile(
                            title: Text(
                              hosp['name']!,
                              style: const TextStyle(color: Colors.black),
                            ),
                            leading: Radio<String>(
                              value: hosp['name']!,
                              groupValue: selectedHospitalName,
                              activeColor: const Color.fromRGBO(33, 158, 80, 1),
                              onChanged: (String? value) {
                                setModalState(() {
                                  selectedHospitalName = value;
                                });
                              },
                            ),
                          );
                        }).toList(),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          selectedHospitalName == null
                              ? null
                              : () {
                                setState(() {
                                  _selectedHospitalName = selectedHospitalName;
                                });
                                Navigator.pop(context);
                              },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color.fromRGBO(33, 158, 80, 1),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color.fromRGBO(33, 158, 80, 1),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching hospitals: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkBookedAppointments() async {
    if (_selectedPatientEmail == null || !mounted) return;

    setState(() {
      _isLoading = true;
      _bookedTimeSlots.clear();
      _allSlotsBooked = false;
    });

    try {
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('appointments')
              .where('userEmail', isEqualTo: _selectedPatientEmail)
              .where(
                'day',
                isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
              )
              .where('day', isLessThan: endOfDay.toIso8601String())
              .get();

      if (!mounted) return;

      setState(() {
        for (var doc in querySnapshot.docs) {
          _bookedTimeSlots.add(doc['time']);
        }
        // Check if all slots are booked (24 time slots in total)
        _allSlotsBooked = _bookedTimeSlots.length >= 24;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking booked appointments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.id == null ? 'Add Appointment' : 'Edit Appointment',
          style: const TextStyle(
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
            icon: const Icon(
              Icons.arrow_back,
              color: Color.fromRGBO(33, 158, 80, 1),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromRGBO(33, 158, 80, 1),
                  ),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TableCalendar(
                        focusedDay: _selectedDate,
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2030),
                        selectedDayPredicate:
                            (day) => isSameDay(_selectedDate, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDate = selectedDay;
                            _selectedTime =
                                null; // Reset selected time when date changes
                          });
                          if (_selectedPatientEmail != null) {
                            _checkBookedAppointments();
                          }
                        },
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(
                            color: Color.fromRGBO(33, 158, 80, 1),
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromRGBO(33, 158, 80, 1),
                              width: 2,
                            ),
                          ),
                          todayTextStyle: const TextStyle(color: Colors.black),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          headerPadding: EdgeInsets.all(8),
                          titleTextStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(33, 158, 80, 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Available Times',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 24,
                        itemBuilder: (context, index) {
                          final time = _getTimeForIndex(index);
                          return _buildTimeButton(time);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Select Patient',
                          style: TextStyle(
                            color: Color.fromRGBO(33, 158, 80, 1),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromRGBO(33, 158, 80, 1),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            hint: const Text(
                              'Select a Patient',
                              style: TextStyle(
                                color: Color.fromRGBO(33, 158, 80, 1),
                              ),
                            ),
                            value: _selectedPatientEmail,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color.fromRGBO(33, 158, 80, 1),
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedPatientEmail = newValue;
                                _selectedTime =
                                    null; // Reset selected time when patient changes
                                if (_selectedPatientEmail != null) {
                                  _showHospitalSelectionModal();
                                  _checkBookedAppointments();
                                }
                              });
                            },
                            items:
                                _patients.map<DropdownMenuItem<String>>((
                                  patient,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: patient['email'],
                                    child: Text(
                                      patient['fullName']!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed:
                          _allSlotsBooked ||
                                  _selectedTime == null ||
                                  _selectedPatientEmail == null ||
                                  _selectedHospitalName == null
                              ? null
                              : _scheduleAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 100,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        widget.id == null ? 'Schedule' : 'Update',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  Widget _buildTimeButton(String time) {
    final isSelected = _selectedTime == time;
    final isBooked = _bookedTimeSlots.contains(time);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed:
            isBooked
                ? null
                : () {
                  setState(() {
                    _selectedTime = time;
                  });
                },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isBooked
                  ? Colors.grey
                  : isSelected
                  ? const Color.fromRGBO(33, 158, 80, 1)
                  : Colors.grey[200],
          foregroundColor:
              isBooked
                  ? Colors.white
                  : isSelected
                  ? Colors.white
                  : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(time),
            if (isBooked) const Icon(Icons.block, size: 16),
          ],
        ),
      ),
    );
  }

  void _scheduleAppointment() async {
    if (_selectedTime == null ||
        _selectedPatientEmail == null ||
        _selectedHospitalName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient, hospital, and time!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.fromRGBO(33, 158, 80, 1),
            ),
          ),
        );
      },
    );

    try {
      final doctorEmail = await SessionManager.getUserSession();
      if (doctorEmail == null) {
        throw Exception('No doctor session found. Please log in again.');
      }

      final appointmentData = {
        'userEmail': _selectedPatientEmail,
        'doctorEmail': doctorEmail,
        'hospitalName': _selectedHospitalName!,
        'day': _selectedDate.toIso8601String(),
        'time': _selectedTime,
        'status': 'scheduled',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.id == null
                ? 'Appointment scheduled successfully'
                : 'Appointment updated successfully',
          ),
          backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
        ),
      );

      if (widget.id == null) {
        await FirebaseFirestore.instance
            .collection('appointments')
            .add(appointmentData);
      } else {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.id)
            .update(appointmentData);
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Ensure loading dialog is closed
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error ${widget.id == null ? 'scheduling' : 'updating'} appointment: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );

      // Navigate back to the calendar page with a `false` result if needed
      Navigator.pop(context, false);
    }
  }
}
