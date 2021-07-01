import 'dart:convert';

import 'package:attendanceapp/services/account.dart';
import 'package:attendanceapp/services/database.dart';
import 'package:attendanceapp/services/ml_kit.dart';
import 'package:attendanceapp/services/camera.dart';
import 'package:attendanceapp/services/facenet.dart';
import 'package:attendanceapp/pages/components/face_painter.dart';
import 'package:attendanceapp/pages/components/camera_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class CaptureAttendance extends StatefulWidget {
  @override
  _CaptureAttendanceState createState() => _CaptureAttendanceState();
}

class _CaptureAttendanceState extends State<CaptureAttendance> {
  bool _chooseClass = true;
  DateTime _current = DateTime.now();
  String _date = '';
  String _start = '';
  String _end = '';
  String _subject, _batch;
  String _errorMsg = '';
  List<Map> _enrolledStudents = [];
  Map _enrolledStudentsMap = {};
  Map _faceIds = {};
  Map _attendance = {};
  TeacherSubjectsAndBatches _tSAB;

  String imagePath;
  Face faceDetected;
  Size imageSize;

  bool _detectingFaces = false;
  bool _addingAttendance = false;

  Future _initializeControllerFuture;
  bool cameraInitialized = false;
  bool attendanceInitialized = false;
  CameraDescription cameraDescription;

