import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:ui' as ui;

enum _MapStatus { loading, success, failure }

class MapData extends StatefulWidget {
  const MapData({super.key});

  @override
  State<MapData> createState() => _MapDataState();
}

class _MapDataState extends State<MapData> {
  // URL for providers API
  static const String _providersUrl =
      "https://providers.euro-assist.com/api/arabic-providers";

  // State variables
  _MapStatus _status = _MapStatus.loading;
  String? _errorMessage;
  LatLng? _currentLocation;
  List<Map<String, dynamic>> _allProviders = [];
  List<Map<String, dynamic>> _filteredProviders = [];
  dynamic _selectedMarkerId;

  // Controllers and Subscriptions
  GoogleMapController? _mapController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final TextEditingController _searchController = TextEditingController();
  String? _mapStyle;

  // UI flags
  bool _isOffline = false;
  bool _showLegend = false;

  // Caches for custom markers
  final Map<String, BitmapDescriptor> _typeBitmapCache = {};
  final Map<String, BitmapDescriptor> _typeBitmapCacheSelected = {};

  // Sample data for testing or offline mode
  final List<Map<String, dynamic>> _sampleData = [
    {
      'id': 1,
      'name': 'صيدلية النور',
      'type': 'صيدلية',
      'latitude': 30.0444,
      'longitude': 31.2357,
      'address': 'شارع القاهرة، القاهرة',
      'city': 'القاهرة',
      'phone': '0123456789',
      'discount_pct': '15%',
    },
    {
      'id': 2,
      'name': 'مستشفى السلام',
      'type': 'مستشفى',
      'latitude': 30.0544,
      'longitude': 31.2457,
      'address': 'شارع السلام، القاهرة',
      'city': 'القاهرة',
      'phone': '0123456790',
      'discount_pct': '20%',
    },
  ];

