class Schedule {
  final String id;
  final String courseId;
  final String courseTitle;
  final String day;
  final String time;
  final String duration;
  final String teacher;
  final String type;
  final String venue;
  final String? meetingLink;

  Schedule({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.day,
    required this.time,
    required this.duration,
    required this.teacher,
    required this.type,
    required this.venue,
    this.meetingLink,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      day: json['day'] ?? '',
      time: json['time'] ?? '',
      duration: json['duration'] ?? '1 hour',
      teacher: json['teacher'] ?? '',
      type: json['type'] ?? 'physical',
      venue: json['venue'] ?? '',
      meetingLink: json['meetingLink'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'day': day,
      'time': time,
      'duration': duration,
      'teacher': teacher,
      'type': type,
      'venue': venue,
      'meetingLink': meetingLink,
    };
  }

  bool get isOnline => type == 'online';
  bool get isPhysical => type == 'physical';
}