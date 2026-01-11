import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await Clipboard.setData(ClipboardData(text: url));
        debugPrint('تم نسخ الرابط لعدم التمكن من فتحه: $url');
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: url));
      debugPrint('استثناء عند محاولة الفتح، تم نسخ الرابط: $url');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      debugPrint('لا يمكن إجراء المكالمة');
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, BuildContext? ctx) async {
    final formattedNumber = _formatPhoneNumber(phoneNumber);
    final whatsappUri = Uri.parse('https://wa.me/$formattedNumber');

    debugPrint('whatsappUri: $whatsappUri');
    try {
      if (await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
        return;
      }
      await Clipboard.setData(ClipboardData(text: whatsappUri.toString()));
      debugPrint('نسخ رابط واتساب إلى الحافظة (لا يوجد معالج): $whatsappUri');
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: whatsappUri.toString()));
      debugPrint('خطأ أثناء محاولة فتح واتساب، تم نسخ الرابط: $e');
    }
  }

  String _formatPhoneNumber(String number) {
    number = number.replaceAll(
        RegExp(r'[^0-9+]'), ''); // Remove spaces, dashes, etc.
    if (number.startsWith('+')) {
      return number.substring(1); // remove '+'
    } else if (number.startsWith('00')) {
      return number.substring(2);
    } else if (number.startsWith('0')) {
      // Replace with your country code (example: Egypt = 20)
      return '20${number.substring(1)}';
    } else {
      return number;
    }
  }

  void _showContactDialog(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.w),
          ),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (0.5 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isLandscape ? 400.w : 320.w,
              ),
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.contact_phone_rounded,
                      size: isLandscape ? 32.w : 40.w,
                      color: theme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'اختر طريقة التواصل',
                    style: TextStyle(
                      fontSize: isLandscape ? 18.sp : 20.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'يمكنك الاتصال بنا على أي من الأرقام التالية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _buildContactButton(
                    context: context,
                    icon: FontAwesomeIcons.phone,
                    label: 'الخط الساخن',
                    phone: '+20233001122',
                    color: Colors.green.shade600,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _makePhoneCall('+20233001122');
                    },
                  ),
                  SizedBox(height: 12.h),
                  _buildContactButton(
                    context: context,
                    icon: FontAwesomeIcons.mobile,
                    label: 'رقم الموبايل',
                    phone: '+201111768519',
                    color: Colors.blue.shade600,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _makePhoneCall('+201111768519');
                    },
                  ),
                  SizedBox(height: 24.h),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 18.w),
                        SizedBox(width: 8.w),
                        Text(
                          'إغلاق',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String phone,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.w),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12.w),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.w),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 16.h,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(
                    icon,
                    size: 16.w,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        phone,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;

          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 24.h),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isSmallScreen ? double.infinity : 500,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10.w : 20.w,
                    vertical: 20.h,
                  ),
                  child: Card(
                    elevation: 16,
                    shadowColor: Colors.black38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.all(isSmallScreen ? 20.w : 30.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: isSmallScreen ? 55 : 65,
                              backgroundImage:
                                  const AssetImage('assets/images/logo.jpg'),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 20.h : 25.h),
                          Text(
                            'شبكة طبية متكاملة تغطي كل المحافظات',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 17.sp : 19.sp,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8.h : 12.h),
                          Text(
                            'نحن هنا لمساعدتك في العثور على أفضل الخدمات الطبية',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13.sp : 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 25.h : 35.h),

                          // Contact buttons with enhanced design
                          isSmallScreen
                              ? Column(
                                  children: [
                                    // Force a consistent height so both buttons look identical
                                    SizedBox(
                                      height: 72.h,
                                      width: double.infinity,
                                      child: _buildEnhancedContactButton(
                                        icon: FontAwesomeIcons.whatsapp,
                                        label: 'واتساب',
                                        subtitle: 'تواصل معنا عبر واتساب',
                                        color: Colors.green,
                                        onPressed: () => _openWhatsApp(
                                            '201111768519', context),
                                        isSmall: isSmallScreen,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    SizedBox(
                                      height: 72.h,
                                      width: double.infinity,
                                      child: _buildEnhancedContactButton(
                                        icon: FontAwesomeIcons.phone,
                                        label: 'اتصل بنا',
                                        subtitle: 'اتصل بنا مباشرة',
                                        color: Colors.blue,
                                        onPressed: () =>
                                            _showContactDialog(context),
                                        isSmall: isSmallScreen,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildEnhancedContactButton(
                                        icon: FontAwesomeIcons.whatsapp,
                                        label: 'واتساب',
                                        subtitle: 'تواصل معنا عبر واتساب',
                                        color: Colors.green,
                                        onPressed: () => _openWhatsApp(
                                            '201111768519', context),
                                        isSmall: isSmallScreen,
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      child: _buildEnhancedContactButton(
                                        icon: FontAwesomeIcons.phone,
                                        label: 'اتصل بنا',
                                        subtitle: 'اتصل بنا مباشرة',
                                        color: Colors.blue,
                                        onPressed: () =>
                                            _showContactDialog(context),
                                        isSmall: isSmallScreen,
                                      ),
                                    ),
                                  ],
                                ),

                          SizedBox(height: isSmallScreen ? 25.h : 35.h),

                          // Social media section with enhanced design
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16.w),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.2),
                                width: 1.w,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'تابعنا على وسائل التواصل الاجتماعي',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14.sp : 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildEnhancedSocialIcon(
                                      icon: FontAwesomeIcons.facebook,
                                      color: Colors.blue,
                                      url:
                                          'https://www.facebook.com/share/1KvhiRG6RB/',
                                      label: 'فيسبوك',
                                    ),
                                    _buildEnhancedSocialIcon(
                                      icon: FontAwesomeIcons.instagram,
                                      color: Colors.purple,
                                      url:
                                          'https://www.instagram.com/euromedicalcard',
                                      label: 'انستغرام',
                                    ),
                                    _buildEnhancedSocialIcon(
                                      icon: FontAwesomeIcons.youtube,
                                      color: Colors.red,
                                      url:
                                          'https://www.youtube.com/@euroassist',
                                      label: 'يوتيوب',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedContactButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
    required bool isSmall,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          // Ensure accessible hit target and consistent sizing
          minimumSize: Size(double.infinity, isSmall ? 64.h : 56.h),
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 16.w : 20.w,
            vertical: isSmall ? 8.h : 14.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.w),
          ),
        ),
        // Use a compact horizontal layout on small screens for balance
        child: isSmall
            ? Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        icon,
                        size: 20.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    icon,
                    size: isSmall ? 20.w : 24.w,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmall ? 14.sp : 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isSmall ? 11.sp : 12.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEnhancedSocialIcon({
    required IconData icon,
    required Color color,
    required String url,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: FaIcon(
              icon,
              color: color,
              size: 24.w,
            ),
            onPressed: () => _launchURL(url),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
