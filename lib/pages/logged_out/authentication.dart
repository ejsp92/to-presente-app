import 'package:attendanceapp/pages/logged_out/fragments/log_in.dart';
import 'package:attendanceapp/pages/logged_out/fragments/register.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Authentication extends StatefulWidget {
  @override
  _AuthenticationState createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> with SingleTickerProviderStateMixin{
  bool _login = true;

  _updateFragment(bool login){
    setState(() => _login = login);
  }

  @override
  Widget build(BuildContext context) {
    return _login ? Login(_updateFragment) : Register(_updateFragment);
  }
}