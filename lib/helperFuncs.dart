import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Row displayLineItem(Icon icon, String label, String text) {
  return Row(children: [
    icon,
    const SizedBox(width: 5),
    Text(label + ":",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(width: 5),
    Text(text, style: const TextStyle(fontSize: 18))
  ]);
}

Icon statusIcon(String status) {
  if (status == "Not checked in") {
    return const Icon(Icons.circle, color: Colors.yellow);
  } else if (status == "Completed") {
    return const Icon(Icons.check_circle, color: Colors.green);
  } else {
    return const Icon(Icons.cancel, color: Colors.red);
  }
}

Future<String> getExternalDocumentPathHelp() async { 
    var status = await Permission.storage.status; 
    if (!status.isGranted) { 
      await Permission.storage.request(); 
    } 
    Directory _directory = Directory(""); 
    if (Platform.isAndroid) { 
      _directory = Directory("/storage/emulated/0/Download"); 
    } else { 
      _directory = await getApplicationDocumentsDirectory(); 
    } 
  
    final exPath = _directory.path; 
    await Directory(exPath).create(recursive: true); 
    return exPath; 
  }