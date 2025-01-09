import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../data/session.dart';
import '../../../data/db_helper.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  String? _fullName;
  String? _address;
  String? _contact;
  String? _demography;
  String? _specialization;
  String? _practingTenure;
  String? _dateOfBirth;
  File? _imageFile;
  bool _isLoading = false;

  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _demographyController = TextEditingController();
  final _specializationController = TextEditingController();
  final _practingTenureController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  List<Map<String, dynamic>> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      String? email = await SessionManager.getUserSession();
      if (email != null) {
        Map<String, dynamic>? userData = await DBHelper().getDoctorByEmail(email);
        if (userData != null) {
          Map<String, dynamic>? doctorInfo =
              await DBHelper().getDoctorInfoByEmail(email);

          setState(() {
            _fullName = userData['fullName'];
            _address = doctorInfo?['address'];
            _contact = doctorInfo?['contact'];
            _demography = doctorInfo?['demography'];
            _specialization = doctorInfo?['specialization'];
            _practingTenure = doctorInfo?['practingTenure'];
            _dateOfBirth = doctorInfo?['birthday'];

            _fullNameController.text = _fullName ?? '';
            _addressController.text = _address ?? '';
            _contactController.text = _contact ?? '';
            _demographyController.text = _demography?? '';
            _specializationController.text = _specialization?? '';
            _practingTenureController.text = _practingTenure?? '';
            _dateOfBirthController.text = _dateOfBirth ?? '';
          });
          _loadAvaiableHospital(email);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _loadAvaiableHospital(email) async {
    try {
      final records = await DBHelper().getHospitalsByEmail(email);
      setState(() {
        _hospitals = records;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your profile lacks hospital. Please add it.')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        setState(() {
          _isLoading = true;
        });
        String? email = await SessionManager.getUserSession();
        if (email != null) {
          Map<String, dynamic>? userData = await DBHelper().getDoctorByEmail(email);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully')),
          );
          Navigator.pop(context, true);
          if (userData != null) {

            await DBHelper().updateDoctors(
              email: email,
              fullName: _fullName,
            );

            await DBHelper().updateDoctorInfo(
              email: email,
              address: _address,
              contact: _contact,
              demography: _demography,
              specialization: _specialization,
              practingTenure: _practingTenure,
              birthday: _dateOfBirth != null
                  ? DateTime.parse(_dateOfBirth!)
                  : null,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildHospitalList() {
    if (_hospitals.isEmpty) {
      return const Center(child: Text('No hospital available'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _hospitals.length,
      itemBuilder: (context, index) {
        final record = _hospitals[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record['name'] ?? 'Unknown name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(10, 62, 29, 1),
                      ),
                    ),
                    IconButton(  
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () {
                        _showAddHospitalModal(context, record: record);
                      },  
                    ),
                  ]
                ),
                const SizedBox(height: 4),
                Text(
                  record['location'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddHospitalModal(BuildContext context, {Map<String, dynamic>? record}) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    if (record != null) {
      nameController.text = record['name'] ?? '';
      locationController.text = record['location'] ?? '';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(record == null ? "Add Hospital" : "Edit Hospital", style: const TextStyle(color: Color.fromRGBO(33, 158, 80, 1), fontSize: 20),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(  
                  labelText: 'Name',  
                  labelStyle: const TextStyle(color: Color.fromRGBO(10, 62, 29, 1)),  
                  border: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1), width: 2.0),  
                  ),  
                  focusedBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                  enabledBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                            fillColor: Colors.white,  
                  filled: true,  
                ),
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: InputDecoration(  
                  labelText: 'Location',  
                  labelStyle: const TextStyle(color: Color.fromRGBO(10, 62, 29, 1)),  
                  border: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1), width: 2.0),  
                  ),  
                  focusedBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                  enabledBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                            fillColor: Colors.white,  
                  filled: true,  
                ),
                style: GoogleFonts.poppins(color: Colors.black),
              ),

              const SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final location = locationController.text.trim();

                if (name.isNotEmpty && location.isNotEmpty) {
                  final email = await SessionManager.getUserSession();
                  final user = await DBHelper().getDoctorByEmail(email!);

                  if (user != null) {
                    Map<String, dynamic> hospital = {
                      'name': name,
                      'location': location,
                    };
                    setState(() {
                      if (record == null) {
                        _hospitals.add(hospital); // Reflect change immediately
                      } else {
                        int index = _hospitals.indexWhere((r) => r['name'] == record['name']);
                        if (index != -1) {
                          _hospitals[index] = hospital; // Update the existing record
                        }
                      }
                    });
                    Navigator.pop(context); 
                    if (record == null) {
                      // Add new medical history
                      await DBHelper().insertHospital(email, hospital);
                    } else {
                      // Update existing medical history
                      await DBHelper().updateHospital(email, record['name'] ,hospital);
                    }
                    setState(() {
                      _loadAvaiableHospital(email); 
                    });
                  }
                }
              },
              child: const Text("Save", style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color.fromRGBO(10, 62, 29, 1),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromRGBO(10, 62, 29, 1),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : const AssetImage('assets/images/avatar.png')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: _pickImage,
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 190, 188, 190),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt,
                              color: Color.fromRGBO(10, 62, 29, 1)),
                          SizedBox(width: 8),
                          Text(
                            'Change Profile Picture',
                            style: TextStyle(color: Color.fromRGBO(10, 62, 29, 1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Full Name', _fullNameController, (value) {
                _fullName = value;
              }),
              _buildTextField('Demography', _demographyController, (value) {
                _demography = value;
              }),
              _buildTextField('Address', _addressController, (value) {
                _address = value;
              }),
              _buildTextField('Contact', _contactController, (value) {
                _contact = value;
              }),
              _buildTextField('Specialization', _specializationController, (value) {
                _specialization = value;
              }),
              _buildTextField('Practing tenure', _practingTenureController, (value) {
                _practingTenure = value;
              }),
              _buildDatePickerField('Date of Birth', _dateOfBirthController),
              const SizedBox(height: 20),
              _buildHospitalList(),
              Center(  
                  child: TextButton(  
                    onPressed: () {
                      _showAddHospitalModal(context);
                    },  
                    child: const Text(  
                      'Add Section',  
                      style: TextStyle(color: Colors.green),  
                    ),  
                  ),  
                ),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: SizedBox(
                    width: 150, // Set a fixed width
                    height: 24, // Set a fixed height to maintain size
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label';
          }
          return null;
        },
        decoration: InputDecoration(  
          labelText: label,  
          labelStyle: const TextStyle(color: Color.fromRGBO(10, 62, 29, 1)),  
          border: OutlineInputBorder(  
            borderRadius: BorderRadius.circular(10),  
            borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1), width: 2.0),  
          ),  
          focusedBorder: OutlineInputBorder(  
            borderRadius: BorderRadius.circular(10),  
            borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
          ),  
          enabledBorder: OutlineInputBorder(  
            borderRadius: BorderRadius.circular(10),  
            borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
          ),  
                    fillColor: Colors.white,  
          filled: true,  
        ),
      ),
    );
  }

  Widget _buildDatePickerField(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            String formattedDate = "${pickedDate.toLocal()}".split(' ')[0];
            setState(() {
              controller.text = formattedDate;
              _dateOfBirth = formattedDate;
            });
          }
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a date';
          }
          return null;
        },
      ),
    );
  }


}
