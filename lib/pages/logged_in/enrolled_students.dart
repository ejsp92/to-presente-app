import 'package:attendanceapp/services/account.dart';
import 'package:attendanceapp/services/database.dart';
import 'package:attendanceapp/pages/components/formatting.dart';
import 'package:enhanced_future_builder/enhanced_future_builder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EnrolledStudents extends StatefulWidget {
  @override
  _EnrolledStudentsState createState() => _EnrolledStudentsState();
}

class _EnrolledStudentsState extends State<EnrolledStudents> {
  Student _studentDbInstance;
  TeacherSubjectsAndBatches _tSAB;
  List<Map> _allStudents = [];
  List<Map> _enrolledStudents = [];
  Map _studentsMap = {};
  List<String> _studentIds = [];
  List<Map> _studentsVisible = [];
  FirebaseUser _user;
  String _subject = '';
  String _batch = '';
  String _search = '';
  String _errorMsg = '';
  String _userName = '';
  String _userEmail = '';
  bool _removeStudents = false;
  final GlobalKey<ScaffoldState> _scaffoldKey= GlobalKey();

  Future setup() async {
    _tSAB = TeacherSubjectsAndBatches(_user);
    _studentDbInstance = Student(_user);

    _allStudents = await _studentDbInstance.getAllStudents();
    if (_allStudents == null) _allStudents = [];

    _studentsMap = await _tSAB.getStudents(_subject, _batch);
    if (_studentsMap == null) {
      _studentIds = [];
      _enrolledStudents = [];
      _studentsVisible = [];
      _studentsMap = {'Empty': true};
    } else {
      _studentIds = _studentsMap.keys.where((key) => key != 'Empty').toList();
      _enrolledStudents = _allStudents.where((student) => _studentIds.contains(student['email'])).toList();

      if (_search.isNotEmpty) {
        _studentsVisible = _enrolledStudents.where((student) => '${student['firstName']} ${student['lastName']}'.toLowerCase().contains(_search.toLowerCase())).toList();
      } else {
        _studentsVisible = _enrolledStudents;
      }
    }

    _userName = await User(_user).userName();
    if(_userName == null){
      _userName = 'N/D';
    }

    if (_user != null) _userEmail = _user.email;
    if (_userEmail == null) {
      _userEmail = 'N/D';
    }

    try {
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Map data = ModalRoute.of(context).settings.arguments;
    _subject = data['subject'];
    _batch = data['batch'];
    _user = Provider.of<FirebaseUser>(context);
    return Scaffold(
        key: _scaffoldKey,
        endDrawer: Drawer(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(18, 95, 0, 20),
                      color: Colors.blue[400],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(_userName, style: TextStyle(color: Colors.white, fontSize: 20),),
                          SizedBox(height: 10,),
                          Text(_userEmail, style: TextStyle(color: Colors.white, fontSize: 12),),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    ListTile(
                      title: Text('Adicionar Estudantes'),
                      onTap: () async{
                        Navigator.of(context).pop();
                        dynamic returnedData = await Navigator.pushNamed(context, '/addStudents', arguments: {'enrolledStudents' : _studentIds, 'batch' : _batch, 'subject': _subject});
                        if(returnedData != null) {
                          if(_studentsMap['Empty']){
                            _studentsMap['Empty'] = false;
                          }
                          setState(() {
                            if (!_studentIds.contains(returnedData['studentAdded'])) {
                              _studentsMap['${returnedData['studentAdded']}'] = false;
                              _studentIds.add(returnedData['studentAdded']);
                              _enrolledStudents = _allStudents.where((student) =>
                                  _studentIds.contains(student['email']))
                                  .toList();

                              if (_search.isNotEmpty) {
                                _studentsVisible =
                                    _enrolledStudents.where((student) =>
                                        '${student['firstName']} ${student['lastName']}'
                                            .toLowerCase()
                                            .contains(_search.toLowerCase()))
                                        .toList();
                              } else {
                                _studentsVisible = _enrolledStudents;
                              }
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Remover Estudante'),
                      onTap: (){
                        Navigator.of(context).pop();
                        setState(() {
                          _removeStudents = true;
                        });
                      },
                    ),
                    ListTile(
                      title: Text('Registrar Presenças'),
                      onTap: () async{
                        Navigator.of(context).pop();
                        await Navigator.pushNamed(context, '/addAttendance', arguments: {'enrolledStudents' : _enrolledStudents, 'subject' : _subject, 'batch' : _batch});
                      },
                    ),
                    ListTile(
                      title: Text('Capturar Presenças'),
                      onTap: () async{
                        Navigator.of(context).pop();
                        await Navigator.pushNamed(context, '/captureAttendance', arguments: {'enrolledStudents' : _enrolledStudents, 'subject' : _subject, 'batch' : _batch});
                      },
                    ),
                    ListTile(
                      title: Text('Configurações de Conta'),
                      onTap: (){
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/accountSettings');
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
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
                      Expanded(child: Text('Estudantes ($_batch)', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),)),
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
                              Navigator.of(context).pushNamedAndRemoveUntil('/authentication', (Route<dynamic> route) => false);
                            }
                          },
                        ),
                      ),
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
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(6.5),
                          child: TextFormField(
                            decoration: authInputFormatting.copyWith(hintText: "Buscar"),
                            onChanged: (val){
                              setState(() {
                                _search = val;

                                if (_search.isNotEmpty) {
                                  _studentsVisible =
                                      _enrolledStudents.where((student) =>
                                          '${student['firstName']} ${student['lastName']}'
                                              .toLowerCase()
                                              .contains(_search.toLowerCase()))
                                          .toList();
                                } else {
                                  _studentsVisible = _enrolledStudents;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.menu, color: Colors.blue[400]),
                        onPressed: (){
                          _scaffoldKey.currentState.openEndDrawer();
                        },
                      ),
                      SizedBox(width: 5,)
                    ],
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
                  future: setup(),
                  rememberFutureResult: true,
                  whenNotDone: LoadingData(),
                  whenDone: (arg) => studentList(),
              ),
            ),
          ),
        ],
      )
  );
  }

  Widget studentList(){
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _studentsMap['Empty'] ? addStudentButton() : Container(),
          _removeStudents && !_studentsMap['Empty'] ? removeStudent() : Container(),
          _studentsMap['Empty'] ? SizedBox(height: 15,) : Container(),
          _studentsMap['Empty'] ? Expanded(child: Text('Nenhum estudante encontrado nesta turma.', style: TextStyle(color: Colors.red),),) : Expanded(
            child: ListView.builder(
              itemCount: _studentsVisible.length,
              itemBuilder: (context, index){
                return Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ListTile(
                      onTap: () async{
                       if(_removeStudents){
                         showDialog(
                             context: context,
                             builder: (context){
                               return Dialog(
                                 shape:  RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(20.0)
                                 ),
                                 child: Container(
                                   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                   child: Column(
                                     mainAxisSize: MainAxisSize.min,
                                     children: <Widget>[
                                       SizedBox(height: 30,),
                                       Text('Você realmente deseja remover ${_studentsVisible[index]['firstName']} ${_studentsVisible[index]['lastName']} ? Está ação não pode ser revertida.', textAlign: TextAlign.justify,),
                                       SizedBox(height: 20,),
                                       Row(
                                         children: <Widget>[
                                           Expanded(
                                             child: FlatButton(
                                               child: Text('Cancelar', style: TextStyle(color: Colors.blue[400]),),
                                               onPressed: (){
                                                 Navigator.of(context).pop();
                                               },
                                             ),
                                           ),
                                           Expanded(
                                             child: FlatButton(
                                               child: Text('Remover', style: TextStyle(color: Colors.blue[400]),),
                                               onPressed: () async{
                                                 dynamic result = await _tSAB.deleteStudent(_subject, _batch, _studentsVisible[index]['email']);
                                                 Map deleted = _studentsVisible[index];
                                                 if(result == 'Success')
                                                 {
                                                   Navigator.of(context).pop();
                                                   setState(() {
                                                     _errorMsg = '';
                                                     _studentsVisible.removeAt(index);
                                                     _studentIds.remove(deleted['email']);
                                                     _studentsMap.removeWhere((key, value) => key == deleted['email']);
                                                   });
                                                   if(_studentIds.isEmpty){
                                                     setState(() {
                                                       _removeStudents = false;
                                                       _studentsMap['Empty'] = true;
                                                     });
                                                   }
                                                 }
                                                 else{
                                                   ScaffoldMessenger.of(context).showSnackBar(
                                                       SnackBar(
                                                           content: Text('Não foi possível remover ${_studentsVisible[index]['firstName']} ${_studentsVisible[index]['lastName']}.')
                                                       )
                                                   );

                                                   Navigator.of(context).pop();
                                                 }
                                               },
                                             ),
                                           )
                                         ],
                                       )
                                     ],
                                   ),
                                 ),
                               );
                             }
                         );
                       }
                       else{
                         Navigator.pushNamed(context, '/attendanceList', arguments: {
                           'subject': _subject,
                           'batch' : _batch,
                           'studentEmail' : _studentsVisible[index]['email'],
                           'studentName' : '${_studentsVisible[index]['firstName']} ${_studentsVisible[index]['lastName']}',
                         });
                       }
                      },
                      title: Row(
                        children: <Widget>[
                          Expanded(child: Text('${_studentsVisible[index]['firstName']} ${_studentsVisible[index]['lastName']} (${_studentsVisible[index]['email']})', style: TextStyle(color: Colors.blue[400]),)),
                          _removeStudents ? Icon(Icons.delete, color: Colors.grey[700],) : Icon(Icons.forward, color: Colors.grey[700],),
                        ],
                      ),
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

  Widget addStudentButton() {

    return GestureDetector(
      onTap:() async{
        dynamic data = await Navigator.pushNamed(context, '/addStudents', arguments: {'enrolledStudents' : _studentIds, 'batch' : _batch, 'subject': _subject});
        print(data);
        if(data != null) {
          if(_studentsMap['Empty']){
            _studentsMap['Empty'] = false;
          }
          setState(() {
            _studentsMap['${data['studentAdded']}'] = false;
            _studentIds.add(data['studentAdded']);
            _enrolledStudents = _allStudents.where((student) =>
                _studentIds.contains(student['email']))
                .toList();

            if (_search.isNotEmpty) {
              _studentsVisible =
                  _enrolledStudents.where((student) =>
                      '${student['firstName']} ${student['lastName']}'
                          .toLowerCase()
                          .contains(_search.toLowerCase()))
                      .toList();
            } else {
              _studentsVisible = _enrolledStudents;
            }
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
            color: Colors.blue[400],
            borderRadius: BorderRadius.all(Radius.circular(50))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add, color: Colors.white, size: 20,),
            SizedBox(width: 5,) ,
            Text('Adicionar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),),
          ],
        ),
      ),
    );
  }

  Widget removeStudent(){
    return Column(
      children: <Widget>[
        _errorMsg.isEmpty ? Container() : Center(child: Text(_errorMsg, style: TextStyle(color: Colors.red), textAlign: TextAlign.center,),),
        _errorMsg.isEmpty ? Container() : SizedBox(height: 15,),
        GestureDetector(
          onTap:() {
            setState(() {
              _removeStudents = !_removeStudents;
              _errorMsg = '';
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
                color: Colors.blue[400],
                borderRadius: BorderRadius.all(Radius.circular(50))
            ),
            child: Center(child: Text('Concluir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),)),
          ),
        ),
      ],
    );
  }
}