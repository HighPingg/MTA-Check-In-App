import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScanner extends StatefulWidget {
  String course;

  QRScanner({super.key, required this.course});

  @override
  State<QRScanner> createState() => _QRScannerState(course);
}

class _QRScannerState extends State<QRScanner> {
  String course;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // Since controller.pauseCamera() doesn't work we use a bool flag to detect if user exited the dialog.
  bool enteredDialog = false;

  _QRScannerState(this.course);

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
        children: [
          Expanded(flex: 5, child: _buildQrView(context)),
          Expanded(flex: 1, child: Text("test"))
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          color: Colors.white,
          icon: const Icon(Icons.arrow_back)),
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
                onPressed: () {
                  setState(() {
                    enteredDialog = false;
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
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
