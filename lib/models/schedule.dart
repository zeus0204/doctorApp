class Schedule {
  final String doctor; // This will store the patient's name for the doctor's view
  final String address;
  final String dayTime;
  final String startTime;
  final String endTime;
  final String avatar;
  final String id;

  Schedule({
    required this.doctor,
    required this.address,
    required this.dayTime,
    required this.startTime,
    required this.endTime,
    required this.avatar,
    required this.id,
  });
}
