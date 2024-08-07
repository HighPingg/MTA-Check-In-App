import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mta_check_in/CourseInterfaces.dart'
import 'package:mta_check_in/QRScanner.dart';

class ClassRoster extends StatefulWidget {
  String courseId;

  ClassRoster({super.key, required this.courseId});

  @override
  State<ClassRoster> createState() => _ClassRosterState(courseId);
}

class _ClassRosterState extends State<ClassRoster> {
  String courseId;
  List<String> students = [];

  _ClassRosterState(this.courseId);

  @override
  void initState() {
    super.initState();

    loadCourse(courseId);
  }

  // Load course list onto courses array.
  void loadCourse(String courseId) async {
    try {
      final response = await http.get(Uri.parse('$BACKEND_URL/classes/$courseId'));

      final responseData = json.decode(response.body);
      List<Course> courseList = [];
      for (var course in responseData) {
        courseList.add(Course.fromJSON(course));
      }

      setState(() {
        courses = courseList;
      });

    } catch (error) {
      setState(() {
        courses = null;
        err = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.height * 0.1,
        backgroundColor: const Color(0xff0039a6),
        foregroundColor: const Color(0xffffffff),
        centerTitle: false,
        title: Container(
          height: MediaQuery.of(context).size.height * 0.05,
          child: Row(children: [
            Image.asset("lib/assets/MTA_NYC_logo.png", fit: BoxFit.fitHeight),
            Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                child: const Text(
                  "Check In",
                  style: TextStyle(fontWeight: FontWeight.bold),
                )),
          ]),
        ),
        actions: [
          Container(
              margin: const EdgeInsets.all(10),
              child: IconButton(
                  onPressed: () {},
                  tooltip: "Delete Course",
                  icon: const Icon(Icons.delete)))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(course,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            Column(
                children: students.map((student) {
              return Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: const BorderRadius.all(Radius.circular(10))),
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.all(10),
                width: double.infinity,
                child: Text(student.toString(), style: TextStyle(fontSize: 18)),
              );
            }).toList()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                    onPressed: () async {
                      final returnedStudents = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => QRScanner(
                                  course: course, students: students)));

                      setState(() {
                        students = returnedStudents;
                      });
                    },
                    child: Row(children: [
                      Icon(Icons.qr_code_scanner),
                      SizedBox(width: 10),
                      Text('Scan')
                    ])),
                OutlinedButton(
                    onPressed: () {
                      _showAddStudentDialog(context);
                    },
                    child: Row(children: [
                      Icon(Icons.edit),
                      SizedBox(width: 10),
                      Text('Manual')
                    ]))
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameFieldController = TextEditingController();
    final bscFieldController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Add Student'),
            content: Container(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameFieldController,
                  decoration: InputDecoration(hintText: "Student name"),
                ),
                TextField(
                  controller: bscFieldController,
                  decoration: InputDecoration(hintText: "BSC ID"),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
              ],
            )),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                onPressed: () async {
                  // SharedPreferences prefs =
                  //     await SharedPreferences.getInstance();

                  // String newStudent =
                  //     "${nameFieldController.text} - ${bscFieldController.text}";
                  // List<String> addedStudents = List<String>.from(students)
                  //   ..add(newStudent);

                  // prefs.setStringList(course, addedStudents);
                  // setState(() {
                  //   students = addedStudents;
                  // });

                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ]);
      },
    );
  }
}
