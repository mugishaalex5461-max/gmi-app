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
  
  List<Map<String, dynamic>> _pendingEnrollments = [];
  
  bool isEnrollmentPending(int courseId) {
    return _pendingEnrollments.any((e) => e['courseId'] == courseId);
  }

  void requestCourseEnrollment(Map<String, dynamic> course) {
    if (!_pendingEnrollments.any((e) => e['courseId'] == course['id'])) {
      _pendingEnrollments.add({
        'courseId': course['id'],
        'title': course['title'],
        'status': 'pending',
        'date': DateTime.now().toString(),
      });
      notifyListeners();
    }
  }

  // ================================================================
  // 📚 AVAILABLE COURSES
  // ================================================================
  List<Map<String, dynamic>> _availableCourses = [
    {
      'id': 1,
      'title': 'O-Level Mathematics',
      'description': 'Core mathematics lessons, exercises, and revision.',
      'level': 'O-Level',
      'type': 'Online',
      'price': 15000.0,
      'subjects': ['Mathematics'],
      'teacher': 'Mr. John Teacher',
      'schedule': 'Mon, Wed 8:00 AM',
      'location': 'Google Meet',
      'meetingLink': 'https://meet.google.com/abc-defg-hij',
      'notesUrl': 'https://example.com/notes/math.pdf',
    },
    {
      'id': 2,
      'title': 'A-Level Physics',
      'description': 'Physics concepts, practicals, and exam preparation.',
      'level': 'A-Level',
      'type': 'Physical',
      'price': 20000.0,
      'subjects': ['Physics'],
      'teacher': 'Dr. Sarah Physics',
      'schedule': 'Tue, Thu 9:00 AM',
      'location': 'GMI Campus, Kampala',
      'meetingLink': null,
      'notesUrl': 'https://example.com/notes/physics.pdf',
    },
    {
      'id': 3,
      'title': 'Computer Studies',
      'description': 'Digital literacy, programming fundamentals, and projects.',
      'level': 'O-Level',
      'type': 'Online',
      'price': 18000.0,
      'subjects': ['ICT', 'Programming'],
      'teacher': 'Ms. Sarah Online',
      'schedule': 'Mon, Wed, Fri 10:00 AM',
      'location': 'Zoom',
      'meetingLink': 'https://zoom.us/j/123456789',
      'notesUrl': 'https://example.com/notes/ict.pdf',
    },
  ];
  List<Map<String, dynamic>> get availableCourses => _availableCourses;

  void enrollCourse(Map<String, dynamic> course) {
    if (!_enrolledCourses.any((c) => c['id'] == course['id'])) {
      _enrolledCourses.add(course);
      // Remove from pending
      _pendingEnrollments.removeWhere((e) => e['courseId'] == course['id']);
      addNotification('✅ Enrolled in ${course['title']}');
      notifyListeners();
    }
  }

  bool isEnrolled(int courseId) {
    return _enrolledCourses.any((c) => c['id'] == courseId);
  }

  // ================================================================
  // 💳 PAYMENT SYSTEM - FIXED!
  // ================================================================
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> get payments => _payments;

  // Admin phone numbers
  final String _adminPhone1 = '+256782559065';
  final String _adminPhone2 = '+256787790547';

  // 🔧 MAIN PAYMENT METHOD - THIS WAS MISSING!
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

    // Validate PIN
    if (pin.length < 4) {
      addNotification('❌ Invalid PIN');
      return false;
    }

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Record payment
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
    addNotification('✅ Payment of UGX ${amount.toStringAsFixed(0)} completed!');

    // Send admin notification
    _sendAdminNotification(
      message: '🔔 NEW PAYMENT RECEIVED!\n'
               '💰 Amount: UGX ${amount.toStringAsFixed(0)}\n'
               '📱 Phone: $phoneNumber\n'
               '📝 Description: $description\n'
               '✅ Status: PAID'
    );

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
    print('========================================');
    print('📱 SMS SENT TO ADMINS:');
    print('📞 Admin 1: $_adminPhone1');
    print('📞 Admin 2: $_adminPhone2');
    print('----------------------------------------');
    print(message);
    print('========================================');
    addNotification('📱 Admin notification sent');
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
          'venue': isOnline ? (course['meetingLink'] ?? 'Google Meet') : (course['location'] ?? 'GMI Campus'),
          'meetingLink': isOnline ? course['meetingLink'] : null,
          'location': isOnline ? null : course['location'],
        });
      }
    }
    notifyListeners();
  }

  bool isClassLive(String classTime) {
    final now = DateTime.now();
    try {
      final parts = classTime.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final classStart = DateTime(now.year, now.month, now.day, hour, minute);
        final classEnd = classStart.add(const Duration(minutes: 90));
        final fifteenMinBefore = classStart.subtract(const Duration(minutes: 15));
        return now.isAfter(fifteenMinBefore) && now.isBefore(classEnd);
      }
      return false;
    } catch (e) {
      return false;
    }
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

  void purchaseCart() {
    if (_cart.isEmpty) return;
    double total = cartTotal;
    for (var item in _cart) {
      _payments.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'amount': item['price'],
        'description': item['title'],
        'date': DateTime.now().toString().substring(0, 16),
        'status': 'Completed',
      });
    }
    addNotification('🛒 Purchased ${_cart.length} items for UGX ${total.toStringAsFixed(0)}');
    _cart.clear();
    notifyListeners();
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
  // 🔔 NOTIFICATIONS
  // ================================================================
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadNotificationCount => _notifications.where((n) => n['read'] == false).length;

  void addNotification(String message) {
    _notifications.insert(0, {
      'message': message,
      'date': DateTime.now().toString().substring(0, 16),
      'read': false,
    });
    notifyListeners();
  }

  void markNotificationRead(int index) {
    if (index < _notifications.length) {
      _notifications[index]['read'] = true;
      notifyListeners();
    }
  }

  // ================================================================
  // 📊 PROGRESS
  // ================================================================
  double getProgressPercentage() {
    final total = _availableCourses.length;
    if (total == 0) return 0;
    return _enrolledCourses.length / total * 100;
  }

  // ================================================================
  // 📱 CONTACT
  // ================================================================
  final List<Map<String, String>> contacts = [
    {'name': 'M Bosco', 'phone': '+256782559065', 'whatsapp': '256782559065'},
    {'name': 'DUSENGE STEPHEN', 'phone': '+256787790547', 'whatsapp': '256787790547'},
  ];

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
    _pendingEnrollments.clear();
    notifyListeners();
  }
}
