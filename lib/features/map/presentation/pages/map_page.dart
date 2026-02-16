import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../di/injection_container.dart';
import '../../../providers/domain/entities/provider_entity.dart';
import '../../../providers/presentation/cubit/map_providers/map_providers_cubit.dart';

// ============================================================================
// CONSTANTS & CONFIGURATION
// ============================================================================

const double _defaultMapZoom = 12.0;
const double _markerZoomLevel = 14.5;
const double _defaultLatitude = 30.0444;
const double _defaultLongitude = 31.2357;

const Duration _animationDuration = Duration(milliseconds: 300);
const Duration _debounceDuration = Duration(milliseconds: 400);

// Use slightly larger icons for better visibility on high-DPI screens
const double _iconSizeNormal = 100.0;
const double _iconSizeSelected = 130.0;
const double _iconBorderWidth = 5.0;

const Map<String, Map<String, dynamic>> _typeIconMap = {
  'صيدلية': {'icon': Icons.local_pharmacy, 'color': Colors.green},
  'مستشفى': {'icon': Icons.local_hospital, 'color': Colors.red},
  'معامل التحاليل': {'icon': Icons.science, 'color': Colors.blue},
  'مراكز الأشعة': {'icon': Icons.medical_services, 'color': Colors.deepPurple},
  'علاج طبيعي': {'icon': Icons.accessibility_new, 'color': Colors.orange},
  'مراكز متخصصة': {'icon': Icons.star, 'color': Colors.teal},
  'عيادة': {'icon': Icons.local_hospital, 'color': Colors.pink},
  'بصريات': {'icon': Icons.visibility, 'color': Colors.brown},
};

// ============================================================================
// MAIN WIDGET
// ============================================================================

class MapData extends StatefulWidget {
  const MapData({super.key});

  @override
  State<MapData> createState() => _MapDataState();
}

class _MapDataState extends State<MapData> with WidgetsBindingObserver {
  // Logic & Services
  late final MapProvidersCubit _cubit;
  late final _MapIconCache _iconCache;

  // Controllers
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  // Local State
  LatLng? _currentLocation; // User's location
  bool _areIconsReady =
      false; // Prevents markers from showing before icons are ready
  bool _isFilterExpanded = false;
  bool _showLegend = false;
  bool _isLocationLoading = false;
  bool _isMapReadyForiOS = false; // Guard for iOS platform view race condition

  // Memoization Cache for diffing
  Set<Marker> _currentMarkers = {};
  List<ProviderEntity>? _lastFilteredProviders;
  ProviderEntity? _lastSelectedProvider;

  // Helpers
  Timer? _batchTimer;
  int _bachedIndex = 0;
  static const int _batchSize = 40; // Process 40 markers per frame (~1-2ms)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = sl<MapProvidersCubit>();
    _iconCache = _MapIconCache();

    // 1. NON-BLOCKING Initialization
    _startParallelInitialization();

