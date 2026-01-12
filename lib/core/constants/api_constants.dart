/// API base URL and endpoint constants
class ApiConstants {
  ApiConstants._();

  /// Base URL for providers API
  static const String baseUrl = 'https://providers.euro-assist.com/api';

  /// Provider Endpoints
  static const String topProviders = '/top-providers';
  static const String arabicProviders = '/arabic-providers';
  static const String arabicProvidersAllLatLng = '/arabic-providers/all-latlng';
  static const String arabicProvidersSearch = '/arabic-providers/search';
  static const String englishProviders = '/providers';
  static const String englishProvidersAllLatLng = '/providers/all-latlng';
  static const String englishProvidersSearch = '/providers/search';

  /// Auth Endpoints
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  /// Member Endpoints
  static const String memberCard = '/member/card';

  /// Query parameter keys
  static const String searchName = 'searchName';
  static const String type = 'type';
  static const String search = 'search';
  static const String city = 'city';
  static const String district = 'district';
  static const String governorate = 'governorate';
  static const String paginate = 'paginate';
  static const String page = 'page';
  static const String perPage = 'per_page';
  static const String query = 'query';
}

/// Storage keys for secure data
class StorageKeys {
  StorageKeys._();

  static const String authToken = 'auth_token';
  static const String userData = 'user_data';
  static const String isLoggedIn = 'is_logged_in';
}

/// Default pagination settings
class PaginationDefaults {
  PaginationDefaults._();

  static const int defaultPage = 1;
  static const int defaultPerPage = 25;
}
