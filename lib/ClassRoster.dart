import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:mta_check_in/CourseInterfaces.dart';
import 'package:mta_check_in/QRScanner.dart';
import 'package:mta_check_in/helperFuncs.dart';

class ClassRoster extends StatefulWidget {
  Course course;

  ClassRoster({super.key, required this.course});

  @override
  State<ClassRoster> createState() => _ClassRosterState(course);
}

class _ClassRosterState extends State<ClassRoster> {
  List<Student> students = [];
  Course course;
  String err = '';

  _ClassRosterState(this.course);

  @override
  void initState() {
    super.initState();

    loadCourse(course.id);
  }

  // Load course list onto courses array.
  void loadCourse(String courseId) async {
    try {
      final response =
          await http.get(Uri.parse('$BACKEND_URL/classes/$courseId'));

      final responseData = json.decode(response.body);
      Course courseData = Course.fromJSON(responseData);

      List<Student> studentData = [];
      for (var student in responseData['students']) {
        studentData.add(Student.fromJSON(student));
      }

      setState(() {
        students = studentData;
        course = courseData;
      });
    } catch (error) {
      setState(() {
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
                    onPressed: () async {
                      // Write data to temp file
                      final path = await getExternalDocumentPathHelp();
                      String filePath = '$path/${course.id}.csv';

                      if (!await _showSaveFileDialog(context, filePath)) return;

                      File file = File(filePath);

                      String writeString = "Name,Employee Id,Status\n";
                      for (Student student in students) {
                        writeString += "${student.toString()}\n";
                      }

                      await file.writeAsString(writeString);
                    },
                    tooltip: "Share",
                    icon: const Icon(Icons.ios_share)))
          ],
        ),
        body: err == ""
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    Text(course.name,
                        style: const TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            displayLineItem(const Icon(Icons.event), "Date",
                                course.date.toString()),
                            const SizedBox(height: 8),
                            displayLineItem(const Icon(Icons.schedule), "Time",
                                course.time.toString()),
                            const SizedBox(height: 8),
                            displayLineItem(const Icon(Icons.person),
                                "Instructor", course.instructor),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            displayLineItem(const Icon(Icons.meeting_room),
                                "Room", course.room),
                            const SizedBox(height: 8),
                            displayLineItem(const Icon(Icons.code),
                                "Course Code", course.courseCode),
                          ],
                        )
                      ],
                    ),
                    Text(course.id),
                    Column(
                        children: students.map((student) {
                      return Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              color: student.status == "Not checked in"
                                  ? Colors.grey
                                  : Colors.transparent),
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.all(10),
                          width: double.infinity,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("NAME",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    displayLineItem(const Icon(Icons.person),
                                        "Employee ID", student.employeeId),
                                    Row(
                                      children: [
                                        statusIcon(student.status),
                                        const SizedBox(width: 5),
                                        Text(student.status),
                                      ],
                                    ),
                                  ],
                                ),
                                student.status != "Not checked in"
                                    ? Column(
                                        children: [
                                          const Text("Fail"),
                                          Checkbox(
                                            value: student.status == "Failed"
                                                ? true
                                                : false,
                                            fillColor:
                                                WidgetStateProperty.resolveWith(
                                                    (states) {
                                              if (states.contains(
                                                  WidgetState.selected)) {
                                                return const Color(0xff0039a6);
                                              }
                                            }),
                                            onChanged: (bool? value) {
                                              setState(() {
                                                student.status = value == true
                                                    ? "Failed"
                                                    : "Completed";
                                              });
                                            },
                                          )
                                        ],
                                      )
                                    : const SizedBox()
                              ]));
                    }).toList()),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                            style: ButtonStyle(
                              foregroundColor:
                                  WidgetStateProperty.resolveWith((states) {
                                return const Color(0xff0039a6);
                              }),
                              overlayColor:
                                  WidgetStateProperty.resolveWith((states) {
                                return Color.fromARGB(12, 0, 58, 166);
                              }),
                            ),
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
                            child: const Row(children: [
                              Icon(Icons.qr_code_scanner),
                              SizedBox(width: 10),
                              Text('Scan')
                            ])),
                        OutlinedButton(
                            style: ButtonStyle(
                              foregroundColor:
                                  WidgetStateProperty.resolveWith((states) {
                                return const Color(0xff0039a6);
                              }),
                              overlayColor:
                                  WidgetStateProperty.resolveWith((states) {
                                return Color.fromARGB(12, 0, 58, 166);
                              }),
                            ),
                            onPressed: () {
                              _showAddStudentDialog(context);
                            },
                            child: const Row(children: [
                              Icon(Icons.edit),
                              SizedBox(width: 10),
                              Text('Manual')
                            ]))
                      ],
                    )
                  ],
                ),
              )
            : Text(err));
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameFieldController = TextEditingController();
    final emplIdFieldController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: const Text('Add Student'),
            content: Container(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameFieldController,
                  decoration: const InputDecoration(hintText: "Student name"),
                ),
                TextField(
                  controller: emplIdFieldController,
                  decoration: const InputDecoration(hintText: "Employee ID"),
                  // keyboardType: TextInputType.number,
                  // inputFormatters: <TextInputFormatter>[
                  //   FilteringTextInputFormatter.digitsOnly
                  // ],
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
                  setState(() {
                    students.add(
                        Student(emplIdFieldController.text, "Not checked in"));
                  });

                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ]);
      },
    );
  }

  Future<bool> _showSaveFileDialog(
      BuildContext context, String filePath) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return PopScope(
            canPop: false,
            child: AlertDialog(
                title: const Text('Save File'),
                content: RichText(
                  text: TextSpan(
                      text: "Save file to ",
                      style: TextStyle(color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                            text: filePath,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        const TextSpan(
                            text: "?", style: TextStyle(color: Colors.black))
                      ]),
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop(true);
                    },
                    child: Text('OK'),
                  ),
                ]));
      },
    );
  }
}
