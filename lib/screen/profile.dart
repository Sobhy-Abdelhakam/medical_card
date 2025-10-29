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

  Future<void> _openWhatsApp(String phoneNumber) async {
    final Uri whatsappUri = Uri.parse("https://wa.me/$phoneNumber");
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('لا يمكن فتح واتساب');
    }
  }

  void _showContactDialog(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.w),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.w),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.contact_phone,
                    size: isLandscape ? 32.w : 40.w,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'اختر طريقة التواصل',
                  style: TextStyle(
                    fontSize: isLandscape ? 18.sp : 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _makePhoneCall('+20233011444');
                        },
                        icon: FaIcon(FontAwesomeIcons.phone, size: 16.w),
                        label: Text('اتصال', style: TextStyle(fontSize: 14.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.w),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _makePhoneCall('+201111768519');
                        },
                        icon: FaIcon(FontAwesomeIcons.phone, size: 16.w),
                        label: Text('اتصال', style: TextStyle(fontSize: 14.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.w),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                    ),
                    child: Text('إلغاء', style: TextStyle(fontSize: 14.sp)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                            color: Colors.blue[800],
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
                                  _buildEnhancedContactButton(
                                    icon: FontAwesomeIcons.whatsapp,
                                    label: 'واتساب',
                                    subtitle: 'تواصل معنا عبر واتساب',
                                    color: Colors.green,
                                    onPressed: () =>
                                        _openWhatsApp('201111768519'),
                                    isSmall: isSmallScreen,
                                  ),
                                  SizedBox(height: 12.h),
                                  _buildEnhancedContactButton(
                                    icon: FontAwesomeIcons.phone,
                                    label: 'اتصل بنا',
                                    subtitle: 'اتصل بنا مباشرة',
                                    color: Colors.blue,
                                    onPressed: () =>
                                        _showContactDialog(context),
                                    isSmall: isSmallScreen,
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
                                      onPressed: () =>
                                          _openWhatsApp('201111768519'),
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
                                    url: 'https://www.youtube.com/@euroassist',
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
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 16.w : 20.w,
            vertical: isSmall ? 16.h : 20.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.w),
          ),
        ),
        child: Column(
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
