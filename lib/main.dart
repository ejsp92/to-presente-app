import 'package:attendanceapp/pages/logged_in/home.dart';
import 'package:attendanceapp/pages/logged_in/add_students.dart';
import 'package:attendanceapp/pages/logged_in/attendance.dart';
import 'package:attendanceapp/pages/logged_in/batches.dart';
import 'package:attendanceapp/pages/logged_in/students.dart';
import 'package:attendanceapp/pages/logged_in/account_settings.dart';
import 'package:attendanceapp/pages/logged_in/attendance_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:attendanceapp/pages/logged_out/authentication.dart';
import 'package:provider/provider.dart';
import 'package:attendanceapp/services/account.dart';
import 'package:flutter/services.dart';

void main() => runApp(LoginApp());

class LoginApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return StreamProvider<FirebaseUser>.value(
      value: Account().account,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Attendance App ',
        home: Authentication(),
        routes: {
          '/batches' : (context) => Batches(),
          '/enrolledStudents' : (context) => EnrolledStudents(),
          '/addStudents' : (context) => AddStudents(),
          '/addAttendance' : (context) => AddAttendance(),
          '/attendanceList' : (context) => AttendanceList(),
          '/home' : (context) => Home(),
          '/authentication': (context) => Authentication(),
          '/accountSettings': (context) => AccountSettings(),
        },
      ),
    );
  }
}

