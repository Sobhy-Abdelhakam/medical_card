import 'dart:async';
import 'dart:convert'; // لتحليل JSON
import 'package:flutter/material.dart';
import 'package:euro_medical_card/screen/main_app.dart';
import 'package:euro_medical_card/screen/welcome_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http; // مكتبة HTTP
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // مكتبة URL Launcher
import 'package:version/version.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final String updateCheckUrl = "https://qr.euro-assist.com/maps/version.json"; // رابط ملف JSON

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward();

    _animation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start update check and navigation concurrently
    _initApp();
  }

  Future<void> _initApp() async {
    // Wait for at least 4 seconds for the splash animation to be visible
    await Future.delayed(const Duration(seconds: 4));
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      final response = await http.get(Uri.parse(updateCheckUrl));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final latestVersion = Version.parse(data['version']);
        final String downloadUrl = data['url'];
        final String status = data['status'];
        final String title = data['title'] ?? "تحديث جديد";
        final String content = data['message'] ?? "يتوفر إصدار جديد من التطبيق. يُرجى تنزيله للحصول على الميزات الجديدة.";
        final String button1 = data['button1'] ?? "تحميل التحديث";
        final String button2 = data['button2'] ?? "ليس الآن";

        if (latestVersion > currentVersion) {
          _showUpdateScreen(downloadUrl, status, title, content, button1, button2);
          return;
        }
      }
    } catch (e) {
      print("خطأ أثناء جلب التحديث: $e");
    }

    _navigateToNextPage();
  }

  Future<void> _navigateToNextPage() async {
    if (!mounted) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => isLoggedIn ? const MainApp() : WelcomePage()),
    );
  }

  void _showUpdateScreen(String downloadUrl, String status, String title, String content, String button1, String button2) {
    if (!mounted) return;
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
          onComplete: _navigateToNextPage,
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
            'assets/images/logo.jpg',
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
  final VoidCallback onComplete;

  const UpdateScreen({
    super.key,
    required this.downloadUrl,
    required this.status,
    required this.title,
    required this.content,
    required this.button1,
    required this.button2,
    required this.onComplete,
  });

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(downloadUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'تعذر فتح الرابط: $downloadUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMandatory = status == "1";

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
              style: TextStyle(fontSize: 18.sp),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 32.w),
                backgroundColor: Colors.red,
              ),
              onPressed: _launchURL,
              child: Text(
                button1,
                style: TextStyle(fontSize: 20.sp, color: Colors.white),
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 32.w),
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: isMandatory ? null : onComplete,
              child: Text(
                button2,
                style: TextStyle(fontSize: 20.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
