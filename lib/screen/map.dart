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
  // --- Constants ---
  static const String _providersUrl =
      "https://providers.euro-assist.com/api/arabic-providers";

  // --- State Variables ---
  _MapStatus _status = _MapStatus.loading;
  String? _errorMessage;
  LatLng? _currentLocation;
  List<Map<String, dynamic>> _allProviders = [];
  List<Map<String, dynamic>> _filteredProviders = [];
  dynamic _selectedMarkerId;

  // --- Controllers & Subscriptions ---
  GoogleMapController? _mapController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final TextEditingController _searchController = TextEditingController();
  String? _mapStyle;

  // --- UI State ---
  bool _isOffline = false;
  bool _showLegend = false;
  bool _isFilterOverlayVisible = false;
  Set<String> _selectedTypes = {};

  // --- Caches & Data ---
  final Map<String, BitmapDescriptor> _typeBitmapCache = {};
  final Map<String, BitmapDescriptor> _typeBitmapCacheSelected = {};
  final List<Map<String, dynamic>> _sampleData = [
    // Sample data...
  ];
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
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _connectivitySubscription?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Initialization ---
  Future<void> _initialize() async {
    _setupConnectivityListener();
    await _loadMapStyle();
    await _generateTypeIcons();
    _loadData();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (!mounted) return;
      final isConnected =
          result.isNotEmpty && result.first != ConnectivityResult.none;
      setState(() => _isOffline = !isConnected);
      if (isConnected)
        _loadData();
      else
        _showRetryDialog("لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك.");
    });
  }

  Future<void> _loadMapStyle() async {
    try {
      _mapStyle =
          await rootBundle.loadString('assets/map_styles/map_style.json');
    } catch (e) {
      debugPrint('Error loading map style: $e');
    }
  }

  // --- Data & Filtering Logic ---
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _status = _MapStatus.loading);

    try {
      final results = await Future.wait([
        _LocationService.getCurrentLocation(context),
        _ApiHelper.fetchProviders(_providersUrl, _sampleData),
      ]);
      if (!mounted) return;

      setState(() {
        _currentLocation = results[0] as LatLng?;
        _allProviders = results[1] as List<Map<String, dynamic>>;
        _applyFilters();
        _status = _MapStatus.success;
      });
      if (_currentLocation != null) {
        _animateToLocation(_currentLocation!, zoom: 14.0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _MapStatus.failure;
        _errorMessage = e.toString();
      });
    }
  }

  void _performSearch() {
    FocusScope.of(context).unfocus();
    _applyFilters();
  }

  void _onSearchTextChanged() {
    setState(() {});
  }

  void _applyFilters() {
    if (!mounted) return;

    final query = _searchController.text.toLowerCase().trim();
    var filtered = List<Map<String, dynamic>>.from(_allProviders);

    if (_selectedTypes.isNotEmpty) {
      filtered =
          filtered.where((p) => _selectedTypes.contains(p['type'])).toList();
    }

    if (query.length >= 3) {
      filtered = filtered.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final city = (p['city'] ?? '').toString().toLowerCase();
        final district = (p['district'] ?? '').toString().toLowerCase();
        final address = (p['address'] ?? '').toString().toLowerCase();
        final phone = (p['phone'] ?? '').toString().toLowerCase();
        final type = (p['type'] ?? '').toString().toLowerCase();

        int? priority;

        if (name.contains(query)) {
          priority = 0;
        } else if (city.contains(query)) {
          priority = 1;
        } else if (district.contains(query)) {
          priority = 2;
        } else if (address.contains(query)) {
          priority = 3;
        } else if (phone.contains(query)) {
          priority = 4;
        } else if (type.contains(query)) {
          priority = 5;
        }

        if (priority != null) {
          p['_matchPriority'] = priority;
          return true;
        }

        p.remove('_matchPriority');
        return false;
      }).toList();
    } else {
      for (final provider in filtered) {
        provider.remove('_matchPriority');
      }
    }

    if (_currentLocation != null) {
      for (var provider in filtered) {
        final lat = provider['latitude'];
        final lng = provider['longitude'];
        if (lat is num && lng is num) {
          provider['distance'] = Geolocator.distanceBetween(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
              lat.toDouble(),
              lng.toDouble());
        } else {
          provider['distance'] = double.maxFinite;
        }
      }
    }

    filtered.sort((a, b) {
      final priorityA = (a['_matchPriority'] ?? 999) as int;
      final priorityB = (b['_matchPriority'] ?? 999) as int;
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      final distanceA = (a['distance'] ?? double.maxFinite) as double;
      final distanceB = (b['distance'] ?? double.maxFinite) as double;
      return distanceA.compareTo(distanceB);
    });

    if (query.length < 3) {
      for (final provider in filtered) {
        provider.remove('_matchPriority');
      }
    }

    setState(() => _filteredProviders = filtered);
    _zoomToFilteredMarkers();
  }

  // --- UI Build Methods ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildFloatingActionButtons(),
      body: Stack(
        children: [
          _buildMapContent(),
          _buildTopBarAndFilterOverlay(),
          if (_isOffline) _buildOfflineBanner(),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildTopBarAndFilterOverlay() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
            child: Row(
              children: [
                _buildFilterToggleButton(),
                SizedBox(width: 8.w),
                Expanded(child: _buildSearchBar()),
              ],
            ),
          ),
          _buildFilterOverlay(),
        ],
      ),
    );
  }

  Widget _buildFilterToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            _isFilterOverlayVisible ? Icons.close : Icons.filter_list,
            key: ValueKey<bool>(_isFilterOverlayVisible),
            color: Theme.of(context).primaryColor,
          ),
        ),
        onPressed: () {
          setState(() => _isFilterOverlayVisible = !_isFilterOverlayVisible);
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: _searchController,
        textAlign: TextAlign.right,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _performSearch(),
        decoration: InputDecoration(
          hintText: 'ابحث عن مستشفى، صيدلية، مدينة...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
            onPressed: _performSearch,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                    _applyFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildFilterOverlay() {
    return AnimatedOpacity(
      opacity: _isFilterOverlayVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_isFilterOverlayVisible,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 15.w),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
            ),
            itemCount: _typeIconMap.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAllChip();
              }
              final entry = _typeIconMap.entries.elementAt(index - 1);
              return _buildCategoryChip(entry.key, entry.value);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAllChip() {
    final isSelected = _selectedTypes.isEmpty;
    return FilterChip(
      label: const Text('الكل'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedTypes.clear());
          _applyFilters();
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildCategoryChip(String typeName, Map<String, dynamic> typeInfo) {
    final isSelected = _selectedTypes.contains(typeName);
    return FilterChip(
      avatar: Icon(
        typeInfo['icon'],
        size: 18.sp,
        color: isSelected ? Colors.white : typeInfo['color'],
      ),
      label: Text(typeName),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTypes.add(typeName);
          } else {
            _selectedTypes.remove(typeName);
          }
        });
        _applyFilters();
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: typeInfo['color'],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
      checkmarkColor: Colors.white,
    );
  }

  // --- Other Methods & Widgets ---
  // All other methods like _buildMapContent, _zoomToFilteredMarkers, _generateTypeIcons,
  // _animateToLocation, _goToMyLocation, _showProviderDetails, _showRetryDialog,
  // _buildFloatingActionButtons, _buildMarkersSet, _buildLegend, _buildOfflineBanner,
  // and the helper classes remain the same as the previous version.
  // ...
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
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: true,
        );
    }
  }

  void _zoomToFilteredMarkers() {
    if (!mounted || _filteredProviders.isEmpty || _mapController == null)
      return;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.w));
    });
  }

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

  void _animateToLocation(LatLng position, {double zoom = 14.0}) {
    if (!mounted) return;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
  }

  Future<void> _goToMyLocation() async {
    try {
      final position = await _LocationService.getCurrentLocation(context);
      if (!mounted) return;

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

  Widget _buildFloatingActionButtons() {
    return Padding(
      padding: EdgeInsets.only(bottom: 85.h),
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
                snippet:
                    '${item['type']}${item.containsKey('distance') ? ' - ${((item['distance'] as double) / 1000).toStringAsFixed(1)} km' : ''}',
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

// --- Helper Classes & Widgets ---
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
