import 'package:attendanceapp/pages/logged_in/teacher_home.dart';
import 'package:attendanceapp/pages/logged_in/verification.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isEmailVerified;
  @override
  Widget build(BuildContext context) {
    Map data = ModalRoute.of(context).settings.arguments;
    isEmailVerified = data['isEmailVerified'];

    return isEmailVerified ? TeacherHome() : VerifyEmail();
  }
}

