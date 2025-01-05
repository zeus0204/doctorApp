import 'package:cloud_firestore/cloud_firestore.dart';

// Singleton class for DBHelper using Firestore
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  DBHelper._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Insert user data
  Future<void> insertDoctor(Map<String, dynamic> doctorData) async {
    try {
      var result = await _firestore.collection('doctors').where('email', isEqualTo: doctorData['email']).get();
      if (result.docs.isNotEmpty) {
        throw Exception('Email already exists. Please use a different email');
      }
      await _firestore.collection('doctors').add(doctorData);
    } catch (e) {
      throw Exception('An error occurred while inserting the doctor');
    }
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('doctors').get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
    } catch (e) {
      throw Exception('Failed to fetch doctors: $e');
    }
  }

  Future<bool> emailExists(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('patients').where('email', isEqualTo: email).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if email exists: $e');
    }
  }

  Future<String?> getUserIdByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('doctors').where('email', isEqualTo: email).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user ID by email: $e');
    }
  }

  Future<Map<String, dynamic>?> getDoctorByEmail(String email) async {
    final querySnapshot = await _firestore
        .collection('doctors')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDoctorInfoByEmail(String email) async {
    try {
      // Query the 'patients' collection for a document where the 'email' field matches the given email
      final querySnapshot = await _firestore
          .collection('doctors')
          .where('email', isEqualTo: email)
          .get();

      // Check if any documents were found
      if (querySnapshot.docs.isNotEmpty) {
        // Assuming each email is unique, take the first match
        final doc = querySnapshot.docs.first;
        // Retrieve the 'patients_info' field from the document
        return doc.data()['doctors_info'] as Map<String, dynamic>?;
      } else {
        // Return null if no document was found
        return null;
      }
    } catch (e) {
      rethrow;
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

  Future<void> insertHospital(String email, Map<String, dynamic> hospital) async {
    try {
      final querySnapshot = await _firestore
          .collection('doctors')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          // Use arrayUnion to add the new hospital to the existing list
          await doc.reference.update({
            'hospitals': FieldValue.arrayUnion([hospital])
          });
        }
      } else {
        throw Exception('No doctors info found with email $email');
      }
    } catch (e) {
      throw Exception('Failed to upsert Doctors info: $e');
    }
  }

  Future<void> updateHospital(String email, String recordTitle, Map<String, dynamic> updatedData) async {
    try {
      final querySnapshot = await _firestore
          .collection('doctors')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        List<dynamic> hospital = doc['hospitals'] ?? [];

        // Find index of the record with the matching title
        int recordIndex = hospital.indexWhere((record) => record['name'] == recordTitle);

        if (recordIndex != -1) {
          // Update the specific record's data
          hospital[recordIndex] = updatedData;

          // Update the document with the modified medical history array
          await doc.reference.update({'hospitals': hospital});
        } else {
          throw Exception('No medical history record found with title $recordTitle');
        }
      } else {
        throw Exception('No patient found with email $email');
      }
    } catch (e) {
      throw Exception('Failed to update medical history: $e');
    }
  }

  Future<void> deleteHospital(String email, String recordId) async {
    try {
      await _firestore.collection('doctors').doc(email)
          .collection('hospitals').doc(recordId).delete();
    } catch (e) {
      throw Exception('Failed to delete medical history: $e');
    }
  }

  

  Future<List<Map<String, dynamic>>> getHospitalsByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('doctors')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming there's only one document per unique email
        final doc = querySnapshot.docs.first;
        final medicalHistory = doc['hospitals'] ?? [];

        if (medicalHistory is List) {
          return medicalHistory.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }

      return []; // Return an empty list if no medical history found
    } catch (e) {
      throw Exception('Failed to fetch medical history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllpatients() async {
    try {
      final querySnapshot = await _firestore.collection('patients').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch patients: $e');
    }
  }
}