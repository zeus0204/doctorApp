class Doctorinfo {  
  int? userId; // Foreign key  
  String? address;  
  String? contact;
  String? specialization;
  String? practingTenure;
  DateTime? birthday;  
  String? avatarUrl;  

  Doctorinfo({  
    required this.userId,  
    required this.address,  
    required this.contact,
    required this.specialization,
    required this.practingTenure,
    required this.birthday,  
    required this.avatarUrl,  
  });  

  Map<String, dynamic> toMap() {  
    return {  
      'user_id': userId,  
      'address': address,  
      'contact': contact,
      'specialization': specialization,
      'practing_tenure': practingTenure,
      'birthday': birthday?.toIso8601String(), // Convert to string for storage  
      'avatar_url': avatarUrl,  
    };  
  }  

  factory Doctorinfo.fromMap(Map<String, dynamic> map) {  
    return Doctorinfo(  
      userId: map['user_id'],  
      address: map['address'],  
      contact: map['contact'],
      specialization: map['specialization'],
      practingTenure: map['practing_tenure'],
      birthday: DateTime.parse(map['birthday']),  
      avatarUrl: map['avatar_url'],  
    );  
  }  
}