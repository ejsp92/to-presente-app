import 'package:attendanceapp/pages/logged_in/subjects.dart';
import 'package:flutter/material.dart';

class TeacherHome extends StatefulWidget {
  @override
  _TeacherHomeState createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Subjects(),
    );
  }
}
