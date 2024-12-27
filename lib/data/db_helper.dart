import 'package:cloud_firestore/cloud_firestore.dart';

// Singleton class for DBHelper using Firestore
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  DBHelper._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Insert user data
  Future<void> insertDoctor(Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('doctors').add(userData);
    } catch (e) {
      throw Exception('An error occurred while inserting the user: $e');
    }
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<bool> emailExists(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if email exists: $e');
    }
  }

  Future<String?> getUserIdByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user ID by email: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by email: $e');
    }
  }

  Future<Map<String, dynamic>?> getDoctorInfoByUserId(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('doctor_profiles').doc(userId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      throw Exception('Failed to get doctor info by user ID: $e');
    }
  }

  Future<void> updateDoctors({
    required String email,
    String? fullName,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('doctors')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          await doc.reference.update({
            if (fullName != null) 'fullName': fullName,
          });
        }
      } else {
        throw Exception('No doctor found with email $email');
      }
    } catch (e) {
      throw Exception('Failed to update doctor: $e');
    }
  }

  Future<void> updateDoctorInfo({
    required String email,
    String? address,
    String? contact,
    String? demography,
    String? specialization,
    String? practingTenure,
    DateTime? birthday,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('doctors')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          await doc.reference.set({
            'doctors_info': {
              if (address != null) 'address': address,
              if (contact != null) 'contact': contact,
              if (demography != null) 'demography': demography,
              if (specialization != null) 'specialization': specialization,
              if (practingTenure != null) 'practingTenure': practingTenure,
              if (birthday != null) 'birthday': birthday.toIso8601String(),
            }
          }, SetOptions(merge: true));
        }
      } else {
        throw Exception('No doctor info found with email $email');
      }
    } catch (e) {
      throw Exception('Failed to upsert Doctors info: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByDoctorId(String doctorId) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('appointments').where('doctor_id', isEqualTo: doctorId).get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
    } catch (e) {
      throw Exception('Failed to get appointments by doctor ID: $e');
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAppointmentsById(String id) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('appointments').where(FieldPath.documentId, isEqualTo: id).get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
    } catch (e) {
      throw Exception('Failed to get appointments by ID: $e');
    }
  }

  Future<void> insertAppointment(Map<String, dynamic> appointmentData) async {
    try {
      await _firestore.collection('appointments').add(appointmentData);
    } catch (e) {
      throw Exception('Failed to insert appointment: $e');
    }
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('appointments').doc(id).update(updatedData);
    } catch (e) {
      throw Exception('Failed to update appointment: $e');
    }
  }
}
