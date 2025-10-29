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

import '../widget/color.dart';

class MapData extends StatefulWidget {
  const MapData({super.key});

  @override
  State<MapData> createState() => _MapDataState();
}

class _MapDataState extends State<MapData> {
  LatLng? currentLocation;
  Set<Marker> markers = {};
  final String url = "https://providers.euro-assist.com/api/arabic-providers";
  GoogleMapController? _mapController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool isOffline = false;
  bool showLegend = false;
  bool markersLoading = false;
  bool locationLoaded = false;
  bool markersLoaded = false;
  bool locationError = false;
  String? locationErrorMessage;
  bool markersError = false;
  String? markersErrorMessage;
  bool _mapCreated = false;
  bool _cameraAnimating = false;
  bool testMode = false; // Enable test mode for sample data

  // Sample data for testing when API fails
  final List<Map<String, dynamic>> sampleData = [
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
    {
      'id': 3,
      'name': 'معمل التحاليل الطبية',
      'type': 'معمل تحاليل',
      'latitude': 30.0344,
      'longitude': 31.2257,
      'address': 'شارع المعمل، القاهرة',
      'city': 'القاهرة',
      'phone': '0123456791',
      'discount_pct': '10%',
    },
  ];

  // Map provider types to IconData and color
  final Map<String, Map<String, dynamic>> typeIconMap = {
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

  Map<String, BitmapDescriptor> typeBitmapCache = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() async {
    try {
      // Generate icons first
      await _generateTypeIcons();

      // Load location and markers
      _loadLocationAndMarkers();

      // Setup connectivity listener
      _setupConnectivityListener();
    } catch (e) {
      debugPrint('Error initializing map: $e');
      _loadLocationAndMarkers(); // Still try to load location
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (result.isNotEmpty && result.first != ConnectivityResult.none) {
        if (isOffline) {
          setState(() {
            isOffline = false;
          });
          _loadLocationAndMarkers();
        }
      } else {
        setState(() {
          isOffline = true;
        });
        _showRetryDialog(
            "لا يوجد اتصال بالإنترنت. يرجى تشغيله لإعادة تحميل البيانات.");
      }
    });
  }

  void _loadLocationAndMarkers() {
    setState(() {
      locationLoaded = false;
      markersLoaded = false;
      locationError = false;
      markersError = false;
      locationErrorMessage = null;
      markersErrorMessage = null;
      currentLocation = null;
      markers = {};
    });

    // Load location and markers in parallel
    Future.wait([
      getCurrentLocation(),
      fetchMarkers(),
    ]).then((_) {
      setState(() {
        locationLoaded = true;
        markersLoaded = true;
      });
    }).catchError((e) {
      setState(() {
        locationLoaded = true;
        markersLoaded = true;
      });
    });
  }

  Future<void> _generateTypeIcons() async {
    try {
      for (final entry in typeIconMap.entries) {
        final iconData = entry.value['icon'] as IconData;
        final color = entry.value['color'] as Color;
        typeBitmapCache[entry.key] =
            await bitmapDescriptorFromIcon(iconData, color, size: 150);
      }
      // Default icon for unknown types
      typeBitmapCache['default'] = await bitmapDescriptorFromIcon(
          Icons.location_on, Colors.blue,
          size: 150);
      debugPrint('Generated ${typeBitmapCache.length} icons successfully');
    } catch (e) {
      debugPrint('Error generating icons: $e');
      // Fallback to default icons
      typeBitmapCache['default'] = BitmapDescriptor.defaultMarker;
    }
  }

  Future<BitmapDescriptor> bitmapDescriptorFromIcon(
      IconData iconData, Color color,
      {int size = 150}) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      final double iconSize = size.toDouble();

