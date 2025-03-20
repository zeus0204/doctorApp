import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/session.dart';

class SetAvailableTime extends StatefulWidget {
  const SetAvailableTime({Key? key}) : super(key: key);

  @override
  _SetAvailableTimeState createState() => _SetAvailableTimeState();
}

class _SetAvailableTimeState extends State<SetAvailableTime> {
  List availableTimes = [];
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isSaving = false;
  bool _isLoading = true;

  Map<String, Set> selectedTimes = {
    'Mon': {},
    'Tue': {},
    'Wed': {},
    'Thu': {},
    'Fri': {},
    'Sat': {},
    'Sun': {},
  };

  @override
  void initState() {
    super.initState();
    _generateTimeSlots();
    _loadExistingAvailability();
  }

  void _generateTimeSlots() {
    TimeOfDay currentTime = startTime;
    availableTimes.clear();
    while (currentTime.hour < endTime.hour ||
        (currentTime.hour == endTime.hour &&
            currentTime.minute < endTime.minute)) {
      String timeLabel = _formatTime(currentTime);
      availableTimes.add(timeLabel);

      // Move to next time slot
      currentTime =
          (currentTime.minute == 0)
              ? TimeOfDay(hour: currentTime.hour, minute: 30)
              : TimeOfDay(hour: currentTime.hour + 1, minute: 0);
    }
  }

  Future<void> _loadExistingAvailability() async {
    try {
      setState(() {
        _isLoading = true;
      });

      String? currentEmail = await SessionManager.getUserSession();

      if (currentEmail == null) {
        _showErrorDialog('No user session found');
        return;
      }

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('doctors')
              .where('email', isEqualTo: currentEmail)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doctorDoc = querySnapshot.docs.first.data();

        if (doctorDoc.containsKey('availability')) {
          Map<String, dynamic> availability = doctorDoc['availability'];

          availability.forEach((day, times) {
            selectedTimes[day] = times.map((time) => time.toString()).toSet();
          });
        }
      }
    } catch (e) {
      _showErrorDialog('Error loading availability: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final int hour =
        time.hour > 12
            ? time.hour - 12
            : time.hour == 0
            ? 12
            : time.hour;
    final String period = time.hour >= 12 ? 'pm' : 'am';
    return '${hour.toString()}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  Future _showMultiSelect(BuildContext context, String day) async {
    List selected = selectedTimes[day]!.toList();
    final List? results = await showDialog<List>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Select Time Slots for $day',
            style: GoogleFonts.poppins(
              color: const Color.fromRGBO(33, 158, 80, 1),
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children:
                  availableTimes.map((timeSlot) {
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return CheckboxListTile(
                          title: Text(timeSlot, style: GoogleFonts.poppins()),
                          value: selected.contains(timeSlot),
                          activeColor: const Color.fromRGBO(33, 158, 80, 1),
                          onChanged: (bool? value) {
                            if (value == true) {
                              selected.add(timeSlot);
                            } else {
                              selected.remove(timeSlot);
                            }
                            setState(() {});
                          },
                        );
                      },
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Done',
                style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),
              ),
              onPressed: () {
                Navigator.of(context).pop(selected);
              },
            ),
          ],
        );
      },
    );
    if (results != null) {
      setState(() {
        selectedTimes[day] = results.toSet();
      });
    }
  }

  Future _saveSelections() async {
    setState(() {
      _isSaving = true;
    });
    try {
      String? currentEmail = await SessionManager.getUserSession();

      if (currentEmail == null) {
        _showErrorDialog('No user session found');
        return;
      }

      Map<String, dynamic> availabilityData = {};
      selectedTimes.forEach((day, times) {
        availabilityData[day] = times.toList();
      });

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('doctors')
              .where('email', isEqualTo: currentEmail)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;

        await docRef.update({'availability': availabilityData});

        _showSuccessDialog('Availability saved successfully');
      } else {
        _showErrorDialog('Doctor not found');
      }
    } catch (e) {
      _showErrorDialog('Error saving availability: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Success', style: GoogleFonts.poppins()),
          content: Text(message, style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              child: Text('OK', style: GoogleFonts.poppins()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Error', style: GoogleFonts.poppins()),
          content: Text(message, style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              child: Text('OK', style: GoogleFonts.poppins()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Select Available Time',
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
            icon: const Icon(
              Icons.arrow_back,
              color: Color.fromRGBO(33, 158, 80, 1),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Color.fromRGBO(33, 158, 80, 1),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children:
                            selectedTimes.keys.map((day) {
                              return ListTile(
                                title: Text(
                                  day,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromRGBO(10, 62, 29, 1),
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  onPressed:
                                      () => _showMultiSelect(context, day),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromRGBO(
                                      33,
                                      158,
                                      80,
                                      1,
                                    ),
                                  ),
                                  child: const Text(
                                    'Select Time Slots',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSelections,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _isSaving
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Save Selections',
                                  style: TextStyle(color: Colors.white),
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
