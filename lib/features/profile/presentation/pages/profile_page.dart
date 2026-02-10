import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../di/injection_container.dart';
import '../../../auth/domain/entities/member_entity.dart';
import '../../../auth/presentation/cubit/auth/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late final AuthCubit _authCubit;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _authCubit = sl<AuthCubit>();
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

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
    final formattedNumber = _formatPhoneNumber(phoneNumber);
    final whatsappUri = Uri.parse('https://wa.me/$formattedNumber');

    try {
      if (await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
        return;
      }
      await Clipboard.setData(ClipboardData(text: whatsappUri.toString()));
      debugPrint('نسخ رابط واتساب إلى الحافظة');
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: whatsappUri.toString()));
      debugPrint('خطأ أثناء محاولة فتح واتساب: $e');
    }
  }

  String _formatPhoneNumber(String number) {
    number = number.replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.startsWith('+')) {
      return number.substring(1);
    } else if (number.startsWith('00')) {
      return number.substring(2);
    } else if (number.startsWith('0')) {
      return '20${number.substring(1)}';
    } else {
      return number;
    }
  }

  Future<void> _downloadCard(int memberId) async {
    setState(() => _isDownloading = true);

    try {
      // Debugging requirements
      // ignore: avoid_print
      print('[DOWNLOAD] start memberId=$memberId');

      // Request permission properly (Android 13+/legacy)
      final storageStatus = await Permission.storage.request();
      final photosStatus = await Permission.photos.request();

      // Debugging requirements
      // ignore: avoid_print
      print(
          '[DOWNLOAD] permission storage=$storageStatus photos=$photosStatus');

      final hasPermission = storageStatus.isGranted ||
          photosStatus.isGranted ||
          Platform.isIOS;

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يجب منح إذن التخزين لتنزيل البطاقة'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Download image bytes
      final url = 'http://euroassist.3utilities.com:5001/debug/card-raw/$memberId';
      // ignore: avoid_print
      print('[DOWNLOAD] url=$url');
      
      // Save to app-specific external directory on Android (no shared Downloads dependency)
      final Directory? baseDir = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      if (baseDir == null) throw Exception('Could not access storage directory');

      final targetDir = Directory('${baseDir.path}/EuroMedicalCard');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final file = File('${targetDir.path}/medical_card_$memberId.png');
      
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data ?? <int>[];
      // Debugging requirements
      // ignore: avoid_print
      print('[DOWNLOAD] status=${response.statusCode} bytes=${bytes.length}');

      if (bytes.isEmpty) {
        throw Exception('لم يتم استلام بيانات الصورة');
      }

      await file.writeAsBytes(bytes);

      // Debugging requirements
      // ignore: avoid_print
      print('[DOWNLOAD] saved path=${file.path} bytes=${bytes.length}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ البطاقة: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('[DOWNLOAD] exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تنزيل البطاقة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authCubit.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _buildProfileContent(state.member);
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(MemberEntity member) {
    final memberId = member.memberId;
    final memberName = member.memberName;
    final templateName = member.templateName;

    // Debugging requirements
    // ignore: avoid_print
    print(
        '[PROFILE] build memberId=$memberId memberName="$memberName" templateName="$templateName"');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 24.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header
              _buildProfileHeader(memberName, templateName, memberId),
              SizedBox(height: 16.h),
              // Membership Card Preview
              _buildCardPreview(memberId),
              SizedBox(height: 24.h),
              // Contact & Social Section
              _buildContactSection(),
              SizedBox(height: 24.h),
              // Logout Button
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String templateName, int memberId) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            templateName,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Member ID: $memberId',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview(int memberId) {
    final cardUrl = 'http://euroassist.3utilities.com:5001/debug/card-raw/$memberId';
    // Debugging requirements
    // ignore: avoid_print
    print('[PROFILE] cardUrl=$cardUrl');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Card',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: AspectRatio(
              aspectRatio: 1.6,
              child: memberId <= 0
                  ? Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Text(
                          'لا يوجد رقم عضو صالح',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    )
                  : Image.network(
                      cardUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // Debugging requirements
                        // ignore: avoid_print
                        print('[PROFILE] card image error: $error');
                        return Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48.w,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8.h),
                              const Text('فشل تحميل البطاقة'),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : () => _downloadCard(memberId),
              icon: _isDownloading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(_isDownloading ? 'جاري التنزيل...' : 'Download Card'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact & Social',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          // Phone buttons
          _buildContactButton(
            icon: FontAwesomeIcons.phone,
            label: 'الخط الساخن',
            phone: '+20233001122',
            color: Colors.green.shade600,
            onPressed: () => _makePhoneCall('+20233001122'),
          ),
          SizedBox(height: 12.h),
          _buildContactButton(
            icon: FontAwesomeIcons.mobile,
            label: 'رقم الموبايل',
            phone: '+201111768519',
            color: Colors.blue.shade600,
            onPressed: () => _makePhoneCall('+201111768519'),
          ),
          SizedBox(height: 12.h),
          _buildContactButton(
            icon: FontAwesomeIcons.whatsapp,
            label: 'واتساب',
            phone: '201111768519',
            color: Colors.green,
            onPressed: () => _openWhatsApp('201111768519'),
          ),
          SizedBox(height: 20.h),
          const Divider(),
          SizedBox(height: 16.h),
          // Social media
          Text(
            'تابعنا على وسائل التواصل الاجتماعي',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialIcon(
                icon: FontAwesomeIcons.facebook,
                color: Colors.blue,
                url: 'https://www.facebook.com/share/1KvhiRG6RB/',
                label: 'فيسبوك',
              ),
              _buildSocialIcon(
                icon: FontAwesomeIcons.instagram,
                color: Colors.purple,
                url: 'https://www.instagram.com/euromedicalcard',
                label: 'انستغرام',
              ),
              _buildSocialIcon(
                icon: FontAwesomeIcons.youtube,
                color: Colors.red,
                url: 'https://www.youtube.com/@euroassist',
                label: 'يوتيوب',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required String phone,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
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
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                FaIcon(icon, color: Colors.white, size: 20.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildSocialIcon({
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
            icon: FaIcon(icon, color: color, size: 24.w),
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

  Widget _buildLogoutButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

}
