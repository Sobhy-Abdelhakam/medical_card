import 'package:euro_medical_card/core/localization/app_localizations.dart';
import 'package:euro_medical_card/features/map/presentation/pages/map_page.dart';
import 'package:euro_medical_card/features/profile/presentation/pages/profile_page.dart';
import 'package:euro_medical_card/features/providers/presentation/pages/medical_network_page.dart';
import 'package:euro_medical_card/features/providers/presentation/pages/partners_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Main application shell with bottom navigation
class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MapData(),
    const MedicalNetworkPage(),
    const PartnersPage(),
    const Profile(),
  ];

  final Set<int> _visitedIndices = {0};

  @override
  void initState() {
    super.initState();
    // Ensure the initial page is marked as visited
    _visitedIndices.add(_selectedIndex);
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
      _visitedIndices.add(index);
    });
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
          : _selectedIndex == 0
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/logo.png',
                        color: Colors.white,
                        width: 35,
                        height: 35,
                      ),
                      const SizedBox(width: 3),
                      const Text(
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
          children: List.generate(_pages.length, (index) {
            if (_visitedIndices.contains(index)) {
              return _pages[index];
            }
            return const SizedBox.shrink();
          }),
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
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
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.map_outlined),
                activeIcon: const Icon(Icons.map),
                label: context.tr('nav_map'),
              ),
              BottomNavigationBarItem(
                icon: const FaIcon(FontAwesomeIcons.stethoscope),
                label: context.tr('nav_providers'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.handshake_outlined),
                activeIcon: const Icon(Icons.handshake),
                label: context.tr('nav_partners'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: context.tr('nav_profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
