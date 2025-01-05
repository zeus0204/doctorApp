import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color.fromRGBO(33, 158, 80, 1);
  static const Color grey = Colors.grey;
  static const Color white = Colors.white;
}

class AppStrings {
  static const String reschedule = "Reschedule";
  static const String joinSession = "Join Session";
}

class AppStyles {
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
