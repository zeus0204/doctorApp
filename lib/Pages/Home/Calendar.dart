import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';  

// Sample data for patients
final List<Map<String, String>> patients = [
  {'name': 'Patient 1', 'updated_history': 'Last Updated: 2h ago', 'avatar': 'assets/patient1.png'},
  {'name': 'Patient 2', 'updated_history': 'Last Updated: 3h ago', 'avatar': 'assets/patient2.png'},
  {'name': 'Patient 3', 'updated_history': 'Last Updated: 5h ago', 'avatar': 'assets/patient3.png'},
  {'name': 'Patient 4', 'updated_history': 'Last Updated: 6h ago', 'avatar': 'assets/patient4.png'},
  {'name': 'Patient 5', 'updated_history': 'Last Updated: 7h ago', 'avatar': 'assets/patient5.png'},
  {'name': 'Patient 6', 'updated_history': 'Last Updated: 7h ago', 'avatar': 'assets/patient6.png'},
  {'name': 'Patient 7', 'updated_history': 'Last Updated: 7h ago', 'avatar': 'assets/patient7.png'},
  {'name': 'Patient 8', 'updated_history': 'Last Updated: 7h ago', 'avatar': 'assets/patient8.png'},
  {'name': 'Patient 9', 'updated_history': 'Last Updated: 7h ago', 'avatar': 'assets/patient9.png'},
  {'name': 'Patient 10', 'updated_history': 'Last Updated: 7h ago', 'avatar': 'assets/patient10.png'},
];

class Calendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
      body: Column(
        children: [
          // Custom header
          Container(
            padding: const EdgeInsets.only(right: 30, left: 30, top: 30),
            child: Column(
              children: [
                Center(
                  child: Text(
                    'Patient Records',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Handle search button tap
                      },
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Handle add button tap
                      },
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 30, left: 30, bottom: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0)
                ),
              ),
              child: ListView.builder(
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(patients[index]['avatar']!),
                      radius: 24,
                    ),
                    title: Text(
                      patients[index]['name']!,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(10, 62, 29, 1),
                      ),
                    ),
                    subtitle: Text(
                      patients[index]['updated_history']!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                      color: Color.fromRGBO(10, 62, 29, 1),
                    ),
                    onTap: () {
                      // Handle tap
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
