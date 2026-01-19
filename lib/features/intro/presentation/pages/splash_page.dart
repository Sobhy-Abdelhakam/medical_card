import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/injection_container.dart';
import '../../../app/presentation/pages/main_app_shell.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../presentation/cubit/splash/splash_cubit.dart';
import '../../presentation/cubit/splash/splash_state.dart';
import 'welcome_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late final SplashCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<SplashCubit>();
    _cubit.startSplash();

    _controller = AnimationController(
      duration:
          const Duration(seconds: 2), // Shorter duration to match cubit delay
      vsync: this,
    )..forward();

    _animation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _cubit.close();
    super.dispose();
  }

  void _navigateToNextPage(SplashState state) {
    if (state is SplashNavigateToHome) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainAppShell()),
      );
    } else if (state is SplashNavigateToWelcome) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    } else if (state is SplashNavigateToLogin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          _navigateToNextPage(state);
        },
        child: Scaffold(
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
        ),
      ),
    );
  }
}

// class UpdateScreen extends StatelessWidget {
//   final String downloadUrl;
//   final String status;
//   final String title;
//   final String content;
//   final String button1;
//   final String button2;
//   final VoidCallback onComplete;

//   const UpdateScreen({
//     super.key,
//     required this.downloadUrl,
//     required this.status,
//     required this.title,
//     required this.content,
//     required this.button1,
//     required this.button2,
//     required this.onComplete,
//   });

//   Future<void> _launchURL() async {
//     final Uri url = Uri.parse(downloadUrl);
//     if (await canLaunchUrl(url)) {
//       await launchUrl(url, mode: LaunchMode.externalApplication);
//     } else {
//       throw 'تعذر فتح الرابط: $downloadUrl';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isMandatory = status == "1";

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title),
//         centerTitle: true,
//         automaticallyImplyLeading: !isMandatory,
//         leading: !isMandatory
//             ? IconButton(icon: const Icon(Icons.close), onPressed: onComplete)
//             : null,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Text(
//               content,
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 18.sp),
//             ),
//             SizedBox(height: 20.h),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 32.w),
//                 backgroundColor: Colors.red,
//               ),
//               onPressed: _launchURL,
//               child: Text(
//                 button1,
//                 style: TextStyle(fontSize: 20.sp, color: Colors.white),
//               ),
//             ),
//             SizedBox(height: 20.h),
//             if (!isMandatory)
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   padding:
//                       EdgeInsets.symmetric(vertical: 16.h, horizontal: 32.w),
//                   backgroundColor: Colors.blueAccent,
//                 ),
//                 onPressed: onComplete,
//                 child: Text(
//                   button2,
//                   style: TextStyle(fontSize: 20.sp, color: Colors.white),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