    // iOS Platform View Fix: Delay rendering slightly to ensure view hierarchy is ready
    if (Platform.isIOS) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isMapReadyForiOS = true);
      });
    } else {
      _isMapReadyForiOS = true;
    }
  }

  void _startParallelInitialization() {
    // Generate icons if not ready (uses static cache internally so it's fast if already done)
    _iconCache.generateTypeIcons(_typeIconMap).then((_) {
      if (mounted) {
        setState(() => _areIconsReady = true);
        // If data was already loaded, trigger batching now
        if (_cubit.state is MapProvidersLoaded) {
          final state = _cubit.state as MapProvidersLoaded;
          _scheduleMarkerBatch(state.filteredProviders, state.selectedProvider);
        }
      }
    });

    _cubit.loadMapProviders();
    _getCurrentLocation(animate: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _batchTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _cubit.close();
    _mapController?.dispose();
    _searchController.dispose();
    // _iconCache.dispose(); // Keep cache alive for re-entry
    super.dispose();
  }

  // --- Location Logic ---

  Future<void> _getCurrentLocation({bool animate = false}) async {
    if (!mounted) return;
    setState(() => _isLocationLoading = true);

    try {
      final loc = await _LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
          if (loc != null) _currentLocation = loc;
        });

        if (loc != null && animate && _mapController != null) {
          _animateCamera(loc, zoom: _markerZoomLevel);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  void _animateCamera(LatLng target, {double zoom = _defaultMapZoom}) {
    try {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
    } catch (e) {
      debugPrint('Error animating camera: $e');
    }
  }

  // --- Search Logic ---

  void _onSearchChanged(String query) {
    if (_searchDebounceTimer?.isActive ?? false) _searchDebounceTimer!.cancel();
    _searchDebounceTimer = Timer(_debounceDuration, () {
      if (query.isEmpty) {
        _cubit.clearFilters();
      } else {
        _cubit.searchMapProviders(query);
      }
    });
  }

  // --- Marker Building (Optimized) ---

  // --- Batched Marker Building ---

  void _scheduleMarkerBatch(List<ProviderEntity> providers, ProviderEntity? selected) {
    _batchTimer?.cancel();
    
    // Check if we really need to update (diffing)
    if (providers == _lastFilteredProviders && selected == _lastSelectedProvider && _currentMarkers.isNotEmpty) {
      return;
    }

    _lastFilteredProviders = providers;
    _lastSelectedProvider = selected;
    
    // Reset
    // Note: We do NOT clear _currentMarkers immediately to prevent flashing.
    // We build a NEW set incrementally and replace at end? 
    // OR add incrementally?
    // "Markers appear progressively" -> Add incrementally.
    
    // If list changed significantly (e.g. filter), we might want to clear old ones.
    // For now, let's start fresh for the new batch to ensure correctness.
    final Set<Marker> newMarkers = {};
    _bachedIndex = 0;

    _batchTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final int start = _bachedIndex;
      final int end = (start + _batchSize < providers.length) 
          ? start + _batchSize 
          : providers.length;

      if (start >= providers.length) {
        timer.cancel();
        return;
      }

      // Generate batch
      for (int i = start; i < end; i++) {
        final provider = providers[i];
        final isSelected = selected?.id == provider.id;
        final type = provider.type;
        
        // Use cached icons (instant)
        final icon = isSelected
            ? (_iconCache.getSelectedIcon(type) ?? _iconCache.getDefaultSelectedIcon())
            : (_iconCache.getIcon(type) ?? _iconCache.getDefaultIcon());

        newMarkers.add(
          Marker(
            markerId: MarkerId(provider.id.toString()),
            position: LatLng(provider.latitude ?? 0, provider.longitude ?? 0),
            icon: icon ?? BitmapDescriptor.defaultMarker,
            zIndex: isSelected ? 10.0 : 1.0,
            anchor: const Offset(0.5, 0.5),
            onTap: () {
              _cubit.selectProvider(provider);
              _showProviderDetails(provider);
            },
          ),
        );
      }

      _bachedIndex = end;

      // Update UI incrementally
      setState(() {
        // We replace the set entirely to ensure GoogleMaps picks up changes
        // But since we are building `newMarkers` from scratch, we might want to 
        // accumulate. 
        // Strategy: 
        // Frame 1: newMarkers has 50. _currentMarkers = 50.
        // Frame 2: newMarkers has 100. _currentMarkers = 100.
        _currentMarkers = Set.of(newMarkers); 
      });

      if (_bachedIndex >= providers.length) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. The Map (Background Layer)
            _buildMapLayer(),

            // 2. Search & Filters (Top Layer)
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFloatingSearchBar(),
                      // Loading Indicator
                      BlocBuilder<MapProvidersCubit, MapProvidersState>(
                        builder: (context, state) {
                          if (state is MapProvidersLoading) {
                            return Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: LinearProgressIndicator(
                                minHeight: 2.h,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation(
                                    Theme.of(context).primaryColor),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      AnimatedSize(
                        duration: _animationDuration,
                        curve: Curves.easeOutCubic,
                        child: _isFilterExpanded
                            ? Padding(
                                padding: EdgeInsets.only(top: 12.h),
                                child: _FilterChipsList(cubit: _cubit),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Floating Controls
            Positioned(
              bottom: 100.h,
              right: 16.w,
              child: _buildFloatingControls(),
            ),

            // 4. Legend
            if (_showLegend)
              Positioned(
                bottom: 110.h,
                left: 16.w,
                child: _LegendWidget(
                    onClose: () => setState(() => _showLegend = false)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLayer() {
    return BlocConsumer<MapProvidersCubit, MapProvidersState>(
      listener: (context, state) {
        if (state is MapProvidersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
        // Trigger batching when data changes
        if (state is MapProvidersLoaded && _areIconsReady) {
          _scheduleMarkerBatch(state.filteredProviders, state.selectedProvider);
        }
      },
      // Only rebuild if switching between major states (Loading/Loaded/Error)
      // Marker updates are handled by setState in _scheduleMarkerBatch
      buildWhen: (previous, current) =>
          current.runtimeType != previous.runtimeType,
      builder: (context, state) {
        // Use local state _currentMarkers regardless of Cubit state
        // This ensures markers persist during loading/rebuilds
        final markers = _currentMarkers;
        // If loading, we just use _currentMarkers, effectively persisting them.

        if (!_isMapReadyForiOS) {
          return const SizedBox(); // Prevent blank/glitchy map on iOS startup
        }

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentLocation ??
                const LatLng(_defaultLatitude, _defaultLongitude),
            zoom: _defaultMapZoom,
          ),
          markers: markers,
          onMapCreated: (c) {
            _mapController = c;
            // Delay style setting or other heavy work if needed
            if (_currentLocation != null) {
              c.moveCamera(CameraUpdate.newLatLng(_currentLocation!));
            }
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false, // Custom button used
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          liteModeEnabled: false,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: false,
          onTap: (_) {
            FocusScope.of(context).unfocus();
            _cubit.selectProvider(null);
          },
        );
      },
    );
  }

  Widget _buildFloatingSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            SizedBox(width: 16.w),
            Icon(Icons.search, color: Colors.grey[600], size: 22.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: context.tr('search_hint'),
                  hintStyle:
                      TextStyle(color: Colors.grey[400], fontSize: 13.sp),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),
            // Divider
            Container(
              height: 24.h,
              width: 1,
              color: Colors.grey[300],
              margin: EdgeInsets.symmetric(horizontal: 4.w),
            ),
            // Filter Toggle
            IconButton(
              icon: Icon(
                _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                color: _isFilterExpanded
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
                size: 22.sp,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _isFilterExpanded = !_isFilterExpanded);
              },
            ),
            SizedBox(width: 4.w),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildFab(
          heroTag: 'legend_fab',
          icon: _showLegend ? Icons.close : Icons.info_outline,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _showLegend = !_showLegend);
          },
          backgroundColor: Colors.white,
          iconColor: Theme.of(context).primaryColor,
        ),
        SizedBox(height: 12.h),
        _buildFab(
          heroTag: 'location_fab',
          icon: _isLocationLoading ? Icons.gps_not_fixed : Icons.my_location,
          onTap: () {
            HapticFeedback.selectionClick();
            _getCurrentLocation(animate: true);
          },
          isLoading: _isLocationLoading,
        ),
      ],
    );
  }

  Widget _buildFab({
    required String heroTag,
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? iconColor,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: 50.w,
      height: 50.w,
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onTap,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        elevation: 6,
        highlightElevation: 10,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: isLoading
            ? Padding(
                padding: EdgeInsets.all(14.w),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(iconColor ?? Colors.white),
                ),
              )
            : Icon(icon, color: iconColor ?? Colors.white, size: 24.sp),
      ),
    );
  }

  void _showProviderDetails(ProviderEntity provider) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProviderDetailsSheet(provider: provider),
    ).whenComplete(() {
      // Clear selection when sheet closes
      _cubit.selectProvider(null);
    });
  }
}

