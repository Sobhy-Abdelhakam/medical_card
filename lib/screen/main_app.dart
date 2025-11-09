import 'package:flutter/material.dart';
import 'package:euro_medical_card/screen/map.dart';
import 'package:euro_medical_card/screen/profile.dart';
import 'package:euro_medical_card/screen/partners.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'card_data.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0; // Start on Home
  final List<Widget> _widgetOptions = const [
    MapData(),
    HomeScreen(),
    PartnersScreen(),
    Profile(),
  ];

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact(); // ✅ adds nice touch feedback
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final double iconSize = isLandscape ? 18.w : 22.w;
    final double fontSize = isLandscape ? 10.sp : 12.sp;

    return Scaffold(
      extendBody: true,
      appBar: isLandscape
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 3,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min, // Keeps it centered and tight
                children: [
                  Image.asset(
                    'assets/icons/logo.png',
                    color: Colors.white,
                    width: 35,
                    height: 35,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'Euro Medical Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            selectedFontSize: fontSize,
            unselectedFontSize: fontSize,
            showUnselectedLabels: true,
            iconSize: iconSize,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.mapLocation),
                label: 'الخريطة',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.stethoscope),
                label: 'الشبكة الطبية',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.handshake),
                label: 'كبار الشركاء',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.comments),
                label: 'التواصل',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
