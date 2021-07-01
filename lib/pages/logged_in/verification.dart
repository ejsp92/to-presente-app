import 'package:attendanceapp/services/account.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerifyEmail extends StatefulWidget {
  @override
  _VerifyEmailState createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  String _msg = '';
  bool _sent = false;
  
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
                        color: Colors.blue[400],
                    ),
                    child: Row(
                      children: <Widget>[
                        BackButton(color: Colors.white70,),
                        Expanded(child: Text('Verificação de Email', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),)),
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
                ],
              ),
            ),
            Expanded(
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 150),
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        _msg.isEmpty ? Container() : Center(child: Text(_msg, style: TextStyle(color: Colors.green), textAlign: TextAlign.center,),),
                        _msg.isEmpty ? Container() : SizedBox(height: 15,),
                        Text(
                          'Verifique seu email usando o link de verificação enviado para o email cadastrado. Isto é necessário para acessar sua conta e ajuda a evitar conta de spam. Faça login novamente depois de verificar seu email.',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.justify,
                        ),
                        SizedBox(height: 50,),
                        GestureDetector(
                          onTap:() async{
                            FirebaseUser user = Provider.of<FirebaseUser>(context, listen: false);
                            await user.sendEmailVerification().then((value) => setState(() {
                              _sent = true;

                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Verificação de email enviada com sucess.')
                                  )
                              );
                            }));
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                            decoration: BoxDecoration(
                                color: Colors.blue[400],
                                borderRadius: BorderRadius.all(Radius.circular(50))
                            ),
                            child: Text(_sent ? 'Reenviar' : 'Enviar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),),
                          ),
                        ),
                      ],
                    ),
                  )
              ),
            ),
          ],
        )
    );
  }
}
