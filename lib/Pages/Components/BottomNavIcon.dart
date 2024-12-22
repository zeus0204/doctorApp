import 'package:doctor_app/Pages/Home/Settings.dart';
import 'package:flutter/material.dart';
import '../Home/Dashboard.dart';
import '../Home/Calendar.dart';
import '../Home/ScanQR.dart';

class BottomNavIcons extends StatefulWidget {
  const BottomNavIcons({super.key});

  @override
  _BottomNavIconState createState() => _BottomNavIconState();
}

class _BottomNavIconState extends State<BottomNavIcons> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Dashboard(),
    Calendar(),
    ScanQR(),
    SettingsPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Show the selected page
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: [
          _buildBottomNavItem(Icons.dashboard, 0),
          _buildBottomNavItem(Icons.calendar_today, 1),
          _buildBottomNavItem(Icons.qr_code, 2),
          _buildBottomNavItem(Icons.settings, 3),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;

    return BottomNavigationBarItem(
      icon: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color.fromRGBO(33, 158, 80, 1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        padding: const EdgeInsets.all(8), // Padding around the icon
        child: Icon(
          icon,
          color: isSelected ? Colors.white : const Color.fromRGBO(33, 158, 80, 1), // Icon color
        ),
      ),
      label: '', // Empty label to match your requirement
    );
  }
}
