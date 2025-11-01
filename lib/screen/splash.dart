import 'dart:async';
import 'dart:convert'; // لتحليل JSON
import 'package:flutter/material.dart';
import 'package:euro_medical_card/screen/main_app.dart';
import 'package:euro_medical_card/screen/welcome_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http; // مكتبة HTTP
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // مكتبة URL Launcher

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final String currentVersion = "1.0.0"; // إصدار التطبيق الحالي
  final String updateCheckUrl = "https://qr.euro-assist.com/maps/version.json"; // رابط ملف JSON

  @override
  void initState() {
    super.initState();

    // إعداد AnimationController
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward();

    _animation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // التحقق من وجود تحديث بعد 4 ثوانٍ
    Timer(const Duration(seconds: 6), () async {
      await _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      // استدعاء API لجلب ملف JSON
      final response = await http.get(Uri.parse(updateCheckUrl));

      if (response.statusCode == 200) {
        // فك الترميز باستخدام UTF-8
        final data = json.decode(utf8.decode(response.bodyBytes));
        final String latestVersion = data['version']; // الإصدار الموجود في JSON
        final String downloadUrl = data['url']; // رابط التحميل من JSON
        final String status = data['status']; // حالة التحديث
        final String title = data['title'] ?? "تحديث جديد"; // عنوان التحديث
        final String content = data['message'] ?? "يتوفر إصدار جديد من التطبيق. يُرجى تنزيله للحصول على الميزات الجديدة."; // محتوى التحديث
        final String button1 = data['button1'] ?? "تحميل التحديث"; // نص الزر الأول
        final String button2 = data['button2'] ?? "ليس الآن"; // نص الزر الثاني

        // إذا كان هناك إصدار جديد، عرض شاشة التحديث
        if (_isNewVersionAvailable(latestVersion)) {
          _showUpdateScreen(downloadUrl, status, title, content, button1, button2);
          return;
        }
      }
    } catch (e) {
      // في حالة وجود خطأ، يمكنك تسجيله أو تجاهله
      print("خطأ أثناء جلب التحديث: $e");
    }

    // إذا لم يكن هناك تحديث، الانتقال إلى الصفحة التالية
    await _navigateToNextPage();
  }


  Future<void> _navigateToNextPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainApp()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomePage()),
      );
    }
  }

  bool _isNewVersionAvailable(String latestVersion) {
    // مقارنة الإصدار الحالي مع الإصدار الجديد
    return currentVersion != latestVersion;
  }

  void _showUpdateScreen(String downloadUrl, String status, String title, String content, String button1, String button2) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateScreen(
          downloadUrl: downloadUrl,
          status: status,
          title: title,
          content: content,
          button1: button1,
          button2: button2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Image.asset(
            'assets/images/logo.jpg', // استبدل هذا بمسار الصورة الخاص بك
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }
}

class UpdateScreen extends StatelessWidget {
  final String downloadUrl;
  final String status;
  final String title;
  final String content;
  final String button1;
  final String button2;

  const UpdateScreen({
    super.key,
    required this.downloadUrl,
    required this.status,
    required this.title,
    required this.content,
    required this.button1,
    required this.button2,
  });

  // دالة لفتح رابط التحميل
  Future<void> _launchURL() async {
    if (await canLaunch(downloadUrl)) {
      await launch(downloadUrl); // فتح الرابط في المتصفح
    } else {
      throw 'تعذر فتح الرابط: $downloadUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMandatory = status == "1"; // تحقق إذا كان التحديث إلزاميًا

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              content,
              textAlign: TextAlign.center,
              style:  TextStyle(fontSize: 18.sp),
            ),
             SizedBox(height: 20.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:  EdgeInsets.symmetric(vertical: 16.h, horizontal: 32.w),
                backgroundColor: Colors.red,
              ),
              onPressed: _launchURL, // استخدام الدالة لفتح الرابط
              child: Text(
                button1,
                style:  TextStyle(fontSize: 20.sp, color: Colors.white),
              ),
            ),
             SizedBox(height: 20.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:  EdgeInsets.symmetric(vertical: 16.h, horizontal: 32.w),
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: isMandatory
                  ? null // تعطيل الزر إذا كان التحديث إلزاميًا
                  : () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
                if (isLoggedIn) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainApp()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => WelcomePage()),
                  );
                }
              },
              child: Text(
                button2,
                style:  TextStyle(fontSize: 20.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
