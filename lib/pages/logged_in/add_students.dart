import 'dart:ui';
import 'package:attendanceapp/services/database.dart';
import 'package:attendanceapp/pages/components/formatting.dart';
import 'package:enhanced_future_builder/enhanced_future_builder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddStudents extends StatefulWidget {
  @override
  _AddStudentsState createState() => _AddStudentsState();
}

class _AddStudentsState extends State<AddStudents> {
  List<Map> _filteredStudents = [];
  List<String> _enrolledStudents = [];
  List<Map> _allStudents = [];
  String _message = '';
  String _batch, _subject;
  String _search = '';
  Student _studentDbInstance;
  TeacherSubjectsAndBatches _tSAB;

  Future setup(FirebaseUser currentUser) async{
    _studentDbInstance = Student(currentUser);
    _tSAB = TeacherSubjectsAndBatches(currentUser);
    _allStudents = await _studentDbInstance.getAllStudents();
    if (_allStudents == null) _allStudents = [];

    if (_allStudents.isNotEmpty) {
      _allStudents =
          _allStudents.where((student) => !_enrolledStudents.contains(
              student['email'])).toList();

      if (_search.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents = _allStudents.where((student) =>
            '${student['firstName']} ${student['lastName']}'
                .toLowerCase()
                .contains(_search.toLowerCase())).toList();
      }
    }
  }

  @override
  Widget build(BuildContext context){
    Map data = ModalRoute.of(context).settings.arguments;
    _enrolledStudents = data['enrolledStudents'];
    _batch = data['batch'];
    _subject = data['subject'];

    return EnhancedFutureBuilder(
      future: setup(Provider.of<FirebaseUser>(context)),
      rememberFutureResult: true,
      whenNotDone: LoadingScreen(),
      whenDone: (arg) => addStudents(),
    );
  }
  Widget addStudents(){
    return Scaffold(
      body: Container(
        padding: EdgeInsets.fromLTRB(10, 50, 10, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: Color.fromRGBO(66, 165, 245, 0.3),
                  blurRadius: 10,
                  offset: Offset(0, 10),
                )],
              ),
              child: Container(
                padding: EdgeInsets.all(6.5),
                child: Row(
                  children: <Widget>[
                    BackButton(color: Colors.grey[700],),
                    Expanded(
                      child: TextFormField(
                        decoration: authInputFormatting.copyWith(hintText: "Buscar"),
                        onChanged: (val){
                          setState(() {
                            _search = val;
                            _filteredStudents = _allStudents.where((student) => '${student['firstName']} ${student['lastName']}'.toLowerCase().contains(_search.toLowerCase())).toList();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(child: Text(_message, style: TextStyle(color: Colors.red),)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                child: ListView.builder(
                  itemBuilder: (context, index){
                    return Card(
                      elevation: 1,
                      child: Container(
                        padding: EdgeInsets.all(6.5),
                        child: ListTile(
                          onTap: () async{
                            Map<String, dynamic> added = _filteredStudents[index];
                            dynamic result = await _tSAB.addStudent(_subject, _batch, added['email']);
                            if(result == 'Success'){
                              setState(() {
                                _enrolledStudents.add(added['email']);
                                _filteredStudents.remove(added);
                                Navigator.pop(context, {'studentAdded' : added['email'],});
                              });
                            }
                            else{
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Algo deu errado, não foi possível adicionar o(a) aluno(a).')
                                  )
                              );
                            }
                          },
                          title: Row(
                            children: <Widget>[
                              Expanded(child: Text('${_filteredStudents[index]['firstName']} ${_filteredStudents[index]['lastName']} (${_filteredStudents[index]['email']})', style: TextStyle(color: Colors.blue[400]),)),
                              Icon(Icons.add_circle_outline, color: Colors.blueGrey,)
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: _filteredStudents.length,),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
