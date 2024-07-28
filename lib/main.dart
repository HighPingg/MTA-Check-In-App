import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ClassRoster.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const String _title = 'MTA Check In App';
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      title: _title,
      theme: ThemeData(
        // useMaterial3: false,
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

final TimeOfDay _timeNow = TimeOfDay.now();
final DateTime _dateNow = DateTime.now();

class _MyHomePageState extends State<MyHomePage> {
  Set<String> courses = {};

  final _dateController =
      TextEditingController(text: _dateNow.toString().split(" ")[0]);
  final _timeController =
      TextEditingController(text: "${_timeNow.hour}:${_timeNow.minute}");

  @override
  void initState() {
    super.initState();

    loadCourses();
  }

  // Load course list onto courses array.
  void loadCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? courses = prefs.getStringList('courses');
    if (courses != null) {
      setState(() {
        this.courses = courses.toSet();
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
          )),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: courses.map((course) {
            return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ClassRoster(course: course)),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  width: double.infinity,
                  child:
                      Text(course.toString(), style: TextStyle(fontSize: 18)),
                ));
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCourseDialog(context);
        },
        tooltip: 'New Class',
        backgroundColor: const Color(0xff0039a6),
        foregroundColor: const Color(0xffffffff),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context) {
    final nameFieldController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Class'),
          content: Container(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameFieldController,
                decoration: InputDecoration(hintText: "Class name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _dateController,
                decoration: InputDecoration(
                    labelText: "Date",
                    filled: true,
                    prefixIcon: Icon(Icons.calendar_today),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: const Color(0xff0039a6)))),
                readOnly: true,
                onTap: () {
                  _displayDatePicker();
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _timeController,
                decoration: InputDecoration(
                    labelText: "Time",
                    filled: true,
                    prefixIcon: Icon(Icons.lock_clock),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: const Color(0xff0039a6)))),
                readOnly: true,
                onTap: () {
                  _displayTimePicker();
                },
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
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String newClass =
                    "${nameFieldController.text} - ${_dateController.text} @ ${_timeController.text}";

                Set<String> addedCourses = Set<String>.from(courses)
                  ..add(newClass);

                prefs.setStringList("courses", addedCourses.toList());
                setState(() {
                  courses = addedCourses;
                });

                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _displayDatePicker() async {
    DateTime? _pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateNow,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (_pickedDate != null) {
      setState(() {
        _dateController.text = _pickedDate.toString().split(" ")[0];
      });
    }
  }

  Future<void> _displayTimePicker() async {
    TimeOfDay? time =
        await showTimePicker(context: context, initialTime: _timeNow);

    if (time != null) {
      setState(() {
        _timeController.text = "${time.hour}:${time.minute}";
      });
    }
  }
}
