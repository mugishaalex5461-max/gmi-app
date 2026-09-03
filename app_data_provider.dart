import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDataProvider extends ChangeNotifier {
  // ================================================================
  // 🔐 USER DATA
  // ================================================================
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;

  void setUser(Map<String, dynamic> user) {
    _currentUser = user;
    notifyListeners();
  }

  // ================================================================
  // 📚 COURSES & ENROLLMENT
  // ================================================================
  List<Map<String, dynamic>> _enrolledCourses = [];
  List<Map<String, dynamic>> get enrolledCourses => _enrolledCourses;

  List<Map<String, dynamic>> _availableCourses = [
    {
      'id': 1,
      'title': 'O-Level All Science',
      'description': 'Complete O-Level Science package with all subjects',
      'level': 'O-Level',
      'type': 'Physical',
      'price': 30000,
      'subjects': ['Mathematics', 'Physics', 'Chemistry', 'Biology'],
      'teacher': 'Mr. John Teacher',
      'schedule': 'Mon, Wed, Fri 8:00 AM - 10:00 AM',
      'location': 'GMI Campus, Kampala',
      'googleMapsUrl': 'https://maps.google.com/?q=Kampala+Uganda',
      'meetingLink': null,
      'notesUrl': 'https://example.com/notes/olevel-science.pdf',
      'imageUrl': 'https://via.placeholder.com/300x200/1a3a5c/ffffff?text=O-Level'
    },
    {
      'id': 2,
      'title': 'A-Level 3 Subjects',
      'description': 'Advanced level with Physics, Chemistry, Mathematics',
      'level': 'A-Level',
      'type': 'Physical',
      'price': 400000,
      'subjects': ['Physics', 'Chemistry', 'Mathematics'],
      'teacher': 'Dr. Sarah Physics',
      'schedule': 'Tue, Thu 9:00 AM - 11:00 AM',
      'location': 'GMI Campus, Kampala',
      'googleMapsUrl': 'https://maps.google.com/?q=Kampala+Uganda',
      'meetingLink': null,
      'notesUrl': 'https://example.com/notes/alevel-physics.pdf',
      'imageUrl': 'https://via.placeholder.com/300x200/2c5f8a/ffffff?text=A-Level'
    },
    {
      'id': 3,
      'title': 'O-Level Online',
      'description': 'Online O-Level classes from anywhere',
      'level': 'O-Level',
      'type': 'Online',
      'price': 30000,
      'subjects': ['All Science Subjects'],
      'teacher': 'Ms. Sarah Online',
      'schedule': 'Tue, Thu 9:00 AM - 10:30 AM',
      'location': 'Google Meet',
      'googleMapsUrl': null,
      'meetingLink': 'https://meet.google.com/abc-defg-hij',
      'notesUrl': 'https://example.com/notes/olevel-online.pdf',
      'imageUrl': 'https://via.placeholder.com/300x200/f0c040/2d2d2d?text=Online'
    },
    {
      'id': 4,
      'title': 'A-Level Online 3 Subjects',
      'description': 'Online A-Level with Physics, Chemistry, Mathematics',
      'level': 'A-Level',
      'type': 'Online',
      'price': 150000,
      'subjects': ['Physics', 'Chemistry', 'Mathematics'],
      'teacher': 'Dr. James Online',
      'schedule': 'Mon, Wed, Fri 10:00 AM - 12:00 PM',
      'location': 'Zoom',
      'googleMapsUrl': null,
      'meetingLink': 'https://zoom.us/j/123456789',
      'notesUrl': 'https://example.com/notes/alevel-online.pdf',
      'imageUrl': 'https://via.placeholder.com/300x200/1a3a5c/ffffff?text=A-Level+Online'
    },
  ];
  List<Map<String, dynamic>> get availableCourses => _availableCourses;

  void enrollCourse(Map<String, dynamic> course) {
    if (!_enrolledCourses.any((c) => c['id'] == course['id'])) {
      _enrolledCourses.add(course);
      addNotification('✅ Enrolled in ${course['title']}');
      notifyListeners();
    }
  }

  bool isEnrolled(int courseId) {
    return _enrolledCourses.any((c) => c['id'] == courseId);
  }

  // ================================================================
  // 📅 SCHEDULES
  // ================================================================
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> get schedules => _schedules;

  void generateSchedule() {
    _schedules.clear();
    for (var course in _enrolledCourses) {
      final days = ['Monday', 'Wednesday', 'Friday'];
      final times = ['08:00', '10:00', '14:00'];
      final isOnline = course['type'] == 'Online';
      for (int i = 0; i < 3; i++) {
        _schedules.add({
          'id': '${course['id']}_$i',
          'courseId': course['id'],
          'courseTitle': course['title'],
          'day': days[i % days.length],
          'time': times[i % times.length],
          'duration': '2 hours',
          'teacher': course['teacher'] ?? 'GMI Teacher',
          'type': isOnline ? 'online' : 'physical',
          'venue': isOnline ? course['meetingLink'] ?? 'Google Meet' : course['location'] ?? 'GMI Campus',
          'meetingLink': isOnline ? course['meetingLink'] : null,
          'location': isOnline ? null : course['googleMapsUrl'],
        });
      }
    }
    notifyListeners();
  }

  bool isClassLive(String classTime) {
    final now = DateTime.now();
    try {
      final hour = int.parse(classTime.split(':')[0]);
      final minute = int.parse(classTime.split(':')[1]);
      final classStart = DateTime(now.year, now.month, now.day, hour, minute);
      final classEnd = classStart.add(const Duration(minutes: 90));
      final fifteenMinBefore = classStart.subtract(const Duration(minutes: 15));
      return now.isAfter(fifteenMinBefore) && now.isBefore(classEnd);
    } catch (e) {
      return false;
    }
  }

  // ================================================================
  // 💳 PAYMENT SYSTEM
  // ================================================================
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> get payments => _payments;

  // Admin phone numbers from PDF
  final String _adminPhone1 = '+256782559065';  // M Bosco
  final String _adminPhone2 = '+256787790547';  // DUSENGE STEPHEN

  Future<bool> processPayment({
    required double amount,
    required String phoneNumber,
    required String pin,
    required String description,
    String? courseId,
  }) async {
    // Validate phone number
    if (phoneNumber.length < 10) {
      addNotification('❌ Invalid phone number');
      return false;
    }

    // Validate PIN (simulate)
    if (pin.length < 4) {
      addNotification('❌ Invalid PIN');
      return false;
    }

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Check amount (in real app, verify with MTN/Airtel API)
    final payment = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'amount': amount,
      'phone': phoneNumber,
      'description': description,
      'date': DateTime.now().toString().substring(0, 16),
      'status': 'Completed',
      'courseId': courseId,
    };

    _payments.add(payment);

    // Send SMS notifications to admins
    _sendAdminNotification(
      message: '🔔 NEW PAYMENT RECEIVED!\n'
               '💰 Amount: UGX ${amount.toStringAsFixed(0)}\n'
               '📱 Phone: $phoneNumber\n'
               '📝 Description: $description\n'
               '✅ Status: PAID'
    );

    addNotification('✅ Payment of UGX ${amount.toStringAsFixed(0)} completed!');

    // If it's a course enrollment
    if (courseId != null) {
      final course = _availableCourses.firstWhere(
        (c) => c['id'] == int.parse(courseId),
        orElse: () => {},
      );
      if (course.isNotEmpty) {
        enrollCourse(course);
        generateSchedule();
        addNotification('✅ Enrolled in ${course['title']}');
      }
    }

    notifyListeners();
    return true;
  }

  void _sendAdminNotification({required String message}) {
    // 🔧 Simulate SMS to admin
    print('========================================');
    print('📱 SMS SENT TO ADMINS:');
    print('📞 Admin 1 (M Bosco): $_adminPhone1');
    print('📞 Admin 2 (DUSENGE STEPHEN): $_adminPhone2');
    print('----------------------------------------');
    print(message);
    print('========================================');

    // Add to notifications
    addNotification('📱 Admin notification sent');
  }

  // ================================================================
  // 📱 PHONE & WHATSAPP CONTACTS (from PDF)
  // ================================================================
  final List<Map<String, String>> contacts = [
    {
      'name': 'M Bosco',
      'phone': '+256782559065',
      'whatsapp': '256782559065',
      'role': 'Admin',
    },
    {
      'name': 'DUSENGE STEPHEN',
      'phone': '+256787790547',
      'whatsapp': '256787790547',
      'role': 'Admin',
    },
  ];

  void makePhoneCall(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void openWhatsApp(String phone) async {
    final url = 'https://wa.me/$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void openGoogleMaps(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void joinMeeting(String link) async {
    if (await canLaunchUrl(Uri.parse(link))) {
      await launchUrl(Uri.parse(link));
    }
  }

  // ================================================================
  // 🔔 NOTIFICATIONS
  // ================================================================
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  void addNotification(String message) {
    _notifications.insert(0, {
      'message': message,
      'date': DateTime.now().toString().substring(0, 16),
      'read': false,
    });
    notifyListeners();
  }

  void markNotificationRead(int index) {
    _notifications[index]['read'] = true;
    notifyListeners();
  }

  int get unreadCount => _notifications.where((n) => n['read'] == false).length;

  // ================================================================
  // 📊 PROGRESS TRACKING
  // ================================================================
  double getProgressPercentage() {
    final total = _availableCourses.length;
    if (total == 0) return 0;
    return _enrolledCourses.length / total * 100;
  }

  // ================================================================
  // 📝 SELF-STUDY MATERIALS (from PDF)
  // ================================================================
  List<Map<String, dynamic>> _selfStudyMaterials = [
    {
      'id': '1',
      'title': 'LSC Standard Items & Responses',
      'level': 'O-Level',
      'price': 2000,
      'description': 'Standard items and model answers for Lower Secondary Certificate',
    },
    {
      'id': '2',
      'title': 'Upper Secondary Standard Items & Responses',
      'level': 'A-Level',
      'price': 4000,
      'description': 'Advanced standard items for Upper Secondary Certificate',
    },
  ];
  List<Map<String, dynamic>> get selfStudyMaterials => _selfStudyMaterials;

  List<Map<String, dynamic>> _purchasedSelfStudy = [];
  List<Map<String, dynamic>> get purchasedSelfStudy => _purchasedSelfStudy;

  void purchaseSelfStudy(Map<String, dynamic> material) {
    if (!_purchasedSelfStudy.any((m) => m['id'] == material['id'])) {
      _purchasedSelfStudy.add(material);
      addNotification('📚 Purchased: ${material['title']}');
      notifyListeners();
    }
  }

  bool hasSelfStudyAccess(String id) {
    return _purchasedSelfStudy.any((m) => m['id'] == id);
  }

  // ================================================================
  // 🛒 SHOPPING CART
  // ================================================================
  List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> get cart => _cart;
  int get cartCount => _cart.length;
  double get cartTotal => _cart.fold(0, (sum, item) => sum + (item['price'] as double));

  void addToCart(Map<String, dynamic> item) {
    if (!_cart.any((c) => c['id'] == item['id'])) {
      _cart.add(item);
      addNotification('🛒 Added to cart: ${item['title']}');
      notifyListeners();
    }
  }

  void removeFromCart(int index) {
    final item = _cart[index];
    _cart.removeAt(index);
    addNotification('🗑️ Removed from cart: ${item['title']}');
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  bool isInCart(int id) {
    return _cart.any((c) => c['id'] == id);
  }

  // ================================================================
  // 📅 APPOINTMENTS
  // ================================================================
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> get appointments => _appointments;

  void bookAppointment(Map<String, dynamic> appointment) {
    _appointments.add(appointment);
    addNotification('📅 Appointment booked: ${appointment['subject']}');
    notifyListeners();
  }

  // ================================================================
  // 📰 NEWS & EVENTS (from PDF)
  // ================================================================
  List<Map<String, dynamic>> _news = [
    {
      'id': '1',
      'title': '🎓 New Academic Year 2026',
      'content': 'GMI Education is now accepting enrollments for the 2026 academic year. Join us for quality education!',
      'date': '2026-09-01',
      'category': 'Academic',
    },
    {
      'id': '2',
      'title': '🏆 Holiday Lessons Program',
      'content': 'Register now for our holiday lessons program. S.1 to S.3 students welcome!',
      'date': '2026-08-25',
      'category': 'Holiday',
    },
    {
      'id': '3',
      'title': '📚 New Self-Study Materials Available',
      'content': 'We have added new LSC and Upper Secondary standard items for self-study.',
      'date': '2026-08-20',
      'category': 'Materials',
    },
  ];
  List<Map<String, dynamic>> get news => _news;

  // ================================================================
  // 🖼️ GALLERY IMAGES (from PDF)
  // ================================================================
  List<Map<String, dynamic>> _galleryImages = [
    {'id': '1', 'title': 'Classroom Session', 'category': 'Classes'},
    {'id': '2', 'title': 'Student Learning', 'category': 'Students'},
    {'id': '3', 'title': 'Holiday Lessons', 'category': 'Holiday'},
    {'id': '4', 'title': 'Science Lab', 'category': 'Classes'},
    {'id': '5', 'title': 'Online Class', 'category': 'Online'},
    {'id': '6', 'title': 'Group Study', 'category': 'Students'},
  ];
  List<Map<String, dynamic>> get galleryImages => _galleryImages;

  // ================================================================
  // 🏷️ HOLIDAY LESSONS (from PDF)
  // ================================================================
  List<Map<String, dynamic>> _holidayLessons = [
    {'title': 'Holiday Program S.1', 'level': 'S.1', 'subjects': ['Mathematics', 'English', 'Science'], 'fee': 50000},
    {'title': 'Holiday Program S.2', 'level': 'S.2', 'subjects': ['Mathematics', 'English', 'Physics', 'Chemistry'], 'fee': 60000},
    {'title': 'Holiday Program S.3', 'level': 'S.3', 'subjects': ['Mathematics', 'Physics', 'Chemistry', 'Biology'], 'fee': 70000},
  ];
  List<Map<String, dynamic>> get holidayLessons => _holidayLessons;

  // ================================================================
  // 🔧 RESET
  // ================================================================
  void reset() {
    _enrolledCourses.clear();
    _payments.clear();
    _notifications.clear();
    _cart.clear();
    _appointments.clear();
    _schedules.clear();
    _purchasedSelfStudy.clear();
    notifyListeners();
  }
}