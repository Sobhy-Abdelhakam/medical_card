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

class MapData extends StatefulWidget {
  const MapData({super.key});

  @override
  State<MapData> createState() => _MapDataState();
}

class _MapDataState extends State<MapData> {
  LatLng? currentLocation;
  final String url = "https://providers.euro-assist.com/api/arabic-providers";
  GoogleMapController? _mapController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool isOffline = false;
  bool showLegend = false;
  bool dataLoading = true;
  bool locationLoaded = false;
  bool providersLoaded = false;
  bool locationError = false;
  String? locationErrorMessage;
  bool providersError = false;
  String? providersErrorMessage;

  bool _mapCreated = false;
  bool testMode = false; // Enable test mode for sample data

  dynamic _selectedMarkerId;
  List<Map<String, dynamic>> _providers = [];

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
  Map<String, BitmapDescriptor> typeBitmapCacheSelected = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() async {
    try {
      await _generateTypeIcons();
      _loadData();
      _setupConnectivityListener();
    } catch (e) {
      debugPrint('Error initializing map: $e');
      _loadData();
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      final isConnected =
          result.isNotEmpty && result.first != ConnectivityResult.none;
      if (isConnected) {
        if (isOffline) {
          setState(() {
            isOffline = false;
          });
          _loadData();
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

  void _loadData() {
    setState(() {
      dataLoading = true;
      locationLoaded = false;
      providersLoaded = false;
      locationError = false;
      providersError = false;
      locationErrorMessage = null;
      providersErrorMessage = null;
      currentLocation = null;
      _providers = [];
      _selectedMarkerId = null;
    });

    Future.wait([
      getCurrentLocation(),
      fetchProviderData(),
    ]).whenComplete(() {
      if (mounted) {
        setState(() {
          dataLoading = false;
          locationLoaded = true;
          providersLoaded = true;
        });
      }
    });
  }

  Future<void> _generateTypeIcons() async {
    try {
      for (final entry in typeIconMap.entries) {
        final iconData = entry.value['icon'] as IconData;
        final color = entry.value['color'] as Color;
        typeBitmapCache[entry.key] =
            await bitmapDescriptorFromIcon(iconData, color, size: 120);
        typeBitmapCacheSelected[entry.key] = await bitmapDescriptorFromIcon(
            iconData, color,
            size: 180, isSelected: true);
      }
      typeBitmapCache['default'] =
          await bitmapDescriptorFromIcon(Icons.location_on, Colors.blue, size: 120);
      typeBitmapCacheSelected['default'] = await bitmapDescriptorFromIcon(
          Icons.location_on, Colors.blue,
          size: 180, isSelected: true);
      debugPrint('Generated ${typeBitmapCache.length} icons successfully');
    } catch (e) {
      debugPrint('Error generating icons: $e');
    }
  }

  Future<BitmapDescriptor> bitmapDescriptorFromIcon(
      IconData iconData, Color color,
      {int size = 120, bool isSelected = false}) async {
    try {
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
    } catch (e) {
      debugPrint('Error creating bitmap descriptor: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> fetchProviderData() async {
    try {
      List<dynamic> data;
      if (testMode) {
        data = sampleData;
      } else {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) {
          data = jsonDecode(utf8.decode(response.bodyBytes));
        } else {
          throw 'API Error: ${response.statusCode}';
        }
      }
      if (mounted) {
        setState(() {
          _providers = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          providersError = true;
          providersErrorMessage = "فشل تحميل بيانات المزودين. عرض بيانات تجريبية.";
          _providers = sampleData;
        });
      }
      debugPrint('Network error: $e');
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw "خدمة الموقع غير مفعلة. يرجى تفعيلها من الإعدادات.";
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw "تم رفض إذن الموقع. يرجى السماح بالوصول إلى الموقع.";
        }
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        throw "تم رفض إذن الموقع دائمًا. يرجى السماح به يدويًا من الإعدادات.";
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          currentLocation = LatLng(position.latitude, position.longitude);
        });
        _animateToLocation(currentLocation!, zoom: 14.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          locationError = true;
          locationErrorMessage = e is String ? e : "تعذر تحديد الموقع.";
        });
      }
      debugPrint('Location error: $e');
    }
  }

  void _animateToLocation(LatLng position, {double zoom = 14.0}) {
    if (_mapCreated && _mapController != null) {
      _mapController!
          .animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
    }
  }

  Future<void> _showProviderDetails(dynamic id) async {
    try {
      final response = await http.get(Uri.parse('$url/$id'));
      if (response.statusCode == 200) {
        final provider = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            builder: (context) =>
                _ProviderDetailsSheet(provider: provider),
          ).whenComplete(() {
            if (mounted) {
              setState(() {
                _selectedMarkerId = null;
              });
            }
          });
        }
      } else {
        _showErrorDialog("فشل في جلب تفاصيل المزود.");
      }
    } catch (e) {
      _showErrorDialog("فشل في جلب تفاصيل المزود.");
    }
  }

  void _showRetryDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("خطأ", textAlign: TextAlign.right),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadData();
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
        title: const Text("خطأ", textAlign: TextAlign.right),
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
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80.h),
        child: FloatingActionButton(
          heroTag: "legend",
          backgroundColor: Theme.of(context).colorScheme.primary,
          onPressed: () => setState(() => showLegend = !showLegend),
          child: Icon(showLegend ? Icons.close : Icons.info_outline,
              color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          _buildMapContent(),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    if (dataLoading) {
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
    }

    if (locationError && _providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16.h),
            Text(locationErrorMessage ?? "حدث خطأ غير متوقع.",
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text("إعادة المحاولة"),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: currentLocation ?? const LatLng(30.0444, 31.2357), // Cairo
        zoom: 12.0,
      ),
      markers: _buildMarkersSet(),
      onMapCreated: (controller) {
        _mapController = controller;
        _mapCreated = true;
        if (currentLocation != null) {
          _animateToLocation(currentLocation!, zoom: 14.0);
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
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: true,
    );
  }

  Set<Marker> _buildMarkersSet() {
    final markers = <Marker>{};

    if (currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'موقعك الحالي'),
          anchor: const Offset(0.5, 1.0),
        ),
      );
    }

    for (var item in _providers) {
      try {
        if (item['latitude'] != null && item['longitude'] != null) {
          final lat = (item['latitude'] as num).toDouble();
          final lng = (item['longitude'] as num).toDouble();

          if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
            final type = item['type'] ?? '';
            final isSelected = item['id'] == _selectedMarkerId;
            final icon = isSelected
                ? (typeBitmapCacheSelected[type] ??
                    typeBitmapCacheSelected['default']!)
                : (typeBitmapCache[type] ?? typeBitmapCache['default']!);

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
                  _showProviderDetails(item['id']);
                },
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error creating marker for item ${item['id']}: $e');
      }
    }
    return markers;
  }

  Widget _buildLegend() {
    return IgnorePointer(
      ignoring: !showLegend,
      child: AnimatedOpacity(
        opacity: showLegend ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: showLegend
            ? _LegendWidget(
                typeIconMap: typeIconMap,
                onClose: () => setState(() => showLegend = false),
              )
            : const SizedBox.shrink(),
      ),
    );
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
            BoxShadow(
                color: Colors.black26, blurRadius: 10, spreadRadius: 2)
          ],
          border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3), width: 1.w),
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
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10)
            ],
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
                    if ((provider['package'] ?? '').toString().trim().isNotEmpty)
                      _buildInfoRow('الباقات:', provider['package']),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        if ((provider['phone'] ?? '').isNotEmpty)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _makePhoneCall(provider['phone']),
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