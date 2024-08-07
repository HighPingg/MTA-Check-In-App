class Course {
  String name;
  String date;
  String time;
  String instructor;
  String id;
  String room;
  String courseCode;

  Course(this.name, this.date, this.time, this.instructor, this.id, this.room,
      this.courseCode);

  Course.fromJSON(Map<String, dynamic> json)
      : name = json['name'] as String,
        date = json['date'] as String,
        time = json['time'] as String,
        instructor = json['instructor'] as String,
        id = json['id'] as String,
        room = json['room'] as String,
        courseCode = json['course_code'] as String;

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': date,
        'time': time,
        'instructor': instructor,
        'id': id,
        'room': room,
        'courseCode': courseCode,
      };

  @override
  String toString() {
    return "$name,$date,$time,$instructor,$id,$room,$courseCode";
  }

  static Course fromString(String string) {
    final splittedString = string.split(",");

    return Course(
        splittedString[0],
        splittedString[1],
        splittedString[2],
        splittedString[3],
        splittedString[4],
        splittedString[5],
        splittedString[6]);
  }
}

class Student {
  // String name;
  String employeeId;
  String status;
  String name;

  Student(this.name, this.employeeId, this.status);

  Student.fromJSON(Map<String, dynamic> json)
      :
        // name = json['name'] as String,
        employeeId = json['employee_id'] as String,
        status = json['status'] as String,
        name = json['name'] as String;

  Map<String, dynamic> toJSON() => {
        'name': name,
        'employee_id': employeeId, 'status': status
      };

  @override
  String toString() {
    return "$name,$employeeId,$status";
  }

  static Student fromString(String string) {
    final splittedString = string.split(",");

    return new Student(splittedString[0], splittedString[1], splittedString[2]);
  }
}

const BACKEND_URL = 'https://mtademo.shivpurohit.com';
