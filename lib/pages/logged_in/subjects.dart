import 'dart:ui';
import 'package:attendanceapp/services/account.dart';
import 'package:attendanceapp/services/database.dart';
import 'package:attendanceapp/pages/components/formatting.dart';
import 'package:enhanced_future_builder/enhanced_future_builder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Subjects extends StatefulWidget {
  @override
  _SubjectsState createState() => _SubjectsState();
}

class _SubjectsState extends State<Subjects> {
  List<String> _subjects = [];
  List<String> _subjectsVisible = [];
  bool _delete = false;
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  String _search = '';
  String _errorMsg = '';
  String _userName = '';
  String _userEmail = '';
  TeacherSubjectsAndBatches _tSAB;
  FirebaseUser _user;

  Future setup() async {
    _tSAB = TeacherSubjectsAndBatches(_user);
    _subjects = await _tSAB.getSubjects();
    if (_subjects == null) _subjects = ['Empty'];

    if (_search.isEmpty)
      _subjectsVisible = _subjects;
    else
      _subjectsVisible = _subjects.where((subject) =>
          subject.toLowerCase().contains(_search.toLowerCase())).toList();

    _userName = await User(_user).userName();
    if (_userName == null) {
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
                      title: Text('Adicionar Disciplina'),
                      onTap: () async{
                        Navigator.of(context).pop();
                        addSubjectForm().then((onValue){
                          setState(() {});
                        });
                      },
                    ),
                    ListTile(
                      title: Text('Remover Disciplina'),
                      onTap: (){
                        Navigator.of(context).pop();
                        if(_subjects[0] != 'Empty'){
                          setState(() {
                            _delete = true;
                          });
                        }
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
                    padding: EdgeInsets.fromLTRB(45, 60, 30, 50),
                    decoration: BoxDecoration(
                        color: Colors.blue[400],
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(child: Text('Disciplinas', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),)),
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
                                  _subjectsVisible = _subjects.where((subject) => subject.toLowerCase().contains(_search.toLowerCase())).toList();
                                });
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.menu, color: Colors.blue[400]),
                          onPressed: () async{
                            _scaffoldKey.currentState.openEndDrawer();
                          },
                        ),
                        SizedBox(width: 5,),
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
                  whenDone: (arg) => subjectsList(),
                ),
              ),
            ),
          ],
        )
    );
  }

  Widget subjectsList(){
    return Center(
      child: Column(
        children: <Widget>[
          _subjects[0] == 'Empty' ? addSubjectButton() : Container(),
          _delete && _subjects[0] != 'Empty' ? deleteButton() : Container(),
          _subjects[0] == 'Empty' ? SizedBox(height: 15,) : Container(),
          _subjects[0] == 'Empty' ? Text('Nenhuma disciplina encontrada.', style: TextStyle(color: Colors.red),) : Expanded(
            child: ListView.builder(
              itemCount: _subjectsVisible.length,
              itemBuilder: (context, index){
                return Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ListTile(
                      onTap: () async{
                        if(!_delete){
                          Navigator.of(context).pushNamed('/batches', arguments: {'subject' : _subjectsVisible[index]});
                        }
                        else{
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
                                      Text('Você realmente deseja deletar a disciplina ${_subjectsVisible[index]} ? Está ação não pode ser revertida.', textAlign: TextAlign.justify,),
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
                                              child: Text('Deletar', style: TextStyle(color: Colors.blue[400]),),
                                              onPressed: () async{
                                                String deleted = _subjectsVisible[index];
                                                dynamic result = await _tSAB.deleteSubject(_subjectsVisible[index]);
                                                if(result == 'Success')
                                                {
                                                  setState(() {
                                                    _errorMsg = '';
                                                    _subjectsVisible.remove(deleted);
                                                    _subjects.remove(deleted);
                                                  });
                                                  if(_subjects.isEmpty){
                                                    setState(() {
                                                      _subjects.add('Empty');
                                                      _delete = false;
                                                    });
                                                  }
                                                  Navigator.of(context).pop();
                                                }
                                                else{
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                          content: Text("Não foi possível deletar a disciplina ${_subjectsVisible[index]}")
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
                      },
                      title: Row(
                        children: <Widget>[
                          Expanded(child: Text('${_subjectsVisible[index]}', style: TextStyle(color: Colors.blue[400]),)),
                          _delete ? Icon(Icons.delete, color: Colors.grey[700],) : Icon(Icons.forward, color: Colors.grey[700],)
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

  Widget addSubjectButton()
  {
    return Row(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap:() async{
              addSubjectForm().then((onValue){
                setState(() {});
              });
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
                  Icon(Icons.add, color: Colors.white, size: 25,),
                  SizedBox(width: 10,) ,
                  Text('Adicionar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),)
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget deleteButton() {
    return Column(
      children: <Widget>[
        _errorMsg.isEmpty ? Container() : Center(child: Text(_errorMsg, style: TextStyle(color: Colors.red), textAlign: TextAlign.center,),),
        _errorMsg.isEmpty ? Container() : SizedBox(height: 15,),
        GestureDetector(
          onTap:(){
            setState(() {
              _delete = false;
              _errorMsg = '';
            }
            );
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
                Icon(Icons.add, color: Colors.white, size: 25,),
                SizedBox(width: 10,) ,
                Text('Concluir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),)
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future addSubjectForm(){
    TextEditingController subjectController = TextEditingController();
    String subject = '';
    bool adding = false;
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState){
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(20.0)),
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _errorMsg.isEmpty ? Container() : Center(child: Text(_errorMsg, style: TextStyle(color: Colors.red),)),
                            _errorMsg.isEmpty ? Container() : SizedBox(height: 15,),
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                boxShadow: [BoxShadow(
                                  color: Color.fromRGBO(66, 165, 245, 0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 10),
                                )],
                              ),
                              child: TextFormField(
                                controller: subjectController,
                                decoration: authInputFormatting.copyWith(hintText: 'Nome da disciplina'),
                                validator: (val) => val.isEmpty ? 'Nome da disciplina não pode ficar em branco' : null,
                                onChanged: (val) => subject = val,
                              ),
                            ),
                            SizedBox(height: 15,),
                            adding ? Center(child: Text("Adicionando..."),) : Row(
                              children: <Widget>[
                                Expanded(
                                  child: GestureDetector(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 45, vertical: 15),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[400],
                                        borderRadius: BorderRadius.all(Radius.circular(20)),
                                      ),
                                      child: Center(child: Text("Adicionar", style: TextStyle(color: Colors.white),)),
                                    ),
                                    onTap: () async{
                                      if(_formKey.currentState.validate())
                                      {
                                        setState(() {
                                          adding = true;
                                        });
                                        if(_subjects.contains(subject))
                                        {
                                          setState(() {
                                            adding = false;
                                          });

                                          ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                  content: Text('Disciplina já existe.')
                                              )
                                          );
                                        }
                                        else
                                        {
                                          dynamic result = await _tSAB.addSubject(subject);
                                          if(result ==  null)
                                          {
                                            setState(() {
                                              adding = false;
                                            });

                                            ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                    content: Text('Algo deu errado, não foi possível adicionar a disciplina.')
                                                )
                                            );
                                          }
                                          else
                                          {
                                            if(_subjects[0] == 'Empty'){
                                              setState((){
                                                _subjects.clear();
                                                _subjects.add(subject);
                                                _errorMsg = '';
                                                subject = '';
                                                subjectController.clear();
                                                adding = false;
                                              });
                                            }
                                            else{
                                              setState((){
                                                _subjects.add(subject);
                                                _errorMsg = '';
                                                subject = '';
                                                subjectController.clear();
                                                adding = false;
                                              });
                                            }
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(width: 10,),
                                Expanded(
                                  child: GestureDetector(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 45, vertical: 15),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[400],
                                        borderRadius: BorderRadius.all(Radius.circular(20)),
                                      ),
                                      child: Center(child: Text("Concluir", style: TextStyle(color: Colors.white),)),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _errorMsg = '';
                                        subject = '';
                                        subjectController.clear();
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                )
                              ],
                            ),
                          ],
                        )
                    ),
                  ),
                ),
              );
            },
          );
      });
  }
}







