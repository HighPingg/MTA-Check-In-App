import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRScanner extends StatefulWidget {
  String course;
  List<String> students;

  QRScanner({super.key, required this.course, required this.students});

  @override
  State<QRScanner> createState() => _QRScannerState(course, students);
}

class _QRScannerState extends State<QRScanner> {
  String course;
  List<String> students;

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
    return Scaffold(
      body: Column(
        children: [Expanded(flex: 5, child: _buildQrView(context))],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startDocked,
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
            margin: EdgeInsets.all(30),
            child: IconButton(
                onPressed: () async {
                  setState(() {
                    flashOn = !flashOn;
                  });

                  await controller!.toggleFlash();
                },
                color: flashOn ? Colors.black : Colors.white,
                icon: Icon(Icons.flashlight_on)))
      ]),
    );
  }

  void _showAddStudentDialog(BuildContext context, String QRCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('New Student'),
            content: Container(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text(QRCode)],
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
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();

                  String newStudent = QRCode;
                  List<String> addedStudents = List<String>.from(students)
                    ..add(newStudent);

                  prefs.setStringList(course, addedStudents);

                  setState(() {
                    enteredDialog = false;
                    students = addedStudents;
                  });

                  Navigator.of(context).pop();
                },
                child: Text('Add'),
              ),
            ]);
      },
    );
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