  // Map provider types to icons and colors for the legend and markers
  final Map<String, Map<String, dynamic>> _typeIconMap = {
    'صيدلية': {'icon': Icons.local_pharmacy, 'color': Colors.green},
    'مستشفى': {'icon': Icons.local_hospital, 'color': Colors.red},
    'معمل تحاليل': {'icon': Icons.science, 'color': Colors.blue},
    'مراكز الأشعة': {
      'icon': Icons.medical_services,
      'color': Colors.deepPurple
    },
    'علاج طبيعي': {'icon': Icons.accessibility_new, 'color': Colors.orange},
    'مركز متخصص': {'icon': Icons.star, 'color': Colors.teal},
    'عيادة': {'icon': Icons.local_hospital, 'color': Colors.pink},
    'بصريات': {'icon': Icons.visibility, 'color': Colors.brown},
  };

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(_onSearchChanged);
  }

  Timer? _debounce;

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Initializes connectivity listener, loads map style and all required data
  Future<void> _initialize() async {
    _setupConnectivityListener();
    await _loadMapStyle();
    await _generateTypeIcons();
    _loadData();
  }

  // Sets up a listener to react to connectivity changes
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      final isConnected =
          result.isNotEmpty && result.first != ConnectivityResult.none;
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });
        if (isConnected) {
          _loadData(); // Reload data when connection is back
        } else {
          _showRetryDialog("لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك.");
        }
      }
    });
  }

  // Loads the custom map style from assets
  Future<void> _loadMapStyle() async {
    try {
      _mapStyle =
          await rootBundle.loadString('assets/map_styles/map_style.json');
    } catch (e) {
      debugPrint('Error loading map style: $e');
    }
  }

  // Main data loading orchestration
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _status = _MapStatus.loading;
    });

    try {
      // Fetch location and providers in parallel
      final results = await Future.wait([
        _LocationService.getCurrentLocation(context),
        _ApiHelper.fetchProviders(_providersUrl, _sampleData),
      ]);

      if (mounted) {
        setState(() {
          _currentLocation = results[0] as LatLng?;
          _allProviders = results[1] as List<Map<String, dynamic>>;
          _filteredProviders = _allProviders;
          _status = _MapStatus.success;
        });
        if (_currentLocation != null) {
          _animateToLocation(_currentLocation!, zoom: 14.0);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = _MapStatus.failure;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // --- Search Logic ---
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      final query = _searchController.text.toLowerCase().trim();

      // Reset if query is empty
      if (query.isEmpty) {
        if (_filteredProviders.length != _allProviders.length) {
          setState(() {
            _filteredProviders = _allProviders;
          });
        }
        return;
      }

      // Only search if 3 or more characters are typed
      if (query.length < 3) {
        return;
      }

      final filtered = _allProviders.where((provider) {
        final name = (provider['name'] ?? '').toLowerCase();
        final city = (provider['city'] ?? '').toLowerCase();
        final type = (provider['type'] ?? '').toLowerCase();
        return name.contains(query) ||
            city.contains(query) ||
            type.contains(query);
      }).toList();

      setState(() {
        _filteredProviders = filtered;
      });

      _zoomToFilteredMarkers();
    });
  }

  void _zoomToFilteredMarkers() {
    if (_filteredProviders.isEmpty || _mapController == null) return;

    if (_filteredProviders.length == 1) {
      final provider = _filteredProviders.first;
      final lat = (provider['latitude'] as num?)?.toDouble();
      final lng = (provider['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        _animateToLocation(LatLng(lat, lng), zoom: 15.0);
      }
      return;
    }

    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;

    for (final provider in _filteredProviders) {
      final lat = (provider['latitude'] as num?)?.toDouble();
      final lng = (provider['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        minLat = lat < minLat ? lat : minLat;
        maxLat = lat > maxLat ? lat : maxLat;
        minLng = lng < minLng ? lng : minLng;
        maxLng = lng > maxLng ? lng : maxLng;
      }
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Add a delay to ensure the map has rendered before animating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.w));
    });
  }

  // --- Map and UI Logic ---

  // Generates custom bitmap icons for each provider type
  Future<void> _generateTypeIcons() async {
    try {
      for (final entry in _typeIconMap.entries) {
        final iconData = entry.value['icon'] as IconData;
        final color = entry.value['color'] as Color;
        _typeBitmapCache[entry.key] =
            await _BitmapGenerator.fromIcon(iconData, color, size: 120);
        _typeBitmapCacheSelected[entry.key] = await _BitmapGenerator.fromIcon(
            iconData, color,
            size: 180, isSelected: true);
      }
      // Default icons
      _typeBitmapCache['default'] = await _BitmapGenerator.fromIcon(
          Icons.location_on, Colors.blue,
          size: 120);
      _typeBitmapCacheSelected['default'] = await _BitmapGenerator.fromIcon(
          Icons.location_on, Colors.blue,
          size: 180, isSelected: true);
    } catch (e) {
      debugPrint('Error generating icons: $e');
    }
  }

  // Animates map to a specific location
  void _animateToLocation(LatLng position, {double zoom = 14.0}) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
  }

  // Fetches current location and animates the map
  Future<void> _goToMyLocation() async {
    try {
      final position = await _LocationService.getCurrentLocation(context);
      if (position != null) {
        setState(() {
          _currentLocation = position;
        });
        _animateToLocation(position, zoom: 14.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), textAlign: TextAlign.right),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Shows provider details in a bottom sheet
  void _showProviderDetails(Map<String, dynamic> provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => _ProviderDetailsSheet(provider: provider),
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _selectedMarkerId = null;
        });
      }
    });
  }

  // Dialog for retrying actions
  void _showRetryDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تنبيه", textAlign: TextAlign.right),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadData();
            },
            child: const Text("إعادة المحاولة"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("موافق"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildFloatingActionButtons(),
      body: Stack(
        children: [
          _buildMapContent(),
          _buildSearchBar(),
          if (_isOffline) _buildOfflineBanner(),
          _buildLegend(),
        ],
      ),
    );
  }

  // Builds the stacked floating action buttons
  Widget _buildFloatingActionButtons() {
    return Padding(
      padding: EdgeInsets.only(bottom: 50.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "my_location",
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            onPressed: _goToMyLocation,
            child: const Icon(Icons.my_location),
          ),
          SizedBox(height: 16.h),
          FloatingActionButton(
            heroTag: "legend",
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () => setState(() => _showLegend = !_showLegend),
            child: Icon(_showLegend ? Icons.close : Icons.info_outline,
                color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Builds the main content based on the current status
  Widget _buildMapContent() {
    switch (_status) {
      case _MapStatus.loading:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary),
              SizedBox(height: 20.h),
              const Text('جاري تحميل الخريطة والبيانات...',
                  style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      case _MapStatus.failure:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 16.h),
              Text(_errorMessage ?? "حدث خطأ غير متوقع.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16)),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text("إعادة المحاولة"),
              ),
            ],
          ),
        );
      case _MapStatus.success:
        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: _currentLocation ?? const LatLng(30.0444, 31.2357), // Cairo
            zoom: 12.0,
          ),
          markers: _buildMarkersSet(),
          onMapCreated: (controller) {
            _mapController = controller;
            _mapController?.setMapStyle(_mapStyle);
            if (_currentLocation != null) {
              _animateToLocation(_currentLocation!, zoom: 14.0);
            }
          },
          onTap: (_) {
            if (_selectedMarkerId != null) {
              setState(() {
                _selectedMarkerId = null;
              });
            }
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false, // Disabled default button
          zoomControlsEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: true,
        );
    }
  }

  // Builds the search bar widget, wrapped in SafeArea
  Widget _buildSearchBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))
            ],
          ),
          child: TextField(
            controller: _searchController,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'ابحث عن مستشفى، صيدلية، مدينة...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon:
                  Icon(Icons.search, color: Theme.of(context).primaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus(); // Hide keyboard
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            ),
          ),
        ),
      ),
    );
  }

  // Creates the set of markers for the map
  Set<Marker> _buildMarkersSet() {
    final markers = <Marker>{};
    for (var item in _filteredProviders) {
      try {
        final lat = (item['latitude'] as num?)?.toDouble();
        final lng = (item['longitude'] as num?)?.toDouble();

        if (lat != null &&
            lng != null &&
            lat >= -90 &&
            lat <= 90 &&
            lng >= -180 &&
            lng <= 180) {
          final type = item['type'] ?? '';
          final isSelected = item['id'] == _selectedMarkerId;
          final icon = isSelected
              ? (_typeBitmapCacheSelected[type] ??
                  _typeBitmapCacheSelected['default']!)
              : (_typeBitmapCache[type] ?? _typeBitmapCache['default']!);

          markers.add(
            Marker(
              markerId: MarkerId(item['id'].toString()),
              position: LatLng(lat, lng),
              icon: icon,
              zIndex: isSelected ? 1.0 : 0.0,
              anchor: const Offset(0.5, 1.0),
              infoWindow: InfoWindow(
                title: item['name'] ?? 'Unknown',
                snippet: item['type'] ?? '',
              ),
              onTap: () {
                _animateToLocation(LatLng(lat, lng), zoom: 15.0);
                setState(() {
                  _selectedMarkerId = item['id'];
                });
                _showProviderDetails(item);
              },
            ),
          );
        }
      } catch (e) {
        debugPrint('Error creating marker for item ${item['id']}: $e');
      }
    }
    return markers;
  }

  // Builds the legend widget
  Widget _buildLegend() {
    return IgnorePointer(
      ignoring: !_showLegend,
      child: AnimatedOpacity(
        opacity: _showLegend ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: _showLegend
            ? _LegendWidget(
                typeIconMap: _typeIconMap,
                onClose: () => setState(() => _showLegend = false),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  // Builds the offline banner
  Widget _buildOfflineBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.red,
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 12.w),
        child: const Text(
          'أنت غير متصل بالإنترنت',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// --- Helper Classes ---

// Handles all location-related logic
class _LocationService {
  static Future<LatLng?> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showLocationServiceDialog(context);
      throw "خدمة الموقع غير مفعلة.";
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw "تم رفض إذن الوصول للموقع.";
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _showPermissionDialog(context);
      throw "تم رفض إذن الموقع بشكل دائم.";
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw "فشل في تحديد الموقع الحالي.";
    }
  }

  static Future<void> _showLocationServiceDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خدمة الموقع', textAlign: TextAlign.right),
        content: const Text(
            'خدمة الموقع غير مفعلة. هل تريد فتح الإعدادات لتفعيلها؟',
            textAlign: TextAlign.right),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Navigator.of(context).pop();
              },
              child: const Text('فتح الإعدادات')),
        ],
      ),
    );
  }

  static Future<void> _showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إذن الموقع', textAlign: TextAlign.right),
        content: const Text(
            'تم رفض إذن الوصول للموقع بشكل دائم. يرجى تفعيله من إعدادات التطبيق.',
            textAlign: TextAlign.right),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () async {
                await Geolocator.openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text('فتح الإعدادات')),
        ],
      ),
    );
  }
}

