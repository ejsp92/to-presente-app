import 'package:attendanceapp/services/account.dart';
import 'package:attendanceapp/services/database.dart';
import 'package:attendanceapp/pages/components/formatting.dart';
import 'package:enhanced_future_builder/enhanced_future_builder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AttendanceList extends StatefulWidget {
  @override
  _AttendanceListState createState() => _AttendanceListState();
}

class _AttendanceListState extends State<AttendanceList> {

  Map _attendancesMap = {};
  List _attendanceListVisible = [];
  String _studentName = 'N/D';
  String _search = '';

  TeacherSubjectsAndBatches _tSAB;

  Future setup(FirebaseUser currentUser, String subject, String batch, String studentEmail) async{
    _tSAB = TeacherSubjectsAndBatches(currentUser);
    _attendancesMap = await _tSAB.getAttendance(subject, batch, studentEmail);

    if (_search.isNotEmpty) {
      _attendanceListVisible = _attendancesMap.keys.where((attendance) => attendance.toString().contains(_search)).toList();
    } else {
     _attendanceListVisible = _attendancesMap.keys.toList();
    }

    sortAttendanceList();
  }

  void sortAttendanceList() {
    _attendanceListVisible.sort((a, b) {
      return '${b.toString().substring(6, 10)}${b.toString().substring(3, 5)}${b.toString().substring(0, 2)}${b.toString().substring(11,13)}${b.toString().substring(14, 16)}'.compareTo(
          '${a.toString().substring(6, 10)}${a.toString().substring(3, 5)}${a.toString().substring(0, 2)}${a.toString().substring(11,13)}${a.toString().substring(14, 16)}'
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Map data = ModalRoute.of(context).settings.arguments;
    _studentName = data['studentName'];
    return Scaffold(
        body: Column(
          children: <Widget>[
            Container(
              color: Colors.white,
              child: Stack(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.fromLTRB(5, 60, 30, 50),
                    decoration: BoxDecoration(
                        color: Colors.blue[400]
                    ),
                    child: Row(
                      children: <Widget>[
                        BackButton(color: Colors.white70,),
                        Expanded(child: Text('Presenças ($_studentName)', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(50))
                          ),
                          child: FlatButton.icon(
                            label: Text('Sair', style: TextStyle(color: Colors.blue[400], fontWeight: FontWeight.bold)),
                            icon: Icon(Icons.exit_to_app, color: Colors.blue[400], size: 15,),
                            onPressed: () async {
                              dynamic result = await Account().signOut();
                              if (result == null) {
                                Navigator.of(context).pushReplacementNamed('/authentication');
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(40, 130, 40, 20),
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
                      child: TextFormField(
                        decoration: authInputFormatting.copyWith(hintText: "Buscar"),
                        onChanged: (val){
                          setState(() {
                            _search = val;
                            if (_search.isNotEmpty) {
                              _attendanceListVisible = _attendancesMap.keys.where((attendance) => attendance.toString().contains(_search)).toList();
                            } else {
                              _attendanceListVisible = _attendancesMap.keys.toList();
                            }
                            sortAttendanceList();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                color: Colors.white,
                child: EnhancedFutureBuilder(
                  future: setup(Provider.of<FirebaseUser>(context), data['subject'], data['batch'], data['studentEmail']),
                  rememberFutureResult: true,
                  whenNotDone: LoadingScreen(),
                  whenDone: (arg) => showAttendance(),
                ),
              ),
            ),
          ],
        )
    );
  }

  Widget showAttendance(){
    if(_attendancesMap == null) {
      return Center(
        child: Text('Nenhuma presença encontrada.', style: TextStyle(color: Colors.blue[400], fontWeight: FontWeight.bold, fontSize: 20),),
      );
    }
    else{
      return Center(
        child: Column(
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
                child: Row(
                  children: <Widget>[
                    Expanded(flex : 3, child: Text('Data', style: TextStyle(color: Colors.blue[400], fontWeight: FontWeight.bold, fontSize: 16),),),
                    Expanded(flex : 3, child: Text('Hora', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 16))),
                    Expanded(flex : 1, child: Text('A/P', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _attendanceListVisible.length,
                itemBuilder: (context, index){
                  return Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
                      child: Row(
                        children: <Widget>[
                          Expanded(flex : 3,child: Text('${_attendanceListVisible[index].substring(0,10)}', style: TextStyle(color: Colors.blue[400],))),
                          Expanded(flex : 3,child: Text('${_attendanceListVisible[index].substring(11,17)} \n ${_attendanceListVisible[index].substring(19,(_attendanceListVisible[index].length))}', style: TextStyle(color: Colors.grey[500]))),
                          Expanded(flex : 1,child: _attendancesMap[_attendanceListVisible[index]] ? Icon(Icons.check_circle_outline, color: Colors.green,) : Icon(Icons.check_circle_outline, color: Colors.red,),),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  }
}
