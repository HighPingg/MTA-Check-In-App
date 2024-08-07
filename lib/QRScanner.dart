import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mta_check_in/CourseInterfaces.dart';
import 'package:mta_check_in/helperFuncs.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'package:http/http.dart' as http;

class QRScanner extends StatefulWidget {
  Course course;
  List<Student> students;

  QRScanner({super.key, required this.course, required this.students});

  @override
  State<QRScanner> createState() => _QRScannerState(course, students);
}

class _QRScannerState extends State<QRScanner> {
  Course course;
  List<Student> students;

  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  bool flashOn = false;

  // Since controller.pauseCamera() doesn't work we use a bool flag to detect if user exited the dialog.
  bool enteredDialog = false;

  _QRScannerState(this.course, this.students);

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
          body: Column(
            children: [Expanded(flex: 5, child: _buildQrView(context))],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.startDocked,
          floatingActionButton:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context, students);
                },
                color: Colors.white,
                icon: const Icon(Icons.arrow_back)),
            Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  color: flashOn ? Colors.white : null,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.all(30),
                child: IconButton(
                    onPressed: () async {
                      setState(() {
                        flashOn = !flashOn;
                      });

                      await controller!.toggleFlash();
                    },
                    color: flashOn ? Colors.black : Colors.white,
                    icon: const Icon(Icons.flashlight_on)))
          ]),
        ));
  }

  void _showAddStudentDialog(BuildContext context, String qrCode) async {
    // Search for student
    Student? foundStudent;
    for (Student student in students) {
      if (student.employeeId == qrCode) {
        foundStudent = student;
        break;
      }
    }

    if (foundStudent == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
              canPop: false,
              child: AlertDialog(
                  title: const Row(children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Not Found')
                  ]),
                  content: Container(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Student not found in class; ID:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(qrCode),
                      
                    ],
                  )),
                  actions: [
                    TextButton(
                      child: const Text('Add Student'),
                      onPressed:  () async {
                        try {
                          final response = await http.post(
                            Uri.parse('$BACKEND_URL/classes/${this.course.id}/students'),
                            headers: {
                              'Content-type': 'application/json'
                            },
                            body: jsonEncode(<String, String>{
                              'employee_id': qrCode
                            })
                          );
                          if(response.statusCode == 201) {
                            final responseData = json.decode(response.body);
                            String name = responseData['student_name'];
                            setState(() {
                              students.add(
                                  Student(name, qrCode, "Not checked in"));
                            });
                          } else if(response.statusCode == 404) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text("Student does not exist."),
                            ));
                          }
                        } catch(e) {
                          print(e.toString());
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text("Failed to add student."),
                          ));
                        }

                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Dismiss'),
                      onPressed: () {
                        setState(() {
                          enteredDialog = false;
                        });

                        Navigator.of(context).pop();
                      },
                    ),
                  ]));
        },
      );
    } else {
      try {
        final response = await http.get(Uri.parse('$BACKEND_URL/students/$qrCode'));

        String name;
        if(response.statusCode == 404) {
          name = "Unknown Student";
        } else if(response.statusCode == 200) {
          final responseData = json.decode(response.body);
          name = responseData['name'];
        } else {
          throw Exception();
        }
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return PopScope(
                canPop: false,
                child: AlertDialog(
                    title: Text('Check In Student?'),
                    content: Container(
                        child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(foundStudent!.employeeId),
                      ],
                    )),
                    actions: [
                      TextButton(
                        child: const Text('Ignore'),
                        onPressed: () {
                          setState(() {
                            enteredDialog = false;
                          });

                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            final response = await http.put(
                              Uri.parse('$BACKEND_URL/classes/${course.id}/students/${foundStudent!.employeeId}/status'),
                              headers: {
                                'Content-type': 'application/json'
                              },
                              body: jsonEncode(<String, String>{
                                'status': 'Completed'
                              })
                            );
                            
                            if(response.statusCode == 200) {
                              setState(() {
                                enteredDialog = false;

                                foundStudent!.status = "Completed";
                              });
                            } else {
                              throw Exception();
                            }
                          }catch(e){
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text("Failed to update status."),
                            ));
                          }

                          Navigator.of(context).pop();
                        },
                        child: const Text('Check In'),
                      ),
                    ]));
        },
      );
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("An unknown error occured, please try again."),
      ));
    }
  }
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;

    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && !enteredDialog) {
        setState(() {
          enteredDialog = true;
        });
        SchedulerBinding.instance.addPostFrameCallback((_) {
          String result = scanData.code.toString();
          _showAddStudentDialog(context, result);
        });
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      Navigator.pop(context, students);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
