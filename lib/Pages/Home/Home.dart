import 'ScanQR.dart';
import 'package:flutter/material.dart';
import '../Home/Appointment/Calendar.dart';
import 'Dashboard.dart';
import 'Settings.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const Dashboard(),
    const Calendar(),
    ScanQR(),
    SettingsPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.dashboard, _currentIndex == 0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.calendar_month, _currentIndex == 1),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.qr_code, _currentIndex == 2),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.settings, _currentIndex == 3),
            label: '',
          ),
        ],
        // Disable the animation when switching tabs
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildIcon(IconData icon, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color.fromRGBO(33, 158, 80, 1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8), // Rounded corners
      ),
      padding: const EdgeInsets.all(10), // Adjust padding for better appearance
      child: Icon(
        icon,
        color: isSelected ? Colors.white : const Color.fromRGBO(33, 158, 80, 1),
      ),
    );
  }
}
