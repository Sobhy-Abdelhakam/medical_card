import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../di/injection_container.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../map/presentation/pages/map_page.dart';
import '../../../member_card/presentation/cubit/member_card_cubit.dart';
import '../../../member_card/presentation/pages/member_card_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../providers/presentation/pages/medical_network_page.dart';
import '../../../providers/presentation/pages/partners_page.dart';

/// Main application shell with bottom navigation
class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;
  final Set<int> _visitedIndices = {0};

  // Guest mode pages (4 tabs)
  final List<Widget> _guestPages = const [
    MapData(),
    MedicalNetworkPage(),
    PartnersPage(),
    Profile(),
  ];

  // Guest mode navigation items
  final List<BottomNavigationBarItem> _guestNavItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.map_outlined),
      activeIcon: Icon(Icons.map),
      label: 'الخريطة',
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.stethoscope),
      label: 'الشبكة الطبية',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.handshake_outlined),
      activeIcon: Icon(Icons.handshake),
      label: 'كبار الشركاء',
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.comments),
      activeIcon: FaIcon(FontAwesomeIcons.solidComments),
      label: 'التواصل',
    ),
  ];

  // Authenticated mode navigation items (5 tabs)
  final List<BottomNavigationBarItem> _authNavItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.map_outlined),
      activeIcon: Icon(Icons.map),
      label: 'الخريطة',
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.stethoscope),
      label: 'الشبكة الطبية',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.credit_card_outlined),
      activeIcon: Icon(Icons.credit_card),
      label: 'البطاقة',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.handshake_outlined),
      activeIcon: Icon(Icons.handshake),
      label: 'كبار الشركاء',
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.comments),
      activeIcon: FaIcon(FontAwesomeIcons.solidComments),
      label: 'التواصل',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _visitedIndices.add(_selectedIndex);
    // Check auth status on init
    context.read<AuthCubit>().checkAuthStatus();
  }

  void _onItemTapped(int index, bool isAuthenticated) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
      _visitedIndices.add(index);
    });
  }

  Future<void> _navigateToLogin() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: const LoginPage(),
        ),
      ),
    );

    if (result == true && mounted) {
      // Login successful - reset to first tab
      setState(() {
        _selectedIndex = 0;
        _visitedIndices.clear();
        _visitedIndices.add(0);
      });
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              this.context.read<AuthCubit>().logout();
              // Reset navigation
              setState(() {
                _selectedIndex = 0;
                _visitedIndices.clear();
                _visitedIndices.add(0);
              });
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final double iconSize = isLandscape ? 18.w : 22.w;
    final double fontSize = isLandscape ? 10.sp : 12.sp;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isAuthenticated = authState is AuthAuthenticated;
        final navItems = isAuthenticated ? _authNavItems : _guestNavItems;

        // Ensure selected index is valid for current nav items
        if (_selectedIndex >= navItems.length) {
          _selectedIndex = 0;
        }

        return Scaffold(
          extendBody: true,
          appBar: isLandscape
              ? null
              : AppBar(
                  backgroundColor: AppColors.primary,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppSpacing.radiusLg),
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
                  foregroundColor: AppColors.onPrimary,
                  actions: [
                    if (isAuthenticated)
                      _buildUserMenu(authState)
                    else
                      _buildLoginButton(),
                  ],
                ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildBody(isAuthenticated),
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
                selectedItemColor: AppColors.primary,
                unselectedItemColor: Colors.grey,
                selectedFontSize: fontSize,
                unselectedFontSize: fontSize,
                showUnselectedLabels: true,
                iconSize: iconSize,
                onTap: (index) => _onItemTapped(index, isAuthenticated),
                items: navItems,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(bool isAuthenticated) {
    if (isAuthenticated) {
      // Authenticated: 5 tabs - Map, Medical, Card, Partners, Contact
      return IndexedStack(
        index: _selectedIndex,
        children: List.generate(5, (index) {
          if (_visitedIndices.contains(index)) {
            switch (index) {
              case 0:
                return const MapData();
              case 1:
                return const MedicalNetworkPage();
              case 2:
                return BlocProvider(
                  create: (_) => sl<MemberCardCubit>(),
                  child: const MemberCardPage(),
                );
              case 3:
                return const PartnersPage();
              case 4:
                return const Profile();
              default:
                return const SizedBox.shrink();
            }
          }
          return const SizedBox.shrink();
        }),
      );
    } else {
      // Guest: 4 tabs - Map, Medical, Partners, Contact
      return IndexedStack(
        index: _selectedIndex,
        children: List.generate(_guestPages.length, (index) {
          if (_visitedIndices.contains(index)) {
            return _guestPages[index];
          }
          return const SizedBox.shrink();
        }),
      );
    }
  }

  Widget _buildLoginButton() {
    return IconButton(
      onPressed: _navigateToLogin,
      icon: const Icon(Icons.login_rounded),
      tooltip: 'تسجيل الدخول',
    );
  }

  Widget _buildUserMenu(AuthState authState) {
    final user = (authState as AuthAuthenticated).user;

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'logout') {
          _handleLogout();
        } else if (value == 'card') {
          setState(() {
            _selectedIndex = 2; // Member card tab
            _visitedIndices.add(2);
          });
        }
      },
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: AppTypography.titleSmall,
              ),
              if (user.memberNumber != null)
                Text(
                  user.memberNumber!,
                  style: AppTypography.caption,
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'card',
          child: Row(
            children: [
              Icon(Icons.credit_card_outlined, size: 20),
              SizedBox(width: 12),
              Text('بطاقة العضوية'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
              SizedBox(width: 12),
              Text('تسجيل الخروج', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : 'U',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