// Handles API data fetching
class _ApiHelper {
  static Future<List<Map<String, dynamic>>> fetchProviders(
      String url, List<Map<String, dynamic>> sampleData) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
            jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        return sampleData;
      }
    } catch (e) {
      debugPrint('Network error: $e. Using sample data.');
      return sampleData;
    }
  }
}

// Generates BitmapDescriptor from an IconData
class _BitmapGenerator {
  static Future<BitmapDescriptor> fromIcon(IconData iconData, Color color,
      {int size = 120, bool isSelected = false}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double iconSize = size.toDouble();

    if (isSelected) {
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(
          Offset(iconSize / 2, iconSize / 2), iconSize * 0.4, shadowPaint);
    }

    final Paint backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(iconSize / 2, iconSize / 2), iconSize * 0.4, backgroundPaint);

    final Paint borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 8.0 : 4.0;
    canvas.drawCircle(
        Offset(iconSize / 2, iconSize / 2), iconSize * 0.4, borderPaint);

    final TextPainter textPainter =
        TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: iconSize * 0.6,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((iconSize - textPainter.width) / 2,
          (iconSize - textPainter.height) / 2),
    );

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}

// --- UI Widgets ---

// Legend widget showing icon meanings
class _LegendWidget extends StatelessWidget {
  final Map<String, Map<String, dynamic>> typeIconMap;
  final VoidCallback onClose;

