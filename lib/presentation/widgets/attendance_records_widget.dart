import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_rta_attendance/cubit/app_cubit.dart';
import 'package:final_rta_attendance/models/4_attendance_record_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceRecordsWidget extends StatelessWidget {
  AttendanceRecordsWidget(
      {required this.attendanceRecords, required this.todaysDate, super.key});
  final List<AttendanceRecordModel> attendanceRecords;
  final DateTime todaysDate;
  Future<List<AttendanceRecordModel>> fetchAttendanceRecords(
      String schoolName, int busRouteNumber) async {
    List<AttendanceRecordModel> attendanceRecords = [];

    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection("attendanceRecords")
          .where("schoolName", isEqualTo: schoolName)
          .where("busRouteNumber", isEqualTo: busRouteNumber.toString())
          .get();

      attendanceRecords = querySnapshot.docs
          .map((doc) => AttendanceRecordModel(
                busRouteNumber: doc.data()['busRouteNumber'],
                schoolName: doc.data()['schoolName'],
                date: doc.data()['date'].toDate(),
                studentAttendanceCheckboxes:
                    doc.data()['studentAttendanceCheckboxes'],
              ))
          .toList();
    } catch (e) {
      print("Error fetching attendanceRecords: $e");
    }
    print(attendanceRecords.first.date);
    return attendanceRecords;
  }

  Future<String> fetchAttendanceRecordIdWithSchoolNameBusRouteNumber(
      String schoolName, int busRouteNumber) async {
    late String docId;

    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection("attendanceRecords")
          .where("schoolName", isEqualTo: schoolName)
          .where("busRouteNumber", isEqualTo: busRouteNumber.toString())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Use id to get the document ID
        docId = querySnapshot.docs.first.id;
      }
    } catch (e) {
      print("Error fetching attendance record ID: $e");
    }

    return docId;
  }

  @override
  Widget build(BuildContext context) {
    final schoolName = context.read<AppCubit>().state.currentSchool.name;
    final busRouteNumber =
        context.read<AppCubit>().state.currentBusRoute.busRouteNumber;

    //fetch the existing attendance records
    // no need passed down from previous widget

    //check if they have one for today
    final todaysAttendanceRecord = attendanceRecords.firstWhere(
      (element) =>
          element.date.toString().substring(0, 10) ==
          todaysDate.toString().substring(0, 10),
      orElse: () => AttendanceRecordModel.empty(),
    );
    if (todaysAttendanceRecord.busRouteNumber == "") {
      // no
      // create a new record for today itself
      // display that record
      // make the rest reachable from dropdown of last 30 days
      //or oldest record of older than 30 days
    } else {
      //yes
      //display one for today first, make the rest reachable from dropdown of last 30 days
      //or oldest record of older than 30 days
    }
  }
}
