import 'dart:convert';
import 'package:attendanceapp/services/account.dart';
import 'package:attendanceapp/services/database.dart';
import 'package:attendanceapp/services/ml_kit.dart';
import 'package:attendanceapp/services/camera.dart';
import 'package:attendanceapp/services/facenet.dart';
import 'package:attendanceapp/pages/components/formatting.dart';
import 'package:attendanceapp/pages/components/face_painter.dart';
import 'package:attendanceapp/pages/components/camera_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class Register extends StatefulWidget {
  final ValueChanged<bool> updateFragment;
  Register(this.updateFragment);
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final Account _account = Account();
  final _formKey = GlobalKey<FormState>();

  String userEmail, userPass, userFirstName, userLastName, teacherEmail, studentFaceId;
  String type = '';
  List<String> _types = ['', 'Professor', 'Estudante'];
  bool loading = false;
  String errorMsg = '';
  int _currentFragment = 0;

  String imagePath;
  Face faceDetected;
  Size imageSize;

  bool _detectingFaces = false;

  Future _initializeControllerFuture;
  bool cameraInitialized = false;
  CameraDescription cameraDescription;

  // switchs when the user press the camera
  bool _cameraVisible = false;
  bool _savingFace = false;

  // service injection
  MLKitService _mlKitService = MLKitService();
  CameraService _cameraService = CameraService();
  FaceNetService _faceNetService = FaceNetService();

  @override
  void initState() {
    super.initState();
    _currentFragment = 0;
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    if (_cameraService != null) _cameraService.dispose();
    super.dispose();
  }

  /// starts the camera & start framing faces
  _startCamera() async {
    setState(() {
      errorMsg = '';
      loading = true;
    });

    if (!cameraInitialized) {
      _faceNetService.loadModel();
      _mlKitService.initialize();

      if (cameraDescription == null) {
        List<CameraDescription> cameras = await availableCameras();

        /// takes the front camera
        cameraDescription = cameras.firstWhere(
              (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
        );
      }

      _initializeControllerFuture =
          _cameraService.startService(cameraDescription);
      await _initializeControllerFuture;

      setState(() {
        cameraInitialized = true;
      });

      _frameFaces();
    }

    setState(() {
      loading = false;
      _cameraVisible = true;
    });
  }

  Future<bool> onTakePicture() async {
    if (faceDetected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Nenhum rosto detectado. Centralize seu rosto na camera e tente novamente.')
          )
      );

      return false;
    } else {
      _savingFace = true;
      await Future.delayed(Duration(milliseconds: 500));
      await _cameraService.cameraController.stopImageStream();
      await Future.delayed(Duration(milliseconds: 200));
      XFile file = await _cameraService.takePicture();
      imagePath = file.path;

      return true;
    }
  }

  /// draws rectangles when detects faces
  _frameFaces() {
    imageSize = _cameraService.getImageSize();

    _cameraService.cameraController.startImageStream((image) async {
      if (_cameraService.cameraController != null) {
        // if its currently busy, avoids overprocessing
        if (_detectingFaces) return;

        _detectingFaces = true;

        try {
          List<Face> faces = await _mlKitService.getFacesFromImage(image);

          if (faces.length > 0) {
            setState(() {
              faceDetected = faces[0];
            });

            if (_savingFace) {
              _faceNetService.setCurrentPrediction(image, faceDetected);
              setState(() {
                studentFaceId = json.encode(_faceNetService.predictedData);
                _savingFace = false;
              });
              _closeCamera();
            }
          } else {
            setState(() {
              faceDetected = null;
            });
          }

          _detectingFaces = false;
        } catch (e) {
          print(e);
          _detectingFaces = false;
        }
      }
    });
  }

  _cancelCamera() async {
    if (_cameraService != null && _cameraService.cameraController != null ) {
      await _cameraService.cameraController.stopImageStream();
    }
    _closeCamera();
  }

  _closeCamera() {
    setState(() {
      _cameraVisible = false;
      cameraInitialized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _cameraVisible ? _camera() : _registration();
  }

  Widget _camera() {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        body: Stack(
          children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Transform.scale(
                    scale: 1.0,
                    child: AspectRatio(
                      aspectRatio: MediaQuery.of(context).size.aspectRatio,
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Container(
                            width: width,
                            height: width *
                                _cameraService
                                    .cameraController.value.aspectRatio,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                CameraPreview(
                                    _cameraService.cameraController),
                                CustomPaint(
                                  painter: FacePainter(
                                      face: faceDetected,
                                      imageSize: imageSize),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
            CameraHeader(
              'IDENTIFICAÇÃO FACIAL',
              onBackPressed: _cancelCamera,
            )
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: GestureDetector(
          onTap: () async {
            try {
              // Ensure that the camera is initialized.
              await _initializeControllerFuture;
              // onShot event (takes the image and predict output)
              await onTakePicture();
            } catch (e) {
              // If an error occurs, log the error to the console.
              print(e);
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
              child: Text("Capturar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 17),),
            ),
          ),
        )
    );
  }

  Widget _registration() {
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
              child: Text('Cadastrar.', style: TextStyle(color: Colors.white, fontSize: 50, letterSpacing: 2, fontWeight: FontWeight.bold),),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(38, 0, 15, 0),
              child: Text('Seja bem-vindo!', style: TextStyle(color: Colors.white, fontSize: 22,),),
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
                    loading ? AuthLoading(185, 20) : _form(),
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

  Widget _form() {
    Widget currentForm;
    if (_currentFragment == 1) {
      currentForm = _registerPasswordType();
    } else if (_currentFragment == 2) {
      currentForm = _registerFaceId();
    } else {
      currentForm = _registerNameEmail();
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 45, 0, 5),
          child: currentForm,
        ),
        SizedBox(height: 30,),
        GestureDetector(
          onTap: () => widget.updateFragment(true),
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
                color: Color.fromRGBO(66, 165, 245, 0.3),
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
                      _currentFragment = 2;
                    });
                  } else {
                    setState(() {
                      errorMsg = '';
                      _currentFragment = 1;
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
                    initialValue: teacherEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: authInputFormatting.copyWith(hintText: "Email do professor"),
                    validator: _account.validateId,
                    onChanged: (val) {
                      teacherEmail = val;
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    _startCamera();
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
                            child: Text("Registrar identificação facial", style: Theme.of(context).textTheme.bodyText1.copyWith(color: studentFaceId == null || studentFaceId.isEmpty ? Colors.grey[400] : Colors.blue[400]),),
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
                      _currentFragment = 0;
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
                          errorMsg = 'Registre sua identificação facial antes de continuar';
                        });
                        return;
                      }

                      setState(() {
                        errorMsg = '';
                        loading = true;
                      });

                      Student student = Student();
                      String result = await student.addStudent(teacherEmail, userFirstName, userLastName, userEmail, studentFaceId);
                      if (result != null) {
                        if(result == 'Success'){
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Seu cadastro foi enviado ao professor.')
                              )
                          );

                          widget.updateFragment(true);
                        } else if (result == 'Teacher not found') {
                          setState(() {
                            loading = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Não existe um professor com o email informado na base de dados.')
                              )
                          );
                        }
                      } else {
                        setState(() {
                          loading = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Não foi possível adicionar os dados do usuário na base de dados. Tente novamente.')
                            )
                        );
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
                      _currentFragment = 0;
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

                      String userType = 'teacher';
                      FirebaseUser user = await _account.register(userEmail, userPass);
                      if (user != null) {
                        User userData = User(user) ;
                        String result = await userData.addUserData(userFirstName, userLastName, userType);
                        bool isEmailVerified = user.isEmailVerified;
                        if (result != null) {
                          String type = await userData.userType();
                          if(type != null){
                            Navigator.of(context)..pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false, arguments: {'type' : type, 'isEmailVerified' : isEmailVerified});
                          } else{
                            await _account.signOut();
                            setState(() {
                              loading = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Não foi possível identificar o tipo de usuário. Tente novamente.')
                                )
                            );
                          }
                        } else {
                          await _account.delete();
                          setState(() {
                            loading = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Não foi possível salvar os dados do usuário. Tente novamente.')
                              )
                          );
                        }
                      } else {
                        setState(() {
                          loading = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Email é inválido ou usuário já existe. Por favor, informe um email válido.')
                            )
                        );
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