  const _LegendWidget({required this.typeIconMap, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      bottom: 20.h,
      left: 10.w,
      right: 10.w,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 5)
          ],
          border: Border.all(color: Colors.grey.shade200, width: 1.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ماذا تعني الرموز',
                  style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
                IconButton(
                  icon: Icon(Icons.cancel,
                      size: 24.w, color: theme.colorScheme.primary),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Divider(height: 1.h, color: Colors.grey[300]),
            SizedBox(height: 12.h),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 4,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
              children: typeIconMap.entries.map((entry) {
                return Row(
                  children: [
                    Icon(entry.value['icon'],
                        size: 24.w, color: entry.value['color']),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet for displaying provider details
class _ProviderDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> provider;

  const _ProviderDetailsSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (_, controller) {
        return Container(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            children: [
              Container(
                width: 40.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    Text(
                      provider['name'] ?? 'غير معروف',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Divider(height: 1.h, color: Colors.grey[300]),
                    SizedBox(height: 12.h),
                    _buildInfoRow('النوع:', provider['type'] ?? ''),
                    _buildInfoRow('العنوان:', provider['address'] ?? ''),
                    _buildInfoRow('المدينة:', provider['city'] ?? ''),
                    _buildInfoRow(
                        'نسبة الخصم:', provider['discount_pct'] ?? ''),
                    if ((provider['phone'] ?? '').isNotEmpty)
                      _buildInfoRow('رقم الهاتف:', provider['phone']),
                    if ((provider['specialization'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty)
                      _buildInfoRow('التخصص:', provider['specialization']),
                    if ((provider['package'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty)
                      _buildInfoRow('الباقات:', provider['package']),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        if ((provider['phone'] ?? '').isNotEmpty)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _makePhoneCall(provider['phone']),
                              icon: Icon(Icons.phone, size: 18.w),
                              label: Text("اتصال",
                                  style: TextStyle(fontSize: 14.sp)),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r)),
                              ),
                            ),
                          ),
                        if ((provider['phone'] ?? '').isNotEmpty)
                          SizedBox(width: 10.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openLocationOnMap(
                              (provider['latitude'] as num).toDouble(),
                              (provider['longitude'] as num).toDouble(),
                            ),
                            icon: Icon(Icons.map, size: 18.w),
                            label: Text("الموقع",
                                style: TextStyle(fontSize: 14.sp)),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri.parse("tel:$phoneNumber");
    if (!await launchUrl(phoneUri)) {
      debugPrint("لا يمكن إجراء المكالمة");
    }
  }

  Future<void> _openLocationOnMap(double latitude, double longitude) async {
    final String url =
        "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('لا يمكن فتح الخرائط');
    }
  }
}
