import 'package:attendanceapp/services/account.dart';
import 'package:attendanceapp/services/firestore.dart';
import 'package:attendanceapp/pages/shared/formatting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

class Register extends StatefulWidget {
  final ValueChanged<bool> updateTitle;
  Register(this.updateTitle);
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final User _account = User();
  final _formKey = GlobalKey<FormState>();

  String userEmail, userPass, userFirstName, userLastName, teacherEmail, studentFaceId;
  String type = '';
  List<String> _types = ['', 'Professor', 'Estudante'];
  bool loading = false;
  String errorMsg = '';
  Widget _currentForm;

  @override
  void initState() {
    super.initState();
    _currentForm = _registerNameEmail();
  }

  @override
  Widget build(BuildContext context) {
    return loading ? AuthLoading(185, 20) : Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 45, 0, 5),
          child: _currentForm,
        ),
        SizedBox(height: 30,),
        GestureDetector(
          onTap: () => widget.updateTitle(true),
          child: Container(
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: 70),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.grey[400],
            ),
            child: Center(
              child: Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 17),),
            ),
          ),
        ),
      ],
    );
  }

  Widget _registerNameEmail(){
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Color.fromRGBO(51, 204, 255, 0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              )],
            ),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey[200]))
                        ),
                        child: TextFormField(
                          decoration: authInputFormatting.copyWith(hintText: "Nome"),
                          validator: (val) => val.isEmpty ? 'Nome não pode ficar em branco' : null,
                          initialValue: userFirstName,
                          onChanged: (val){
                            userFirstName = val;
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey[200]))
                        ),
                        child: TextFormField(
                          decoration: authInputFormatting.copyWith(hintText: "Sobrenome"),
                          validator: (val) => val.isEmpty ? 'Sobrenome não pode ficar em branco' : null,
                          initialValue: userLastName,
                          onChanged: (val){
                            userLastName =val;
                          },
                        ),
                      ),
                    )
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[200]))
                  ),
                  child: TextFormField(
                    initialValue: userEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: authInputFormatting.copyWith(hintText: "Email"),
                    validator: _account.validateId,
                    onChanged: (val) {
                      userEmail = val;
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[200]))
                  ),
                  height: 85,
                  child: FormField<String>(
                    validator: (val) => type == null || type.isEmpty ? 'Selecione um tipo' : null,
                    builder: (FormFieldState<String> state) {
                      return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Flexible(
                                  child: InputDecorator(
                                    decoration: authInputFormatting.copyWith(hintText: 'Tipo'),
                                    isEmpty: type == null || type.isEmpty,
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: type,
                                        isDense: true,
                                        onChanged: (value) {
                                          setState(() {
                                            type = value;
                                            state.didChange(value);
                                          });
                                        },
                                        items: _types.map((value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            state.hasError ? Container(padding: EdgeInsets.fromLTRB(14.0, 0.0, 14.0, 0.0),child: Text(state.errorText, style: Theme.of(context).textTheme.caption.copyWith(color: Colors.red[700]))) : Container()
                          ]);
                      // return

                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30,),
          Text(errorMsg, style: TextStyle(color: Colors.red[700]),),
          SizedBox(height: 30,),
          GestureDetector(
            onTap: () {
              if(_formKey.currentState.validate()) {
                  if (type == 'Estudante') {
                    setState(() {
                      errorMsg = '';
                      _currentForm = _registerFaceId();
                    });
                  } else {
                    setState(() {
                      errorMsg = '';
                      _currentForm = _registerPasswordType();
                    });
                  }
                }
            },
            child: Container(
              height: 50,
              margin: EdgeInsets.symmetric(horizontal: 50),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.blue[400],
              ),
              child: Center(
                child: Text("Próximo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 17),),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _registerFaceId() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Color.fromRGBO(51, 204, 255, 0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              )],
            ),
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[200]))
                  ),
                  child: TextFormField(
                    initialValue: teacherEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: authInputFormatting.copyWith(hintText: "Email do professor"),
                    validator: _account.validateId,
                    onChanged: (val) {
                      log('data: $userEmail');
                      teacherEmail = val;
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                  },
                  child: Container(
                    padding: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[200]))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.camera_alt, color: studentFaceId == null || studentFaceId.isEmpty ? Colors.grey[400] : Colors.blue[400], size: 30.0,),
                        Container(
                            padding: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                            child: Text("Registrar face", style: Theme.of(context).textTheme.bodyText1.copyWith(color: studentFaceId == null || studentFaceId.isEmpty ? Colors.grey[400] : Colors.blue[400]),),
                        ),
                      ]
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30,),
          Text(errorMsg, style: TextStyle(color: Colors.red[700]),),
          SizedBox(height: 30,),
          Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      errorMsg = '';
                      _currentForm = _registerNameEmail();
                    });
                  },
                  child: Container(
                    height: 50,
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.blue[400],
                    ),
                    child: Center(
                      child: Text("Voltar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 17),),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () async {
                    if (_formKey.currentState.validate()) {
                      if (studentFaceId == null || studentFaceId.isEmpty) {
                        setState(() {
                          errorMsg = 'Registre sua face para continuar';
                          _currentForm = _registerFaceId();
                        });
                        return;
                      }

                      // setState(() {
                      //   error = '';
                      //   loading = true;
                      // });
                      // String userType = type == 'Professor' ? 'teacher' : 'student';
                      // FirebaseUser user = await _account.register(userEmail, userPass);
                      // if (user != null) {
                      //   UserDataBase userData = UserDataBase(user) ;
                      //   dynamic userDataSet = await userData.newUserData(userFirstName, userLastName, userType);
                      //   bool isEmailVerified = user.isEmailVerified;
                      //   if (userDataSet != null) {
                      //     dynamic type = await userData.userType();
                      //     if(type != null){
                      //       Navigator.of(context).pushReplacementNamed('/home', arguments: {'type' : type, 'isEmailVerified' : isEmailVerified});
                      //     } else{
                      //       await _account.signOut();
                      //       setState(() {
                      //         loading = false;
                      //         error = 'Não foi possível identificar o tipo de usuário';
                      //       });
                      //     }
                      //   } else {
                      //     await _account.deleteUser();
                      //     setState(() {
                      //       loading = false;
                      //       error = 'Não foi possível adicionar os dados do usuário na base de dados';
                      //     });
                      //   }
                      // } else {
                      //   setState(() {
                      //     type = '';
                      //     loading = false;
                      //     error = 'Por favor, informe um email válido';
                      //     _currentForm = _registerNameEmail();
                      //   });
                      // }
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
                      child: Text("Enviar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 17),),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _registerPasswordType() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Color.fromRGBO(51, 204, 255, 0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              )],
            ),
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[200]))
                  ),
                  child: TextFormField(
                    decoration: authInputFormatting.copyWith(hintText: "Senha"),
                    validator: _account.validateRegisterPass,
                    obscureText: true,
                    onChanged: (val){
                      userPass = val;
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30,),
          Text(errorMsg, style: TextStyle(color: Colors.red[700]),),
          SizedBox(height: 30,),
          Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentForm = _registerNameEmail();
                    });
                  },
                  child: Container(
                    height: 50,
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.blue[400],
                    ),
                    child: Center(
                      child: Text('Voltar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 17),),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () async {
                    if (_formKey.currentState.validate()) {
                      setState(() {
                        errorMsg = '';
                        loading = true;
                      });
                      String userType = type == 'Professor' ? 'teacher' : 'student';
                      FirebaseUser user = await _account.register(userEmail, userPass);
                      if (user != null) {
                        UserDataBase userData = UserDataBase(user) ;
                        dynamic userDataSet = await userData.newUserData(userFirstName, userLastName, userType);
                        bool isEmailVerified = user.isEmailVerified;
                        if (userDataSet != null) {
                          dynamic type = await userData.userType();
                          if(type != null){
                            Navigator.of(context).pushReplacementNamed('/home', arguments: {'type' : type, 'isEmailVerified' : isEmailVerified});
                          } else{
                            await _account.signOut();
                            setState(() {
                              loading = false;
                              errorMsg = 'Não foi possível identificar o tipo de usuário';
                            });
                          }
                        } else {
                          await _account.deleteUser();
                          setState(() {
                            loading = false;
                            errorMsg = "Não foi possível adicionar os dados do usuário na base de dados";
                          });
                        }
                      } else {
                        setState(() {
                          type = '';
                          loading = false;
                          errorMsg = "Por favor, informe um email válido";
                          _currentForm = _registerNameEmail();
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
                      child: Text("Cadastrar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 17),),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