// ============================================================================
// SUB-WIDGETS
// ============================================================================

class _FilterChipsList extends StatelessWidget {
  final MapProvidersCubit cubit;
  const _FilterChipsList({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapProvidersCubit, MapProvidersState>(
      // Only rebuild if selected types change
      buildWhen: (previous, current) {
        if (previous is MapProvidersLoaded && current is MapProvidersLoaded) {
          return previous.selectedTypes != current.selectedTypes;
        }
        return true;
      },
      builder: (context, state) {
        if (state is! MapProvidersLoaded) return const SizedBox();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip(
                context,
                label: context.tr('all_types'),
                isSelected: state.selectedTypes.isEmpty,
                onTap: () => cubit.clearFilters(),
              ),
              ..._typeIconMap.keys.map((type) {
                final isSelected = state.selectedTypes.contains(type);
                return _buildFilterChip(
                  context,
                  label: type,
                  isSelected: isSelected,
                  onTap: () => cubit.toggleType(type),
                  iconData: _typeIconMap[type]?['icon'],
                  color: _typeIconMap[type]?['color'],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? iconData,
    Color? color,
  }) {
    final themeColor = color ?? Theme.of(context).primaryColor;

    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: isSelected ? null : Border.all(color: Colors.grey[200]!),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconData != null) ...[
                    Icon(
                      iconData,
                      size: 16.sp,
                      color: isSelected ? Colors.white : themeColor,
                    ),
                    SizedBox(width: 6.w),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendWidget extends StatelessWidget {
  final VoidCallback onClose;
  const _LegendWidget({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      width: 220.w,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: BackdropFilter(
        // Create glass effect
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('legend_title'),
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                ),
                InkWell(
                  onTap: onClose,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child:
                        Icon(Icons.close, size: 18.sp, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            Divider(height: 16.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200.h),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: _typeIconMap.entries
                      .map((e) => Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: Row(
                              children: [
                                Icon(e.value['icon'],
                                    color: e.value['color'], size: 18.sp),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[800]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderDetailsSheet extends StatelessWidget {
  final ProviderEntity provider;
  const _ProviderDetailsSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30)],
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 24.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: (_typeIconMap[provider.type]?['color'] ??
                          Theme.of(context).primaryColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  _typeIconMap[provider.type]?['icon'] ?? Icons.local_hospital,
                  color: _typeIconMap[provider.type]?['color'] ??
                      Theme.of(context).primaryColor,
                  size: 32.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        provider.type,
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),
          Divider(color: Colors.grey[100], height: 1),
          SizedBox(height: 20.h),

          // Details
          _DetailRow(icon: Icons.place_outlined, text: provider.address),
          if (provider.phone.isNotEmpty)
            _DetailRow(
                icon: Icons.phone_outlined,
                text: provider.phone,
                isPhone: true),
          if (provider.discountPct.isNotEmpty)
            _DetailRow(
              icon: Icons.local_offer_outlined,
              text: '${context.tr('discount')}: ${provider.discountPct}%',
              color: Colors.green[700],
              hasBg: true,
            ),

          SizedBox(height: 24.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _MainActionButton(
                  icon: Icons.call,
                  label: context.tr('call_button'),
                  color: Colors.green,
                  onTap: () => _launchUrl('tel:${provider.phone}'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _MainActionButton(
                  icon: Icons.map,
                  label: context.tr('location_button'),
                  color: Theme.of(context).primaryColor,
                  onTap: () => _launchUrl(provider.mapUrl),
                  isOutlined: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isPhone;
  final Color? color;
  final bool hasBg;

  const _DetailRow({
    required this.icon,
    required this.text,
    this.isPhone = false,
    this.color,
    this.hasBg = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hasBg) {
      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: (color ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: color),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: Colors.grey[400]),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[800],
                fontWeight: FontWeight.w400,
                height: 1.3,
                fontFamily: isPhone ? 'Roboto' : null,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}

class _MainActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isOutlined;

  const _MainActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOutlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            border: isOutlined
                ? Border.all(color: color.withOpacity(0.4), width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isOutlined ? color : Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: isOutlined ? color : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HELPERS
// ============================================================================

class _MapIconCache {
  // Static cache to persist across instances
  static final Map<String, BitmapDescriptor> _staticIconCache = {};
  static final Map<String, BitmapDescriptor> _staticSelectedIconCache = {};
  static bool _isGenerated = false;

  Future<void> generateTypeIcons(Map<String, Map<String, dynamic>> typeIconMap) async {
    if (_isGenerated) return; // Return immediately if already generated

    try {
      final futures = <Future>[];

      // Use Future.wait to run all generation in parallel on the event loop
      // (Actually it's single threaded but platform channel calls are async)

      // Defaults
      futures.add(_BitmapGenerator.create(Icons.location_on, Colors.blue, _iconSizeNormal)
          .then((icon) => _staticIconCache['default'] = icon));
      futures.add(_BitmapGenerator.create(Icons.location_on, Colors.blue, _iconSizeSelected, isSelected: true)
          .then((icon) => _staticSelectedIconCache['default'] = icon));

      // Custom Types
      for (var entry in typeIconMap.entries) {
        final type = entry.key;
        final icon = entry.value['icon'] as IconData;
        final color = entry.value['color'] as Color;

        futures.add(_BitmapGenerator.create(icon, color, _iconSizeNormal)
            .then((desc) => _staticIconCache[type] = desc));
        futures.add(_BitmapGenerator.create(icon, color, _iconSizeSelected, isSelected: true)
            .then((desc) => _staticSelectedIconCache[type] = desc));
      }

      await Future.wait(futures);
      _isGenerated = true;
    } catch (e) {
      debugPrint('Error generating icons: $e');
    }
  }

  BitmapDescriptor? getIcon(String type) => _staticIconCache[type];
  BitmapDescriptor? getSelectedIcon(String type) => _staticSelectedIconCache[type];
  BitmapDescriptor? getDefaultIcon() => _staticIconCache['default'];
  BitmapDescriptor? getDefaultSelectedIcon() => _staticSelectedIconCache['default'];

  void dispose() {
    // We do NOT clear the static cache on dispose to keep them for next time
  }
}

class _BitmapGenerator {
  /// Generates a [BitmapDescriptor] from an icon.
  /// Minimizes heavy painting operations.
  static Future<BitmapDescriptor> create(
      IconData icon, Color color, double size,
      {bool isSelected = false}) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double s = size;
    final double center = s / 2;

    // 1. Draw Shadow (Subtle)
    // Reduce shadow blur for performance if needed, but keeping it for UX
    final path = Path()
      ..addOval(
          Rect.fromCircle(center: Offset(center, center), radius: center - 4));
    canvas.drawShadow(path, Colors.black.withOpacity(0.25), 4.0, true);

    // 2. Background
    final Paint bgPaint = Paint()..color = isSelected ? color : Colors.white;
    canvas.drawCircle(Offset(center, center), center - 4, bgPaint);

    // 3. Border (Thicker for contrast)
    final Paint borderPaint = Paint()
      ..color = isSelected ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _iconBorderWidth;
    canvas.drawCircle(Offset(center, center), center - 6, borderPaint);

    // 4. Icon
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: s * 0.55,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: isSelected ? Colors.white : color,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset((s - tp.width) / 2, (s - tp.height) / 2));

    final img = await recorder.endRecording().toImage(s.toInt(), s.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}

class _LocationService {
  static Future<LatLng?> getCurrentLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) return null;
      }
      if (p == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5), // Fail fast
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
