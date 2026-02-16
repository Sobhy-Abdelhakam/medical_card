import 'package:flutter/material.dart';

class AppLocalizations {
  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
  ];

  static const Locale defaultLocale = Locale('ar');

  /// Common
  static const Map<String, Map<String, String>> _translations = {
    'ar': {
      // App
      'app_title': 'يورو ميديكال كارد',
      'app_name': 'Euro Medical Card',

      // Bottom Navigation
      'nav_home': 'الرئيسية',
      'nav_map': 'الخريطة',
      'nav_providers': 'المراكز الطبية',
      'nav_partners': 'شركاؤنا',
      'nav_profile': 'ملفي الشخصي',

      // Home Screen
      'home_welcome': 'مرحباً،',
      'home_find_on_map': 'البحث على الخريطة',
      'home_map_subtitle': 'تحديد مواقع أقرب مقدمي الخدمة',
      'home_medical_network': 'الشبكة الطبية',
      'home_partners': 'شركاؤنا',
      'see_all': 'عرض الكل',

      // Map Screen
      'welcome_back': 'مرحباً!',
      'search_hint': 'ابحث عن مركز صحي...',
      'filter_by_type': 'تصفية حسب النوع',
      'selected_count': 'تم تحديد {count} نوع',
      'reset_filters': 'إعادة تعيين',
      'all_types': 'الكل',
      'legend_title': 'دليل الرموز',
      'location_loading': 'جاري تحديد الموقع...',
      'loading_centers': 'جاري تحميل المراكز الطبية...',

      // Provider Types
      'pharmacy': 'صيدلية',
      'hospital': 'مستشفى',
      'laboratory': 'معامل التحاليل',
      'radiology': 'مراكز الأشعة',
      'physiotherapy': 'علاج طبيعي',
      'specialized_centers': 'مراكز متخصصة',
      'clinic': 'عيادة',
      'optometry': 'بصريات',

      // Provider Details Sheet
      'call_button': 'اتصال',
      'location_button': 'الموقع',
      'select_phone': 'اختر رقم للاتصال',
      'cancel': 'إلغاء',
      'open_maps': 'افتح في خرائط جوجل',
      'call_failed': 'تعذر إجراء المكالمة',
      'maps_failed': 'تعذر فتح خرائط جوجل',

      // Providers Screen
      'select_city': 'اختر مدينة',
      'all_cities': 'كل المدن',
      'load_more': 'تحميل المزيد',

      // Location Permissions
      'location_disabled_title': 'خدمات الموقع معطلة',
      'location_disabled_msg': 'يرجى تفعيل خدمات الموقع لاستخدام هذه الميزة',
      'location_permission_title': 'إذن الموقع',
      'location_permission_msg':
          'يرجى منح إذن الوصول إلى الموقع من إعدادات التطبيق',
      'ok': 'حسناً',
      'settings': 'الإعدادات',

      // Error & Loading States
      'error_title': 'حدث خطأ',
      'retry': 'إعادة المحاولة',
      'empty_state': 'لا توجد بيانات',
      'loading': 'جاري التحميل...',

      // Profile
      'guest': 'ضيف',
    },
    'en': {
      // App
      'app_title': 'Euro Medical Card',
      'app_name': 'Euro Medical Card',

      // Bottom Navigation
      'nav_home': 'Home',
      'nav_map': 'Map',
      'nav_providers': 'Providers',
      'nav_partners': 'Partners',
      'nav_profile': 'Profile',

      // Home Screen
      'home_welcome': 'Welcome,',
      'home_find_on_map': 'Find on Map',
      'home_map_subtitle': 'Locate nearest medical providers',
      'home_medical_network': 'Medical Network',
      'home_partners': 'Our Partners',
      'see_all': 'See All',

      // Map Screen
      'welcome_back': 'Welcome Back!',
      'search_hint': 'Search for a healthcare center...',
      'filter_by_type': 'Filter by Type',
      'selected_count': '{count} type(s) selected',
      'reset_filters': 'Reset',
      'all_types': 'All',
      'legend_title': 'Legend',
      'location_loading': 'Getting your location...',
      'loading_centers': 'Loading healthcare centers...',

      // Provider Types
      'pharmacy': 'Pharmacy',
      'hospital': 'Hospital',
      'laboratory': 'Laboratory',
      'radiology': 'Radiology Center',
      'physiotherapy': 'Physiotherapy',
      'specialized_centers': 'Specialized Centers',
      'clinic': 'Clinic',
      'optometry': 'Optometry',

      // Provider Details Sheet
      'call_button': 'Call',
      'location_button': 'Location',
      'select_phone': 'Select a phone number',
      'cancel': 'Cancel',
      'open_maps': 'Open in Google Maps',
      'call_failed': 'Could not make the call',
      'maps_failed': 'Could not open Google Maps',

      // Providers Screen
      'select_city': 'Select City',
      'all_cities': 'All Cities',
      'load_more': 'Load More',

      // Location Permissions
      'location_disabled_title': 'Location Services Disabled',
      'location_disabled_msg':
          'Please enable location services to use this feature',
      'location_permission_title': 'Location Permission',
      'location_permission_msg':
          'Please grant location access from app settings',
      'ok': 'OK',
      'settings': 'Settings',

      // Error & Loading States
      'error_title': 'Error',
      'retry': 'Retry',
      'empty_state': 'No data available',
      'loading': 'Loading...',

      // Profile
      'guest': 'Guest',
    },
  };

  static String translate(String key, {String? locale}) {
    locale ??= defaultLocale.languageCode;
    return _translations[locale]?[key] ?? key;
  }

  static String translateWithCount(String key, int count, {String? locale}) {
    locale ??= defaultLocale.languageCode;
    final template = _translations[locale]?[key] ?? key;
    return template.replaceAll('{count}', count.toString());
  }
}

/// Extension to make translation easier in widgets
extension AppLocalizationsExt on BuildContext {
  String tr(String key) {
    final locale = Localizations.localeOf(this).languageCode;
    return AppLocalizations.translate(key, locale: locale);
  }

  String trWithCount(String key, int count) {
    final locale = Localizations.localeOf(this).languageCode;
    return AppLocalizations.translateWithCount(key, count, locale: locale);
  }

  Locale get currentLocale => Localizations.localeOf(this);
}
