import 'package:flutter/material.dart';
import 'package:gmi_learning_app/models/providers/app_data_provider.dart' show AppDataProvider;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
// ✅ THIS WAS MISSING!
import '../models/schedule.dart';

class MyClassesScreen extends StatefulWidget {
  const MyClassesScreen({super.key});

  @override
  State<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm').format(DateTime.now());
      _currentDate = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());
    });
  }

  List<Schedule> _getMySchedule(AppDataProvider provider) {
    List<Schedule> schedule = [];
    final days = ['Monday', 'Wednesday', 'Friday'];
    final times = ['08:00', '10:00', '14:00'];

    for (var course in provider.enrolledCourses) {
      final isOnline = course['type'] == 'Online';
      for (int i = 0; i < 3; i++) {
        schedule.add(Schedule(
          id: '${course['id']}_$i',
          courseId: course['id'].toString(),
          courseTitle: course['title'],
          day: days[i % days.length],
          time: times[i % times.length],
          duration: '2 hours',
          teacher: course['teacher'] ?? 'GMI Teacher',
          type: isOnline ? 'online' : 'physical',
          venue: isOnline ? 'Google Meet' : 'GMI Campus',
          meetingLink:
              isOnline ? 'https://meet.google.com/${course['id']}-$i' : null,
        ));
      }
    }
    return schedule;
  }

  bool _isClassHappeningNow(Schedule schedule) {
    final now = DateTime.now();
    try {
      final classTime = DateFormat('HH:mm').parse(schedule.time);
      final classStart = DateTime(
        now.year,
        now.month,
        now.day,
        classTime.hour,
        classTime.minute,
      );
      final classEnd = classStart.add(const Duration(minutes: 90));
      final fifteenMinBefore = classStart.subtract(const Duration(minutes: 15));
      return now.isAfter(fifteenMinBefore) && now.isBefore(classEnd);
    } catch (e) {
      return false;
    }
  }

  bool _isClassStartingSoon(Schedule schedule) {
    final now = DateTime.now();
    try {
      final classTime = DateFormat('HH:mm').parse(schedule.time);
      final classStart = DateTime(
        now.year,
        now.month,
        now.day,
        classTime.hour,
        classTime.minute,
      );
      final diff = classStart.difference(now);
      return diff.inMinutes <= 15 && diff.inMinutes > 0;
    } catch (e) {
      return false;
    }
  }

  void _joinOnlineClass(String link) async {
    if (await canLaunchUrl(Uri.parse(link))) {
      await launchUrl(Uri.parse(link));
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Cannot open link: $link'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _openLocation(String venue) async {
    final query = Uri.encodeComponent(venue);
    final url = 'https://www.google.com/maps/search/$query';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot open maps'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppDataProvider>(context);
    final mySchedule = _getMySchedule(provider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Classes'),
          backgroundColor: const Color(0xFF1A3A5C),
          bottom: const TabBar(
            tabs: [
              Tab(text: '📅 Today', icon: Icon(Icons.today)),
              Tab(text: '📚 All Classes', icon: Icon(Icons.calendar_month)),
              Tab(text: '📊 Schedule', icon: Icon(Icons.schedule)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _updateTime(),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A3A5C), Color(0xFF2C5F8A)],
            ),
          ),
          child: provider.enrolledCourses.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                  children: [
                    _buildTodayClasses(mySchedule),
                    _buildAllClasses(mySchedule),
                    _buildWeeklySchedule(mySchedule),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'No Enrolled Courses',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'You haven\'t enrolled in any courses yet.\nGo to Courses and enroll to see your schedule!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/courses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0C040),
                foregroundColor: Colors.black,
              ),
              child: const Text('Browse Courses'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayClasses(List<Schedule> schedule) {
    final today = DateFormat('EEEE').format(DateTime.now());
    final todayClasses = schedule.where((s) => s.day == today).toList();
    final liveClasses =
        todayClasses.where((s) => _isClassHappeningNow(s)).toList();

    if (todayClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.free_breakfast,
                size: 80, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'No Classes Today! 🎉',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enjoy your day off!',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentDate,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(
                      '⏰ $_currentTime • ${todayClasses.length} class(es) today',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                if (liveClasses.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${liveClasses.length} LIVE',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (liveClasses.isNotEmpty) ...[
            const Text('🔴 LIVE CLASSES',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 8),
            ...liveClasses.map((s) => _buildScheduleCard(s, isLive: true)),
            const SizedBox(height: 16),
          ],
          const Text('📅 Today\'s Schedule',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: todayClasses.length,
              itemBuilder: (context, index) =>
                  _buildScheduleCard(todayClasses[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllClasses(List<Schedule> schedule) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: schedule.length,
        itemBuilder: (context, index) => _buildScheduleCard(schedule[index]),
      ),
    );
  }

  Widget _buildWeeklySchedule(List<Schedule> schedule) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final today = DateFormat('EEEE').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Weekly Schedule',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isToday = day == today;
                final dayClasses = schedule.where((s) => s.day == day).toList();
                final hasLive = dayClasses.any((s) => _isClassHappeningNow(s));

                if (dayClasses.isEmpty && !isToday) {
                  return const SizedBox.shrink();
                }

                return Card(
                  color: isToday
                      ? const Color(0xFFF0C040).withValues(alpha: 0.2)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: isToday
                            ? const Color(0xFFF0C040)
                            : Colors.transparent,
                        width: 2),
                  ),
                  child: ExpansionTile(
                    leading: isToday
                        ? Icon(hasLive ? Icons.live_tv : Icons.today,
                            color:
                                hasLive ? Colors.red : const Color(0xFFF0C040))
                        : null,
                    title: Row(
                      children: [
                        Text(day,
                            style: TextStyle(
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        if (isToday && hasLive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Text('🔴 LIVE',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ],
                        if (isToday && !hasLive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF0C040),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Text('Today',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ),
                        ],
                        const Spacer(),
                        Text(
                            '${dayClasses.length} class${dayClasses.length > 1 ? 'es' : ''}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    children: dayClasses.isEmpty
                        ? [
                            const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('No classes',
                                    style: TextStyle(color: Colors.grey)))
                          ]
                        : dayClasses.map((s) => _buildScheduleItem(s)).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule, {bool isLive = false}) {
    final isStartingSoon = _isClassStartingSoon(schedule);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLive ? Colors.red : Colors.transparent,
          width: isLive ? 3 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.red
                        : schedule.isOnline
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLive
                            ? Icons.live_tv
                            : schedule.isOnline
                                ? Icons.videocam
                                : Icons.location_on,
                        size: 14,
                        color: isLive
                            ? Colors.white
                            : schedule.isOnline
                                ? Colors.blue.shade700
                                : Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLive ? '🔴 LIVE NOW' : schedule.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isLive
                              ? Colors.white
                              : schedule.isOnline
                                  ? Colors.blue.shade700
                                  : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  schedule.time,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              schedule.courseTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  schedule.teacher,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  schedule.isOnline ? Icons.video_library : Icons.place,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    schedule.venue,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ],
            ),
            if (!isLive && isStartingSoon)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      isStartingSoon
                          ? '⏰ Starting in ${_getMinutesUntilClass(schedule)} min'
                          : '📅 Scheduled',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (schedule.isOnline && schedule.meetingLink != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLive || isStartingSoon
                          ? () => _joinOnlineClass(schedule.meetingLink!)
                          : null,
                      icon: Icon(
                        isLive ? Icons.video_call : Icons.video_library,
                        color: isLive || isStartingSoon
                            ? Colors.white
                            : Colors.grey,
                      ),
                      label: Text(
                        isLive
                            ? '🔴 Join Now!'
                            : isStartingSoon
                                ? 'Join Soon'
                                : 'Join Class',
                        style: TextStyle(
                          color: isLive || isStartingSoon
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLive
                            ? Colors.red
                            : isStartingSoon
                                ? Colors.orange
                                : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                if (schedule.isPhysical)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openLocation(schedule.venue),
                      icon: const Icon(Icons.directions),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showScheduleDetails(schedule, isLive: isLive);
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A3A5C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getMinutesUntilClass(Schedule schedule) {
    final now = DateTime.now();
    try {
      final classTime = DateFormat('HH:mm').parse(schedule.time);
      final classStart = DateTime(
        now.year,
        now.month,
        now.day,
        classTime.hour,
        classTime.minute,
      );
      return classStart.difference(now).inMinutes;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildScheduleItem(Schedule schedule) {
    final isLive = _isClassHappeningNow(schedule);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLive
              ? Colors.red
              : schedule.isOnline
                  ? Colors.blue.shade100
                  : Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isLive
              ? Icons.live_tv
              : schedule.isOnline
                  ? Icons.videocam
                  : Icons.location_on,
          color: isLive
              ? Colors.white
              : schedule.isOnline
                  ? Colors.blue.shade700
                  : Colors.green.shade700,
          size: 20,
        ),
      ),
      title: Text(
        schedule.courseTitle,
        style: TextStyle(
          fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
          color: isLive ? Colors.red : null,
        ),
      ),
      subtitle: Text('${schedule.time} • ${schedule.teacher}'),
      trailing: isLive && schedule.isOnline && schedule.meetingLink != null
          ? ElevatedButton(
              onPressed: () => _joinOnlineClass(schedule.meetingLink!),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text('Join Now'),
            )
          : null,
    );
  }

  void _showScheduleDetails(Schedule schedule, {bool isLive = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isLive ? Icons.live_tv : Icons.info,
              color: isLive ? Colors.red : const Color(0xFF1A3A5C),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(schedule.courseTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLive)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.live_tv, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      '🔴 CLASS IS LIVE NOW!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.calendar_today, schedule.day),
            _buildDetailRow(Icons.access_time, schedule.time),
            _buildDetailRow(Icons.person, schedule.teacher),
            _buildDetailRow(
              schedule.isOnline ? Icons.videocam : Icons.location_on,
              schedule.venue,
            ),
            _buildDetailRow(Icons.access_time, schedule.duration),
          ],
        ),
        actions: [
          if (isLive && schedule.isOnline && schedule.meetingLink != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _joinOnlineClass(schedule.meetingLink!);
              },
              icon: const Icon(Icons.video_call),
              label: const Text('Join Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          if (schedule.isPhysical)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openLocation(schedule.venue);
              },
              icon: const Icon(Icons.directions),
              label: const Text('Directions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