      // Draw white background circle for better visibility
      final Paint backgroundPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(iconSize / 2, iconSize / 2),
        iconSize * 0.4,
        backgroundPaint,
      );

      // Draw colored border
      final Paint borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawCircle(
        Offset(iconSize / 2, iconSize / 2),
        iconSize * 0.4,
        borderPaint,
      );

      // Draw the icon
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
    } catch (e) {
      debugPrint('Error creating bitmap descriptor: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> fetchMarkers() async {
    try {
      setState(() {
        markersLoading = true;
      });

      List<dynamic> data;

      if (testMode) {
        // Use sample data for testing
        data = sampleData;
        debugPrint('Using test mode with ${data.length} sample markers');
      } else {
        // Fetch from API
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw 'Request timeout';
          },
        );

        if (response.statusCode == 200) {
          data = jsonDecode(utf8.decode(response.bodyBytes));
          debugPrint('Fetched ${data.length} markers from API');
        } else {
          debugPrint('API error: ${response.statusCode} - ${response.body}');
          // Fallback to sample data if API fails
          data = sampleData;
          debugPrint('Falling back to sample data');
        }
      }

      Set<Marker> newMarkers = {};
      int validMarkers = 0;

      for (var item in data) {
        try {
          if (item['latitude'] != null && item['longitude'] != null) {
            String type = item['type'] ?? '';
            BitmapDescriptor icon =
                typeBitmapCache[type] ?? typeBitmapCache['default']!;

            double lat = item['latitude'] is int
                ? (item['latitude'] as int).toDouble()
                : item['latitude'];
            double lng = item['longitude'] is int
                ? (item['longitude'] as int).toDouble()
                : item['longitude'];

            // Validate coordinates
            if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
              newMarkers.add(
                Marker(
                  markerId: MarkerId(
                      item['id']?.toString() ?? 'marker_$validMarkers'),
                  position: LatLng(lat, lng),
                  icon: icon,
                  anchor: const Offset(0.5, 1.0), // Center the marker properly
                  infoWindow: InfoWindow(
                    title: item['name'] ?? 'Unknown',
                    snippet: item['type'] ?? '',
                  ),
                  onTap: () {
                    _showProviderDetails(item['id']);
                  },
                ),
              );
              validMarkers++;
            } else {
              debugPrint(
                  'Invalid coordinates: $lat, $lng for item ${item['id']}');
            }
          } else {
            debugPrint('Missing coordinates for item ${item['id']}');
          }
        } catch (e) {
          debugPrint('Error creating marker for item: $e');
        }
      }

      debugPrint('Created $validMarkers valid markers');
      setState(() {
        markers = newMarkers;
        markersLoading = false;
      });
    } catch (e) {
      debugPrint('Network error: $e');
      // Fallback to sample data
      _loadSampleData();
    }
  }

  void _loadSampleData() {
    Set<Marker> newMarkers = {};
    int validMarkers = 0;

    for (var item in sampleData) {
      try {
        String type = item['type'] ?? '';
        BitmapDescriptor icon =
            typeBitmapCache[type] ?? typeBitmapCache['default']!;

        newMarkers.add(
          Marker(
            markerId: MarkerId(item['id'].toString()),
            position: LatLng(item['latitude'], item['longitude']),
            icon: icon,
            anchor: const Offset(0.5, 1.0), // Center the marker properly
            infoWindow: InfoWindow(
              title: item['name'] ?? 'Unknown',
              snippet: item['type'] ?? '',
            ),
            onTap: () {
              _showProviderDetails(item['id']);
            },
          ),
        );
        validMarkers++;
      } catch (e) {
        debugPrint('Error creating sample marker: $e');
      }
    }

    setState(() {
      markers = newMarkers;
      markersLoading = false;
    });
    debugPrint('Loaded $validMarkers sample markers');
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        bool opened = await Geolocator.openLocationSettings();
        if (!opened) {
          setState(() {
            locationError = true;
            locationErrorMessage =
                "خدمة الموقع غير مفعلة. يرجى تفعيلها من الإعدادات.";
          });
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            locationError = true;
            locationErrorMessage =
                "تم رفض إذن الموقع. يرجى السماح بالوصول إلى الموقع.";
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        bool opened = await Geolocator.openAppSettings();
        if (!opened) {
          setState(() {
            locationError = true;
            locationErrorMessage =
                "تم رفض إذن الموقع دائمًا. يرجى السماح به يدويًا من الإعدادات.";
          });
          return;
        }
        return;
      }

      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        setState(() {
          currentLocation =
              LatLng(lastPosition.latitude, lastPosition.longitude);
        });
        if (_mapCreated && !_cameraAnimating) {
          _cameraAnimating = true;
          _mapController
              ?.animateCamera(
                CameraUpdate.newLatLng(currentLocation!),
              )
              .whenComplete(() => _cameraAnimating = false);
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
      debugPrint(
          'Current location: ${position.latitude}, ${position.longitude}');

      if (_mapCreated && !_cameraAnimating) {
        _cameraAnimating = true;
        _mapController
            ?.animateCamera(
              CameraUpdate.newLatLngZoom(currentLocation!, 15.0),
            )
            .whenComplete(() => _cameraAnimating = false);
      }
    } catch (e) {
      setState(() {
        locationError = true;
        locationErrorMessage = e is String ? e : "تعذر تحديد الموقع.";
      });
      debugPrint('Location error: $e');
    }
  }

  Future<void> _showProviderDetails(dynamic id) async {
    try {
      final response = await http.get(Uri.parse('$url/$id'));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final provider = data;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.w)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        provider['name'] ?? 'غير معروف',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
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
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.w),
                                  ),
                                ),
                              ),
                            ),
                          if ((provider['phone'] ?? '').isNotEmpty)
                            SizedBox(width: 10.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openLocationOnMap(
                                provider['latitude'] ?? 0.0,
                                provider['longitude'] ?? 0.0,
                              ),
                              icon: Icon(Icons.map, size: 18.w),
                              label: Text("الموقع",
                                  style: TextStyle(fontSize: 14.sp)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.w),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      } else {
        _showErrorDialog("فشل في جلب تفاصيل المزود.");
      }
    } catch (e) {
      _showErrorDialog("فشل في جلب تفاصيل المزود.");
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorDialog("لا يمكن إجراء المكالمة");
    }
  }

  Future<void> _openLocationOnMap(double latitude, double longitude) async {
    final String url =
        "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
    final Uri uri = Uri.parse(url);

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

  void _showRetryDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("خطأ", textAlign: TextAlign.right),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadLocationAndMarkers();
            },
            child: const Text("إعادة المحاولة"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("خطأ", textAlign: TextAlign.right),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("موافق"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool allLoaded = locationLoaded && markersLoaded;
    final bool bothFailed = (locationError || currentLocation == null) &&
        (markersError || markers.isEmpty);
    final bool canShowMap = allLoaded && !bothFailed;
    LatLng defaultCenter = const LatLng(30.0444, 31.2357); // Cairo
    LatLng? mapCenter = currentLocation ?? defaultCenter;
    final String? errorMessage = markersErrorMessage ??
        locationErrorMessage ??
        "تعذر تحميل الخريطة أو العلامات. يرجى المحاولة مرة أخرى.";

    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
            bottom: 80.0), // Move button higher above zoom controls
        child: FloatingActionButton(
          heroTag: "legend",
          backgroundColor: AppColors.primary,
          onPressed: () => setState(() => showLegend = !showLegend),
          child: Icon(showLegend ? Icons.close : Icons.info_outline,
              color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          if (!allLoaded)
            const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
          else if (!canShowMap && errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadLocationAndMarkers,
                    child: Text("إعادة المحاولة"),
                  ),
                ],
              ),
            )
          else if (canShowMap)
            GoogleMap(
              mapType: MapType.normal,
              liteModeEnabled:
                  false, // Disable lite mode for full interactivity
              initialCameraPosition: CameraPosition(
                target: mapCenter,
                zoom: 14.0,
              ),
              markers: {
                if (currentLocation != null)
                  Marker(
                    markerId: const MarkerId('current_location'),
                    position: currentLocation!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure),
                    infoWindow: InfoWindow(
                      title: 'موقعك الحالي',
                      snippet: 'Your current location',
                    ),
                    anchor:
                        const Offset(0.5, 1.0), // Center the marker properly
                  ),
                ...markers, // Include all provider markers
              },
              onMapCreated: (controller) {
                _mapController = controller;
                _mapCreated = true;
              },
              myLocationEnabled: true, // Enable blue dot
              myLocationButtonEnabled: true, // Enable my location button
              zoomControlsEnabled: true, // Enable zoom controls
              zoomGesturesEnabled: true, // Enable zoom gestures
              scrollGesturesEnabled: true, // Enable scroll gestures
              tiltGesturesEnabled: true, // Enable tilt gestures
              rotateGesturesEnabled: true, // Enable rotate gestures
              compassEnabled: true, // Enable compass
              mapToolbarEnabled: true, // Enable map toolbar
            ),
          if (showLegend)
            Positioned(
              bottom: 20.h,
              left: 10.w,
              right: 10.w,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1.w,
                  ),
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
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.cancel,
                            size: 20.w,
                            color: AppColors.primary,
                          ),
                          onPressed: () => setState(() => showLegend = false),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Divider(height: 1.h, color: Colors.grey[300]),
                    SizedBox(height: 12.h),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 8.w,
                      mainAxisSpacing: 8.h,
                      children: typeIconMap.entries.map((entry) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Row(
                            children: [
                              Container(
                                width: 30.w,
                                height: 30.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.w),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    entry.value['icon'],
                                    size: 30.w,
                                    color: entry.value['color'],
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.w),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_history_sharp,
                              color: AppColors.primary, size: 24.w),
                          SizedBox(width: 10.w),
                          Text(
                            'موقعك الحالي',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
