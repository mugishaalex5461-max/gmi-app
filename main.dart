import 'package:flutter/material.dart';
import 'package:gmi_learning_app/models/providers/app_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 🔧 IMPORT ALL SCREENS
import 'screens/my_classes_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppDataProvider()),
      ],
      child: const GMIApp(),
    ),
  );
}

class GMIApp extends StatelessWidget {
  const GMIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GMI Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A3A5C),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1A3A5C),
          secondary: Color(0xFFF0C040),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A3A5C),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF0C040),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/student-dashboard': (context) => const StudentDashboard(),
        '/teacher-dashboard': (context) => const TeacherDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/shop': (context) => const ShopScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/register': (context) => const RegisterScreen(),
        '/courses': (context) => const CoursesScreen(),
        '/my-classes': (context) => const MyClassesScreen(), // ✅ NOW IMPORTED!
      },
    );
  }
}

class GmiLogo extends StatelessWidget {
  const GmiLogo({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset('assets/gmi_logo.svg'),
    );
  }
}

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.availableCourses.length,
        itemBuilder: (context, index) {
          final course = provider.availableCourses[index];
          final enrolled = provider.isEnrolled(course['id'] as int);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course['title'] as String,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(course['description'] as String),
                  const SizedBox(height: 8),
                  Text('${course['level']} • ${course['type']} • '
                      'UGX ${course['price'].toStringAsFixed(0)}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: enrolled || provider.isEnrollmentPending(course['id'] as int)
                              ? null
                              : () {
                                  _showPaymentDialog(context, provider, course);
                                },
                          icon: const Icon(Icons.school),
                          label: Text(enrolled
                              ? 'Paid and enrolled'
                              : provider.isEnrollmentPending(course['id'] as int)
                                  ? 'Payment pending'
                                  : 'Enroll and pay'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Add to cart',
                        onPressed: provider.isInCart(course['id'])
                            ? null
                            : () => provider.addToCart(course),
                        icon: const Icon(Icons.add_shopping_cart),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, AppDataProvider provider,
      Map<String, dynamic> course) {
    var channel = 'MTN Mobile Money';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Choose payment channel'),
          content: DropdownButtonFormField<String>(
            initialValue: channel,
            items: const [
              DropdownMenuItem(value: 'MTN Mobile Money', child: Text('MTN Mobile Money')),
              DropdownMenuItem(value: 'Airtel Money', child: Text('Airtel Money')),
            ],
            onChanged: (value) => setDialogState(() => channel = value!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.requestCourseEnrollment(course);
                provider.startPayment(
                  amount: (course['price'] as num).toDouble(),
                  description: course['title'] as String,
                  channel: channel,
                  courseId: course['id'] as int,
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment request sent via $channel')),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          GmiLogo(size: 96),
          SizedBox(height: 16),
          Center(child: Text('GMI Learning User', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          SizedBox(height: 24),
          ListTile(leading: Icon(Icons.email_outlined), title: Text('Email'), subtitle: Text('Use your registered account email')),
          ListTile(leading: Icon(Icons.school_outlined), title: Text('Learning account'), subtitle: Text('Student or teacher access')),
        ],
      ),
    );
  }
}

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('${provider.cartCount} items')),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.cart.isEmpty
                ? const Center(child: Text('Your cart is empty. Add a course from Courses.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.cart.length,
                    itemBuilder: (context, index) {
                      final item = provider.cart[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.menu_book),
                          title: Text(item['title'] as String),
                          subtitle: Text('UGX ${item['price']}'),
                          trailing: IconButton(
                            tooltip: 'Remove from cart',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => provider.removeFromCart(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (provider.cart.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Total: UGX ${provider.cartTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.purchaseCart();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Purchase completed')),
                        );
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// 🔐 LOGIN SCREEN
// ================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _openContact(String url, String action) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open $action')),
      );
    }
  }

  Widget _contactRow({
    required String name,
    required String phone,
    required String whatsappNumber,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(phone, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Call $name',
            onPressed: () => _openContact('tel:$phone', 'the phone dialer'),
            icon: const Icon(Icons.phone, color: Colors.white),
          ),
          IconButton(
            tooltip: 'WhatsApp $name',
            onPressed: () => _openContact(
                'https://wa.me/$whatsappNumber', 'WhatsApp'),
            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
          ),
        ],
      ),
    );
  }

  final Map<String, Map<String, String>> _demoAccounts = {
    'student@gmi.com': {'password': 'student123', 'role': 'student'},
    'teacher@gmi.com': {'password': 'teacher123', 'role': 'teacher'},
    'admin@gmi.com': {'password': 'admin123', 'role': 'admin'},
  };

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      await Future.delayed(const Duration(seconds: 1));

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_demoAccounts.containsKey(email) &&
          _demoAccounts[email]!['password'] == password) {
        final role = _demoAccounts[email]!['role']!;
        if (mounted) {
          if (role == 'student') {
            Navigator.pushReplacementNamed(context, '/student-dashboard');
          } else if (role == 'teacher') {
            Navigator.pushReplacementNamed(context, '/teacher-dashboard');
          } else if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          }
        }
      } else {
        setState(() {
          _errorMessage = '❌ Invalid email or password.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A3A5C), Color(0xFF2C5F8A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const GmiLogo(size: 96),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'GMI Learning',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const Text(
                        'Great Mind International',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Welcome Back! 👋',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login to continue your learning journey',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? 'Enter email' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          validator: (v) =>
                              (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_errorMessage!,
                                style: TextStyle(color: Colors.red.shade700)),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Login',
                                    style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account?",
                                style: TextStyle(color: Colors.grey.shade600)),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/register'),
                              child: const Text('Register'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📋 Demo Accounts:',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('👨‍🎓 Student: student@gmi.com / student123',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('👨‍🏫 Teacher: teacher@gmi.com / teacher123',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('👨‍💼 Admin: admin@gmi.com / admin123',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contact GMI Support',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('Tap the phone or WhatsApp icon to contact us',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      _contactRow(
                        name: 'DUSENGE STEPHEN',
                        phone: '+256 787790547',
                        whatsappNumber: '256787790547',
                      ),
                      _contactRow(
                        name: 'M. BOSCO',
                        phone: '+256 782 559065',
                        whatsappNumber: '256782559065',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 📝 REGISTER SCREEN
// ================================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedLevel = 'O-Level';
  bool _isLoading = false;
  final List<String> _levels = ['O-Level', 'A-Level', 'University'];

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A3A5C), Color(0xFF2C5F8A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Text(
                  'Create Account 🎓',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join GMI Learning Platform',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                          ),
                          validator: (v) => v!.isEmpty || !v.contains('@')
                              ? 'Enter valid email'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                          ),
                          validator: (v) => (v?.length ?? 0) < 10
                              ? 'Enter valid phone'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLevel,
                          decoration: const InputDecoration(
                            labelText: 'Education Level',
                            prefixIcon: Icon(Icons.school_outlined),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                          ),
                          items: _levels.map((level) {
                            return DropdownMenuItem(
                                value: level, child: Text(level));
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedLevel = value!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                          ),
                          validator: (v) =>
                              (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text('Register',
                                    style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account?',
                                style: TextStyle(color: Colors.grey.shade600)),
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Login')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 👨‍🎓 STUDENT DASHBOARD
// ================================================================
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: const Color(0xFF1A3A5C),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👋 Welcome Student!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Access your courses, materials, and appointments',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildCard(context, Icons.book, 'My Courses', Colors.blue,
                          () {
                        Navigator.pushNamed(context, '/courses');
                      }),
                      _buildCard(
                          context, Icons.shopping_bag, 'Shop', Colors.green,
                          () {
                        Navigator.pushNamed(context, '/shop');
                      }),
                      _buildCard(context, Icons.calendar_month, 'My Classes',
                          Colors.orange, () {
                        Navigator.pushNamed(context, '/my-classes');
                      }),
                      _buildCard(context, Icons.event_available, 'Book Tutor',
                          Colors.teal, () {
                        _showAppointmentDialog(context);
                      }),
                      _buildCard(
                          context, Icons.person, 'Profile', Colors.purple, () {
                        Navigator.pushNamed(context, '/profile');
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDialog(BuildContext context) {
    final subjectController = TextEditingController();
    var teacher = 'John Teacher';
    var channel = 'MTN Mobile Money';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Book a tutor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: teacher,
                  decoration: const InputDecoration(labelText: 'Teacher'),
                  items: const [
                    DropdownMenuItem(value: 'John Teacher', child: Text('John Teacher')),
                    DropdownMenuItem(value: 'Sarah Teacher', child: Text('Sarah Teacher')),
                  ],
                  onChanged: (value) => setDialogState(() => teacher = value!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: channel,
                  decoration: const InputDecoration(labelText: 'Payment channel'),
                  items: const [
                    DropdownMenuItem(value: 'MTN Mobile Money', child: Text('MTN Mobile Money')),
                    DropdownMenuItem(value: 'Airtel Money', child: Text('Airtel Money')),
                  ],
                  onChanged: (value) => setDialogState(() => channel = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (subjectController.text.trim().isEmpty) return;
                final provider = context.read<AppDataProvider>();
                provider.bookAppointment({
                  'student': 'GMI Learning Student',
                  'teacher': teacher,
                  'subject': subjectController.text.trim(),
                  'date': DateTime.now().toIso8601String().split('T').first,
                  'status': 'Awaiting payment',
                });
                provider.startPayment(
                  amount: 10000,
                  description: 'Tutor appointment: ${subjectController.text.trim()}',
                  channel: channel,
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment payment request sent')),
                );
              },
              child: const Text('Book and pay'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// 👨‍🏫 TEACHER DASHBOARD
// ================================================================
class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: const Color(0xFF1A3A5C),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👨‍🏫 Welcome Teacher!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your appointments, students, and classes',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildCard(context, Icons.calendar_today, 'Appointments',
                          Colors.blue, () {
                        _showTeacherRecords(context, 'Appointments', [
                          'Review pending student appointment requests',
                          'Approve, reschedule, or cancel appointments',
                        ]);
                      }),
                      _buildCard(
                          context, Icons.people, 'My Students', Colors.green,
                          () {
                        _showTeacherRecords(context, 'My Students', [
                          'Jane Student • O-Level Mathematics',
                          'View enrolled learners and course progress',
                        ]);
                      }),
                      _buildCard(
                          context, Icons.schedule, 'Schedule', Colors.orange,
                          () {
                        _showTeacherRecords(context, 'Schedule', [
                          'Monday • 08:00 • O-Level Mathematics',
                          'Wednesday • 10:00 • A-Level Physics',
                          'Friday • 14:00 • Computer Studies',
                        ]);
                      }),
                      _buildCard(
                          context, Icons.person, 'Profile', Colors.purple, () {
                        Navigator.pushNamed(context, '/profile');
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeacherRecords(
      BuildContext context, String title, List<String> records) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            Text(title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            ...records.map((record) => ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(record),
                )),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// 👨‍💼 ADMIN DASHBOARD - COMPLETE FIXED VERSION
// ================================================================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'name': 'Jane Student',
      'email': 'student@gmi.com',
      'role': 'Student'
    },
    {
      'id': 2,
      'name': 'John Teacher',
      'email': 'teacher@gmi.com',
      'role': 'Teacher'
    },
    {'id': 3, 'name': 'Admin User', 'email': 'admin@gmi.com', 'role': 'Admin'},
  ];

  final List<Map<String, dynamic>> _materials = [
    {
      'id': 1,
      'title': 'O-Level Mathematics Notes',
      'level': 'O-Level',
      'price': 15000
    },
    {
      'id': 2,
      'title': 'A-Level Physics Guide',
      'level': 'A-Level',
      'price': 20000
    },
  ];

  final List<Map<String, dynamic>> _appointments = [
    {
      'id': 1,
      'student': 'Jane Student',
      'teacher': 'John Teacher',
      'subject': 'Mathematics',
      'date': '2024-09-15',
      'status': 'Pending'
    },
  ];

  final List<Map<String, dynamic>> _payments = [
    {
      'id': 1,
      'user': 'Jane Student',
      'amount': 15000,
      'material': 'Mathematics Notes',
      'date': '2024-09-01',
      'status': 'Completed'
    },
  ];

  final List<String> _tabs = [
    '📊 Dashboard',
    '👥 Users',
    '📚 Materials',
    '📅 Appointments',
    '💰 Payments'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF1A3A5C),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
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
        child: Column(
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _tabs[index],
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF1A3A5C)
                                : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildUsersManagement();
      case 2:
        return _buildMaterialsManagement();
      case 3:
        return _buildAppointmentsManagement();
      case 4:
        return _buildPaymentsManagement();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final provider = context.watch<AppDataProvider>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Overview',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      '👥', 'Users', _users.length, Colors.blue)),
              Expanded(
                  child: _buildStatCard(
                      '📚', 'Materials', _materials.length, Colors.green)),
              Expanded(
                  child: _buildStatCard('📅', 'Appointments',
                      _appointments.length, Colors.orange)),
              Expanded(
                  child: _buildStatCard(
                      '💰', 'Payments', _payments.length, Colors.purple)),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('📌 Quick Actions',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _selectedIndex = 1),
                        icon: const Icon(Icons.people, size: 16),
                        label: const Text('Users'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3A5C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _selectedIndex = 2),
                        icon: const Icon(Icons.book, size: 16),
                        label: const Text('Materials'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3A5C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (provider.notifications.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              child: ExpansionTile(
                leading: Badge(
                  label: Text('${provider.unreadNotificationCount}'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                title: const Text('Payment and activity notifications'),
                children: provider.notifications.take(5).map((notification) {
                  final index = provider.notifications.indexOf(notification);
                  return ListTile(
                    title: Text(notification['message'] as String),
                    subtitle: Text(notification['date'] as String),
                    onTap: () => provider.markNotificationRead(index),
                  );
                }).toList(),
              ),
            ),
          ],
          if (provider.pendingPayments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.pending_actions),
                    title: Text('Pending payments'),
                  ),
                  ...provider.pendingPayments.map((payment) => ListTile(
                        title: Text(payment['material'] as String),
                        subtitle: Text('${payment['channel']} • UGX ${payment['amount']}'),
                        trailing: TextButton(
                          onPressed: () => provider.confirmPayment(payment['id'].toString()),
                          child: const Text('Confirm'),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, int count, Color color) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            Text(count.toString(),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C))),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersManagement() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Text('👥 Users',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _showAddUserDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0C040),
                  foregroundColor: Colors.black,
                ),
                child: const Text('+ Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          user['role'] == 'Admin' ? Colors.purple : Colors.blue,
                      child: Text(user['name'].toString().substring(0, 1),
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(user['name'] as String),
                    subtitle: Text('${user['email']} • ${user['role']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _users.removeAt(index));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('🗑️ User deleted!'),
                              backgroundColor: Colors.red),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'Student';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'Student', child: Text('Student')),
                DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                DropdownMenuItem(value: 'Admin', child: Text('Admin')),
              ],
              onChanged: (value) => setState(() => selectedRole = value!),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _users.add({
                    'id': _users.length + 1,
                    'name': nameController.text,
                    'email': emailController.text,
                    'role': selectedRole,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✅ User added!'),
                      backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsManagement() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Text('📚 Materials',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _showAddMaterialDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0C040),
                  foregroundColor: Colors.black,
                ),
                child: const Text('+ Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _materials.length,
              itemBuilder: (context, index) {
                final material = _materials[index];
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.book, color: Color(0xFF1A3A5C)),
                    title: Text(material['title'] as String),
                    subtitle:
                        Text('${material['level']} • UGX ${material['price']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _materials.removeAt(index));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('🗑️ Material deleted!'),
                              backgroundColor: Colors.red),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMaterialDialog() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    String selectedLevel = 'O-Level';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (UGX)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedLevel,
              decoration: const InputDecoration(labelText: 'Level'),
              items: const [
                DropdownMenuItem(value: 'O-Level', child: Text('O-Level')),
                DropdownMenuItem(value: 'A-Level', child: Text('A-Level')),
              ],
              onChanged: (value) => setState(() => selectedLevel = value!),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final price = int.tryParse(priceController.text.trim());
              if (titleController.text.isNotEmpty && price != null && price > 0) {
                setState(() {
                  _materials.add({
                    'id': _materials.length + 1,
                    'title': titleController.text,
                    'price': price,
                    'level': selectedLevel,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✅ Material added!'),
                      backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid title and price')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsManagement() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📅 Appointments',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appointment = _appointments[index];
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: appointment['status'] == 'Pending'
                          ? Colors.orange
                          : Colors.green,
                      child: const Icon(Icons.calendar_today,
                          color: Colors.white, size: 20),
                    ),
                    title: Text(
                        '${appointment['subject']} - ${appointment['teacher']}'),
                    subtitle: Text(
                        '${appointment['student']} • ${appointment['date']} • ${appointment['status']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _appointments.removeAt(index));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('🗑️ Appointment deleted!'),
                              backgroundColor: Colors.red),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsManagement() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💰 Payments',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _payments.length,
              itemBuilder: (context, index) {
                final payment = _payments[index];
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: payment['status'] == 'Completed'
                          ? Colors.green
                          : Colors.orange,
                      child: const Icon(Icons.payment,
                          color: Colors.white, size: 20),
                    ),
                    title: Text('${payment['user']} - ${payment['material']}'),
                    subtitle: Text(
                        'UGX ${payment['amount']} • ${payment['date']} • ${payment['status']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _payments.removeAt(index));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('🗑️ Payment deleted!'),
                              backgroundColor: Colors.red),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
