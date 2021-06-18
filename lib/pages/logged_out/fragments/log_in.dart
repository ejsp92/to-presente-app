import 'package:attendanceapp/services/account.dart';
import 'package:attendanceapp/services/database.dart';
import 'package:attendanceapp/pages/components/formatting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  final ValueChanged<bool> updateTitle;
  Login(this.updateTitle);
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final Account _account = Account();
  final _formKey = GlobalKey<FormState>();


  String _email;
  String _pass;
  String _errorMsg = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context){
    return _login();
  }

  Widget _login() {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                colors: [
                  Colors.blue[900],
                  Colors.blue[400],
                  Colors.blue[200]
                ]
            )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(35, 70, 15, 0),
              child: Text('Login.', style: TextStyle(color: Colors.white, fontSize: 50, letterSpacing: 2, fontWeight: FontWeight.bold),),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(38, 0, 15, 0),
              child: Text('Bem-vindo de volta!', style: TextStyle(color: Colors.white, fontSize: 22,),),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(0, 70, 0, 0),
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  // borderRadius: BorderRadius.only(
                  //     topLeft: Radius.circular(50), topRight: Radius.circular(50))
                ),
                child: ListView(
                  children: <Widget>[
                    _loading ? AuthLoading(185, 20) : _form(),
                    SizedBox(height: 50,)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(){
    return Column(
      children: <Widget>[
        Form(
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
                          initialValue: _email,
                          decoration: authInputFormatting.copyWith(hintText: "Email"),
                          validator: _account.validateId,
                          onChanged: (val){
                            _email = val;
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey[200]))
                        ),
                        child: TextFormField(
                          initialValue: _pass,
                          decoration: authInputFormatting.copyWith(hintText: "Senha"),
                          validator: _account.validateLoginPass,
                          obscureText: true,
                          onChanged: (val){
                            _pass = val;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30,),
                Text(_errorMsg, style: TextStyle(color: Colors.red),),
                SizedBox(height: 30,),
                GestureDetector(
                  onTap: () async{
                    if(_formKey.currentState.validate())
                    {
                      setState(() => _loading = true);
                      FirebaseUser user = await _account.login(_email, _pass);
                      if(user != null)
                      {
                        bool isEmailVerified = user.isEmailVerified;
                        dynamic type = await User(user).userType();
                        if(type != null){
                          Navigator.of(context).pushReplacementNamed('/home', arguments: {'type' : type, 'isEmailVerified' : isEmailVerified});
                        }
                        else{
                          await _account.signOut();
                          setState(() {
                            _loading = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Não foi possível identificar o tipo de usuário. Tente novamente.')
                              )
                          );
                        }
                      }
                      else
                      {
                        setState(() {
                          _loading = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Email ou senha inválida.')
                            )
                        );
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
                      child: Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 17),),
                    ),
                  ),
                ),
                SizedBox(height : 30),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => widget.updateTitle(false),
          child: Container(
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: 70),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.grey[400],
            ),
            child: Center(
              child: Text("Cadastro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 17),),
            ),
          ),
        ),
      ],
    );
  }
}
