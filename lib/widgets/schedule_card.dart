import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:doctor_app/models/schedule.dart';
import 'package:doctor_app/utils/constants.dart';
import 'package:doctor_app/Pages/Home/Appointment/add_appointment.dart';

class ScheduleCard extends StatelessWidget {
  final List<Schedule> schedules;
  final Size size;
  final List<Map<String, dynamic>> patients;
  final String appointmentId;

  const ScheduleCard({
    super.key,
    required this.schedules,
    required this.size,
    required this.patients,
    required this.appointmentId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: size.height,
          child: FlutterCarousel(
            options: CarouselOptions(
              height: size.height,
              viewportFraction: 0.93,
              enlargeCenterPage: true,
              autoPlay: schedules.length > 1,
              autoPlayInterval: const Duration(seconds: 4),
              showIndicator: true,
              indicatorMargin: 10,
            ),
            items:
                schedules.map((schedule) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(
                          horizontal: size.width * 0.01,
                        ),
                        padding: EdgeInsets.all(size.width * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 1,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildPatientInfo(schedule),
                                    const SizedBox(height: 20),
                                    _buildScheduleInfo(schedule),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                            _buildActionButtons(context),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfo(Schedule schedule) {
    return Row(
      children: [
        CircleAvatar(
          // backgroundImage: NetworkImage(schedule.avatar),
          backgroundImage: AssetImage('assets/images/avatar.png'),
          radius: size.width * 0.06,
        ),
        SizedBox(width: size.width * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                schedule.doctor,
                style: TextStyle(
                  fontSize: size.width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                schedule.address,
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: size.width * 0.035,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleInfo(Schedule schedule) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(
              vertical: size.height * 0.01,
              horizontal: size.width * 0.04,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(Icons.calendar_today, schedule.dayTime),
                _buildInfoItem(
                  Icons.access_time,
                  "${schedule.startTime} - ${schedule.endTime}",
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryColor),
          SizedBox(width: size.width * 0.01),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: size.width * 0.03,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AddAppointment(
                          id: appointmentId,
                          patients: patients,
                        ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: FittedBox(
                child: Text(
                  'Reschedule',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: size.width * 0.035,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.01),
            child: ElevatedButton(
              onPressed: () {
                // Handle join session
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: FittedBox(
                child: Text(
                  'Join Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.035,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
