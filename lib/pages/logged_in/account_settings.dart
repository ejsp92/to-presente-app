import 'package:attendanceapp/services/account.dart';
import 'package:attendanceapp/services/database.dart';
import 'package:attendanceapp/pages/components/formatting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountSettings extends StatefulWidget {
  @override
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  Map _status = {
    'index': null,
    'action': null,
  };

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
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
                        Expanded(child: Text(
                          'Configurações de Conta', style: TextStyle(color: Colors
                            .white, fontSize: 25, fontWeight: FontWeight
                            .bold),)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(
                                  50))
                          ),
                          child: FlatButton.icon(
                            label: Text('Sair', style: TextStyle(
                                color: Colors.blue[400],
                                fontWeight: FontWeight.bold)),
                            icon: Icon(Icons.exit_to_app, color: Colors.blue[400],
                              size: 15,),
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
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                color: Colors.white,
                child: ListView(
                  children: <Widget>[
                    SizedBox(height: 40,),
                    Card(
                      child: ListTile(
                        title: Text("Atualizar nome"),
                        trailing: Icon(Icons.edit),
                        subtitle: _status['index'] == 0 ? Text(
                          _status['status'],
                          style: TextStyle(color: _status['error']
                              ? Colors.red
                              : Colors.green),) : Text(
                            "Atualize seu nome de exibição"),
                        onTap: () {
                          setState(() {
                            _status = {
                              'index': null,
                              'action': 0,
                            };
                          });
                        },
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                    ),
                    _status['action'] == 0 ? changeNameForm() : Container(),
                    // Card(
                    //   child: ListTile(
                    //     title: Text("Atualizar email"),
                    //     trailing: Icon(Icons.email),
                    //     subtitle: _status['index'] == 1 ? Text(
                    //       _status['status'],
                    //       style: TextStyle(color: _status['error']
                    //           ? Colors.red
                    //           : Colors.green),) : Text(
                    //         "Atualize seu email atual"),
                    //     onTap: () {
                    //       ScaffoldMessenger.of(context).showSnackBar(
                    //           SnackBar(
                    //               content: Text('Função indisponível.')
                    //           )
                    //       );
                    //     },
                    //   ),
                    //   shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(10.0)),
                    // ),
                    Card(
                      child: ListTile(
                        title: Text("Atualizar senha"),
                        trailing: Icon(Icons.lock_outline),
                        subtitle: _status['index'] == 2 ? Text(
                          _status['status'], style: TextStyle(
                            color: _status['error'] ? Colors.red : Colors
                                .green),) : Text("Atualize sua senha"),
                        onTap: () {
                          setState(() {
                            _status = {
                              'index': null,
                              'action': 2,
                            };
                          });
                        },
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                    ),
                    _status['action'] == 2 ? changePasswordForm() : Container(),
                  ],
                ),
              ),
            ),
          ],
        )
    );
  }

  Widget changeNameForm() {
    String firstName;
    String lastName;
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 45, 0, 5),
        child: Column(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: Color.fromRGBO(66, 165, 245, 0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
                ],
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[200]))
                    ),
                    child: TextFormField(
                      decoration: authInputFormatting.copyWith(
                          hintText: "Nome"),
                      validator: (val) =>
                      val.isEmpty
                          ? "Nome não pode ficar em branco"
                          : null,
                      onChanged: (val) {
                        firstName = val;
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[200]))
                    ),
                    child: TextFormField(
                      decoration: authInputFormatting.copyWith(
                          hintText: "Sobrenome"),
                      validator: (val) =>
                      val.isEmpty
                          ? "Sobrenome não pode ficar em branco"
                          : null,
                      onChanged: (val) {
                        lastName = val;
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30,),
            Row(
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (_formKey.currentState.validate()) {
                        dynamic result = await User(Provider.of<
                            FirebaseUser>(context, listen: false))
                            .updateUserName(firstName, lastName);
                        if (result != null) {
                          setState(() {
                            _status = {
                              'index': 0,
                              'action': null,
                              'error': false,
                              'status': 'Nome atualizado com sucesso',
                            };
                          });
                        }
                        else {
                          setState(() {
                            _status = {
                              'index': 0,
                              'action': 0,
                              'error': true,
                              'status': 'Não foi possível atualizar o nome',
                            };
                          });
                        }
                      }
                    },
                    child: Container(
                      height: 50,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.blue[400],
                      ),
                      child: Center(
                        child: Text("Atualizar", style: TextStyle(color: Colors
                            .white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 17),),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _status = {
                          'index': null,
                          'action': null,
                        };
                      });
                    },
                    child: Container(
                      height: 50,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.grey[300],
                      ),
                      child: Center(
                        child: Text("Cancelar", style: TextStyle(color: Colors
                            .white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 17),),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget changePasswordForm() {
    String newPass;
    String oldPass;
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 45, 0, 5),
        child: Column(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: Color.fromRGBO(66, 165, 245, 0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
                ],
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[200]))
                    ),
                    child: TextFormField(
                      decoration: authInputFormatting.copyWith(
                          hintText: "Senha atual"),
                      validator: Account().validateRegisterPass,
                      obscureText: true,
                      onChanged: (val) {
                        oldPass = val;
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[200]))
                    ),
                    child: TextFormField(
                      decoration: authInputFormatting.copyWith(
                          hintText: "Nova senha"),
                      validator: Account().validateRegisterPass,
                      obscureText: true,
                      onChanged: (val) {
                        newPass = val;
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30,),
            Row(
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (_formKey.currentState.validate()) {
                        dynamic result = await Account().resetPassword(oldPass, newPass);
                        if(result != null){
                          setState(() {
                            _status = {
                              'index': 2,
                              'action': null,
                              'error': false,
                              'status': 'Senha atualizada com sucesso',
                            };
                          });
                        }
                        else{
                          setState(() {
                            _status = {
                              'index': 2,
                              'action': 2,
                              'error': true,
                              'status': 'Não foi possível atualizar a senha',
                            };
                          });
                        }
                      }
                    },
                    child: Container(
                      height: 50,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.blue[400],
                      ),
                      child: Center(
                        child: Text("Atualizar", style: TextStyle(color: Colors
                            .white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 17),),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _status = {
                          'index': null,
                          'action': null,
                        };
                      });
                    },
                    child: Container(
                      height: 50,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.grey[300],
                      ),
                      child: Center(
                        child: Text("Cancelar", style: TextStyle(color: Colors
                            .white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 17),),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}