  // service injection
  MLKitService _mlKitService = MLKitService();
  CameraService _cameraService = CameraService();
  FaceNetService _faceNetService = FaceNetService();

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    if (_cameraService != null) _cameraService.dispose();
    super.dispose();
  }

  /// starts the camera & start framing faces
  _startCamera() async {
    if (!attendanceInitialized) await _initAttendance();
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
  }

  /// draws rectangles when detects faces
  _frameFaces() {
    imageSize = _cameraService.getImageSize();

    _cameraService.cameraController.startImageStream((image) async {
      if (_cameraService.cameraController != null) {
        // if its currently busy, avoids overprocessing
        if (_detectingFaces || _addingAttendance) return;

        _detectingFaces = true;

        try {
          List<Face> faces = await _mlKitService.getFacesFromImage(image);

          if (faces.length > 0) {
            setState(() {
              faceDetected = faces[0];
            });

            _faceNetService.setCurrentPrediction(image, faceDetected);
            String studentEmail = _faceNetService.predict(_faceIds);

            if (studentEmail != null) {
              _addingAttendance = true;
              _addAttendance(studentEmail);
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
      cameraInitialized = false;
    });

    Navigator.pop(context);
  }

  _initAttendance() async {
    try {
      String dateTime = '$_date $_start - $_end';
      await _tSAB.addAttendance(_subject, _batch, dateTime, _attendance);
    } catch (e) {
      print(e);
    } finally {
      attendanceInitialized = true;
    }
  }

  _addAttendance(String studentEmail) async {
    String studentName = _enrolledStudentsMap[studentEmail]['firstName'];

    try {
      if (_attendance[studentEmail]) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Olá, ${studentName}!\nSua presença já foi registrada.')
            )
        );
      } else {
        _attendance[studentEmail] = true;
        String dateTime = '$_date $_start - $_end';
        dynamic result = await _tSAB.addAttendance(
            _subject, _batch, dateTime, _attendance);
        if (result == null) {
          _attendance[studentEmail] = false;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Algo deu errado, tente novamente.')
              )
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Olá, ${studentName}!\nSua presença foi registrada com sucesso.')
              )
          );
        }
      }
    } catch (e) {
      print(e);
      _attendance[studentEmail] = false;
    } finally {
      await Future.delayed(Duration(milliseconds: 5000));
      _addingAttendance = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Map data = ModalRoute.of(context).settings.arguments;
    _subject = data['subject'];
    _batch = data['batch'];
    _enrolledStudents = data['enrolledStudents'];
    _tSAB = TeacherSubjectsAndBatches(Provider.of<FirebaseUser>(context));

    _date = _date.isEmpty ? '${_current.day.toString().padLeft(2, '0')}/${_current.month.toString().padLeft(2, '0')}/${_current.year}' : _date;
    _enrolledStudentsMap = _enrolledStudentsMap.isEmpty ? Map.fromIterable(_enrolledStudents, key: (student) => student['email'], value: (student) => student) : _enrolledStudentsMap;
    _faceIds = _faceIds.isEmpty ? Map.fromIterable(_enrolledStudents, key: (student) => student['email'], value: (student) => json.decode(student['faceId']) ) : _faceIds;
    _attendance = _attendance.isEmpty ? Map.fromIterable(_enrolledStudents, key: (student) => student['email'], value: (student) => false ) : _attendance;

    if (_chooseClass) return chooseClassDuration();
    else return captureAttendance();
  }

  Widget chooseClassDuration(){
    dynamic fieldTextStyle = TextStyle(color: Colors.blue[400], fontSize: 17, fontWeight: FontWeight.w400);
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
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
                      Expanded(child: Text('Horário da Aula', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),)),
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
              ],
            ),
          ),
          SizedBox(height: 5,),
          Expanded(
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
                    margin: EdgeInsets.fromLTRB(20, 100, 20, 25),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 5, 0, 5),
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.calendar_today,),
                              SizedBox(width: 20,),
                              Expanded(child: _date.isEmpty ? Text('Data da Aula', style: fieldTextStyle,) : Text('$_date', style: fieldTextStyle)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 5, 0, 5),
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.access_time,),
                              SizedBox(width: 20,),
                              Expanded(child: _start.isEmpty ? Text('Início', style: fieldTextStyle,) : Text('$_start', style: fieldTextStyle,)),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.grey[700],),
                                onPressed: (){
                                  DatePicker.showTime12hPicker(
                                    context,
                                    theme: DatePickerTheme(containerHeight: 300, backgroundColor: Colors.white,),
                                    showTitleActions: true,
                                    onConfirm: (time) {
                                      setState(() {
                                        _start = time.toString().substring(11,16);
                                      });
                                    }, locale: LocaleType.pt,
                                  );
                                },
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 5, 0, 5),
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.access_time,),
                              SizedBox(width: 20,),
                              Expanded(child: _end.isEmpty ? Text('Fim', style: fieldTextStyle,) : Text('$_end', style: fieldTextStyle,)),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.grey[700],),
                                onPressed: (){
                                  DatePicker.showTime12hPicker(
                                    context,
                                    theme: DatePickerTheme(containerHeight: 240, backgroundColor: Colors.white,),
                                    showTitleActions: true,
                                    onConfirm: (time) {
                                      setState(() {
                                        _end = time.toString().substring(11,16);
                                      });
                                    }, locale: LocaleType.pt,
                                  );
                                },
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _errorMsg.isEmpty ? Container() :  Text(_errorMsg, style: TextStyle(color: Colors.red),),
                  _errorMsg.isEmpty ? Container() :  SizedBox(height: 20,),
                  Container(
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                        if(_date.isNotEmpty && _start.isNotEmpty && _start.isNotEmpty) {
                          setState(() {
                            _chooseClass = false;
                            _errorMsg = '';
                          });

                          _startCamera();
                        } else {
                          setState(() {
                            _errorMsg = 'Todos os campos são obrigatórios.';
                          });
                        }
                      },
                      child: Container(
                        height: 50,
                        margin: EdgeInsets.symmetric(horizontal: 70),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Colors.blue[400],
                        ),
                        child: Center(
                          child: Text('Capturar',style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 17),),
                        ),
                      ),
                    ),
                  ),
                ],
              )
          ),
        ],
      ),
    );
  }

  Widget captureAttendance(){
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
              'CAPTURA DE PRESENÇA',
              onBackPressed: _cancelCamera,
            )
          ],
        ),
    );
  }
}
