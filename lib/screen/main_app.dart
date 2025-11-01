import 'package:flutter/material.dart';
import 'package:euro_medical_card/screen/map.dart';
import 'package:euro_medical_card/screen/profile.dart';
import 'package:euro_medical_card/screen/partners.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widget/color.dart';
import 'card_data.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() =>
      _MainAppState();
}

class _MainAppState
    extends State<MainApp> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    const MapData(),
    const HomeScreen(),
    const PartnersScreen(),
    const Profile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final double iconSize = isLandscape ? 14.w : 20.w; // Smaller icons for 4 items
    final double fontSize = isLandscape ? 9.sp : 11.sp; // Smaller font for 4 items

    return Scaffold(
      appBar: isLandscape ? null : AppBar( // Hide AppBar in landscape mode
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Euro Medical Card', style: TextStyle(color: Colors.white)),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: FaIcon(
              FontAwesomeIcons.mapLocation,
              size: iconSize,
            ),
            label: 'الخريطة',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(
              FontAwesomeIcons.stethoscope,
              size: iconSize,
            ),
            label: 'الشبكة الطبية',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(
              FontAwesomeIcons.handshake,
              size: iconSize,
            ),
            label: 'كبار الشركاء',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(
              FontAwesomeIcons.comments,
              size: iconSize,
            ),
            label: 'التواصل',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        backgroundColor: AppColors.primary,
        selectedLabelStyle: TextStyle(
          fontSize: fontSize,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSize,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}