
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../di/injection_container.dart';
import '../../../app/presentation/pages/main_app_shell.dart';
import '../../domain/repositories/intro_repository.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePage createState() => _WelcomePage();
}

class _WelcomePage extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> introData = [
    {
      "image": "assets/images/splash3.jpg",
      "title": "شبكة طبية في جميع أنحاء مصر ",
      "description": "شبكة طبية منتشرة في كل المحافظات."
    },
    {
      "image": "assets/images/splash1.jpg",
      "title": "تخفيضات مميزة",
      "description": "تخفيضات مميزة تصل إلى %80  ."
    },
    {
      "image": "assets/images/splash2.jpg",
      "title": "وصول سهل وسريع",
      "description":
          "وصول سهل سريع بضفطة واحده هتحصل علي اقرب شبكة طبية او مقدم خدمة ليك ....شوف الافضل ."
    },
  ];

  List<bool> imageLoaded = [];

  @override
  void initState() {
    super.initState();

    imageLoaded = List.generate(introData.length, (index) => false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < introData.length; i++) {
        precacheImage(AssetImage(introData[i]['image']!), context).then((_) {
          if (mounted) {
            setState(() {
              imageLoaded[i] = true;
            });
          }
        });
      }
    });
  }

  Future<void> _nextPage() async {
    if (_currentIndex < introData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await sl<IntroRepository>().setAppOpened();
      if(mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAppShell()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: introData.length,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: screenWidth,
                          height: 400.h,
                          child: ClipRRect(
                            child: (imageLoaded.length > index &&
                                    imageLoaded[index])
                                ? Image.asset(
                                    introData[index]["image"]!,
                                    fit: BoxFit.cover,
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          introData[index]["title"]!,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30.0),
                          child: Text(
                            introData[index]["description"]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  SizedBox(height: 60.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      introData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: _currentIndex == index ? 12 : 8,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? theme.colorScheme.primary
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: EdgeInsets.symmetric(
                          horizontal: 40.w, vertical: 15.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _currentIndex == introData.length - 1
                          ? 'ابدأ الآن'
                          : 'التالي',
                      style: TextStyle(fontSize: 18.sp, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
