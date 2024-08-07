import 'package:flutter/material.dart';

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
