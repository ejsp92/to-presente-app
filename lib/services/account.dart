import 'package:firebase_auth/firebase_auth.dart';

class Account {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final RegExp emailRegExp = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");

  Stream<FirebaseUser> get account {
    return _auth.onAuthStateChanged;
  }

  Future<FirebaseUser> register(email, pass) async{
    try
    {
      AuthResult account = await _auth.createUserWithEmailAndPassword(email: email, password: pass);
      return account.user;
    }
    catch(e)
    {
      print(e.toString());
      return null;
    }
  }

  Future<FirebaseUser> login(email, pass) async{
    try {
      AuthResult account = await _auth.signInWithEmailAndPassword(email: email, password: pass);
      return account.user;
    }
    catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future signOut() async{
    try{
      return await _auth.signOut();
    }
    catch(e){
      return null;
    }
  }

  Future delete() async{
    FirebaseUser user = await _auth.currentUser();
    await user.delete();
  }

  Future<String> resetPassword(oldPass, newPass) async{
    try{
      FirebaseUser user = await _auth.currentUser();
      AuthResult newAuth = await user.reauthenticateWithCredential(
        EmailAuthProvider.getCredential(
          email: user.email,
          password: oldPass,
        ),
      );
      await newAuth.user.updatePassword(newPass);
      return 'Success';
    }
    catch(e){
      print(e.toString());
      return null;
    }
  }

  String validateId(String id)
  {
    if(id.isEmpty) {
      return 'Email não pode ficar em branco';
    } else if (!emailRegExp.hasMatch(id)) {
      return 'Email deve ser válido';
    } else {
      return null;
    }
  }

  String validateRegisterPass(String pass)
  {
    if(pass.length < 6)
    {
      return "Senha não pode ter menos que 6 caracateres";
    }
    else
    {
      return null;
    }
  }

  String validateLoginPass(String pass)
  {
    if(pass.isEmpty)
    {
      return "Senha não pode ficar em branco";
    }
    else
    {
      return null;
    }
  }
}