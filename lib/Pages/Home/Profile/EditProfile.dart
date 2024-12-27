import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../data/session.dart';
import '../../../data/db_helper.dart';

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

  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _demographyController = TextEditingController();
  final _specializationController = TextEditingController();
  final _practingTenureController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

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
        Map<String, dynamic>? userData = await DBHelper().getUserByEmail(email);
        if (userData != null) {
          int userId = userData['id'];
          Map<String, dynamic>? doctorInfo =
              await DBHelper().getDoctorInfoByUserId(userId as String);

          setState(() {
            _fullName = userData['fullName'];
            _address = doctorInfo?['address'];
            _contact = doctorInfo?['contact'];
            _demography = doctorInfo?['demography'];
            _specialization = doctorInfo?['specialization'];
            _practingTenure = doctorInfo?['practing_tenure'];
            _dateOfBirth = doctorInfo?['birthday'];

            _fullNameController.text = _fullName ?? '';
            _addressController.text = _address ?? '';
            _contactController.text = _contact ?? '';
            _demographyController.text = _demography?? '';
            _specializationController.text = _specialization?? '';
            _practingTenureController.text = _practingTenure?? '';
            _dateOfBirthController.text = _dateOfBirth ?? '';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }


  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        String? email = await SessionManager.getUserSession();
        if (email != null) {
          Map<String, dynamic>? userData = await DBHelper().getUserByEmail(email);
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
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
              Center(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save Changes',
                      style: TextStyle(color: Colors.white)),
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
