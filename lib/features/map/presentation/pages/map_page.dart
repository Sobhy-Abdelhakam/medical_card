import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../di/injection_container.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../providers/domain/entities/provider_entity.dart';
import '../../../providers/presentation/cubit/map_providers/map_providers_cubit.dart';

// ============================================================================
// CONSTANTS & CONFIGURATION
// ============================================================================

// Map configuration
const double _defaultMapZoom = 12.0;
const double _markerZoomLevel = 14.0;
const double _defaultLatitude = 30.0444;
const double _defaultLongitude = 31.2357;

// Animation & timing
const int _animationDurationMs = 300;
const int _debounceDelayMs = 500;
const Duration _animationDuration =
    Duration(milliseconds: _animationDurationMs);
const Duration _debounceDuration = Duration(milliseconds: _debounceDelayMs);

// Icon sizes
const double _iconDefaultSize = 80.0;
const double _iconSelectedSize = 100.0;
const double _iconBorderWidth = 4.0;

// Spacing & padding
const double _filterChipSpacing = 8.0;
const double _topBarPadding = 16.0;
const double _bottomButtonSpacing = 12.0;
const double _bottomPadding = 24.0;

// Shadow configuration
const BoxShadow _defaultBoxShadow = BoxShadow(
  color: Colors.black26,
  blurRadius: 8.0,
  offset: Offset(0, 2),
);

/// Provider type icons and colors mapping
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

/// Professional map screen displaying healthcare providers
class MapData extends StatefulWidget {
  const MapData({super.key});

  @override
  State<MapData> createState() => _MapDataState();
}

class _MapDataState extends State<MapData> with WidgetsBindingObserver {
  // Cubits & Services
  late final MapProvidersCubit _cubit;
  late final _MapIconCache _iconCache;

  // Map Controller
  GoogleMapController? _mapController;

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  // State variables
  LatLng? _currentLocation;
  bool _isFilterOverlayVisible = false;
  bool _showLegend = false;
  bool _isLocationLoading = false;
  bool _isMapReady = false;
  String? _memberName;
  int? _templateId;

  // Timers
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = sl<MapProvidersCubit>();
    _iconCache = _MapIconCache();
    _loadMemberInfo();
    // Defer initialization to next frame to allow UI to render first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  /// Load member info for welcome banner
  Future<void> _loadMemberInfo() async {
    final authRepository = sl<AuthRepository>();
    final member = await authRepository.getCurrentMember();
    // Debugging requirements
    // ignore: avoid_print
    print(
        '[MAP] loaded member for welcome: ${member?.memberId} "${member?.memberName}" templateId=${member?.templateId}');

    if (member != null && mounted) {
      setState(() {
        _memberName = member.memberName;
        _templateId = member.templateId;
      });
    }
  }

  /// Initialize the map screen with all necessary resources
  Future<void> _initializeScreen() async {
    await Future.wait([
      _iconCache.generateTypeIcons(_typeIconMap),
    ]);

    if (mounted) {
      _cubit.loadMapProviders();
      _getCurrentLocation();

      // Artificial delay to let the UI breathe before heavy map initialization
      // This prevents the "Skipped frames" jank on startup
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _isMapReady = true);
      }
    }
  }

  /// Get current device location with error handling
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() => _isLocationLoading = true);

    try {
      final location = await _LocationService.getCurrentLocation(context);
      if (mounted) {
        setState(() => _isLocationLoading = false);
        if (location != null) {
          _setCurrentLocation(location);
          if (_mapController != null && _isMapReady) {
            _animateToLocation(location, zoom: _markerZoomLevel);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocationLoading = false);
        debugPrint('Error getting location: $e');
      }
    }
  }

  /// Set current location and update state
  void _setCurrentLocation(LatLng location) {
    setState(() => _currentLocation = location);
  }

  /// Handle search input with debouncing
  void _onSearchSubmitted(String query) {
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      _cubit.clearFilters();
      return;
    }

    _searchDebounceTimer = Timer(_debounceDuration, () {
      _cubit.searchMapProviders(query);
      FocusScope.of(context).unfocus();
    });
  }

  /// Animate camera to specific location
  void _animateToLocation(
    LatLng position, {
    double zoom = _defaultMapZoom,
  }) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, zoom),
    );
  }

  /// Toggle filter overlay visibility with haptic feedback
  void _toggleFilterOverlay() {
    HapticFeedback.lightImpact();
    setState(() => _isFilterOverlayVisible = !_isFilterOverlayVisible);
  }

  /// Toggle legend visibility
  void _toggleLegend() {
    HapticFeedback.lightImpact();
    setState(() => _showLegend = !_showLegend);
  }

  /// Show error snackbar to user
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show provider details modal
  void _showProviderDetails(ProviderEntity provider) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProviderDetailsSheet(provider: provider),
    ).whenComplete(() => _cubit.selectProvider(null));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounceTimer?.cancel();
    _cubit.close();
    _mapController?.dispose();
    _searchController.dispose();
    _iconCache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildMap(),
            _buildFilterOverlay(),
            _buildLegend(),
            _buildFloatingButtons(),
            if (_isLocationLoading) _buildLocationLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  /// Build professional app bar with welcome message and search
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(120.h),
      child: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.95),
                Theme.of(context).primaryColor.withOpacity(0.85),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Container(
              padding: EdgeInsets.only(
                left: _topBarPadding.w,
                right: _topBarPadding.w,
                top: 8.h,
                bottom: 10.h,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildWelcomeBannerCompact(),
                  SizedBox(height: 8.h),
                  _buildSearchAndFilterBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Compact welcome banner for app bar
  Widget _buildWelcomeBannerCompact() {
    final name =
        (_memberName?.trim().isNotEmpty ?? false) ? _memberName! : 'Guest';
    final hasAvatar = _templateId == 7;

    return SizedBox(
      height: 45.h,
      child: Row(
        children: [
          if (hasAvatar)
            Container(
              width: 45.w,
              height: 45.h, 
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1.5,
                ),
              ),
              child: Image.asset(
                'assets/images/zamalik.jpeg',
                fit: BoxFit.contain,
              ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('welcome_back'),
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Search and filter bar for app bar
  Widget _buildSearchAndFilterBar() {
    return Row(
      children: [
        _buildFilterButton(),
        SizedBox(width: _filterChipSpacing.w),
        Expanded(child: _buildSearchBar()),
      ],
    );
  }

  // ========================================================================
  // Map Widget
  // ========================================================================

  Widget _buildMap() {
    return BlocConsumer<MapProvidersCubit, MapProvidersState>(
      listener: (context, state) {
        if (state is MapProvidersError) {
          _showErrorSnackBar(state.message);
        }
      },
      builder: (context, state) {
        if (!_isMapReady) {
          return _buildLoadingPlaceholder();
        }

        if (state is MapProvidersLoading) {
          return _buildLoadingPlaceholder();
        }

        Set<Marker> markers = <Marker>{};
        if (state is MapProvidersLoaded) {
          markers = _buildMarkers(state);
        }

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentLocation ??
                const LatLng(_defaultLatitude, _defaultLongitude),
            zoom: _defaultMapZoom,
          ),
          markers: markers,
          onMapCreated: _onMapCreated,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onTap: (_) => _cubit.selectProvider(null),
        );
      },
    );
  }

  /// Callback when map is created
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLocation != null) {
      _animateToLocation(_currentLocation!, zoom: _markerZoomLevel);
    }
  }

  /// Build markers from provider list
  Set<Marker> _buildMarkers(MapProvidersLoaded state) {
    return state.filteredProviders.map((provider) {
      final isSelected = state.selectedProvider?.id == provider.id;
      final type = provider.type;
      final icon = isSelected
          ? (_iconCache.getSelectedIcon(type) ??
              _iconCache.getDefaultSelectedIcon())
          : (_iconCache.getIcon(type) ?? _iconCache.getDefaultIcon());

      return Marker(
        markerId: MarkerId(provider.id.toString()),
        position: LatLng(
          provider.latitude ?? _defaultLatitude,
          provider.longitude ?? _defaultLongitude,
        ),
        icon: icon ?? BitmapDescriptor.defaultMarker,
        zIndexInt: isSelected ? 10 : 1,
        infoWindow: InfoWindow(
          title: provider.name,
          snippet: provider.type,
        ),
        onTap: () {
          _cubit.selectProvider(provider);
          _showProviderDetails(provider);
        },
      );
    }).toSet();
  }

  // ========================================================================
  // Filter Overlay
  // ========================================================================

  Widget _buildFilterButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _isFilterOverlayVisible ? 1 : 0),
      duration: _animationDuration,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 3.14159 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _toggleFilterOverlay,
                child: Padding(
                  padding: EdgeInsets.all(10.w),
                  child: Icon(
                    _isFilterOverlayVisible ? Icons.close : Icons.filter_list,
                    color: Theme.of(context).primaryColor,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 42.h,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          textAlign: TextAlign.right,
          textInputAction: TextInputAction.search,
          onSubmitted: _onSearchSubmitted,
          onChanged: (value) {
            setState(() {});
            if (value.isEmpty) {
              _cubit.clearFilters();
            }
          },
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
          cursorColor: Theme.of(context).primaryColor,
          decoration: InputDecoration(
            hintText: context.tr('search_hint'),
            hintStyle: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[400],
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 10.h,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 12.w, right: 4.w),
              child: Icon(
                Icons.search,
                size: 20.sp,
                color: Theme.of(context).primaryColor.withOpacity(0.6),
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? Padding(
                    padding: EdgeInsets.only(right: 4.w),
                    child: IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 18.sp,
                        color: Colors.grey[400],
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        _cubit.clearFilters();
                      },
                      splashRadius: 20,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // Filter Overlay
  // ========================================================================

  Widget _buildFilterOverlay() {
    return AnimatedPositioned(
      duration: _animationDuration,
      curve: Curves.easeOutCubic,
      top: _isFilterOverlayVisible ? 120.h : -220.h,
      left: _topBarPadding.w,
      right: _topBarPadding.w,
      child: AnimatedOpacity(
        opacity: _isFilterOverlayVisible ? 1.0 : 0.0,
        duration: _animationDuration,
        child: _isFilterOverlayVisible
            ? _FilterOverlayWidget(cubit: _cubit)
            : const SizedBox.shrink(),
      ),
    );
  }

  // ========================================================================
  // Legend
  // ========================================================================

  Widget _buildLegend() {
    if (!_showLegend) return const SizedBox.shrink();

    return Positioned(
      bottom: (100).h + MediaQuery.of(context).padding.bottom,
      left: _topBarPadding.w,
      child: _LegendWidget(onClose: _toggleLegend),
    );
  }

  // ========================================================================
  // Floating Action Buttons
  // ========================================================================

  Widget _buildFloatingButtons() {
    return Positioned(
      bottom: _bottomPadding.h + MediaQuery.of(context).padding.bottom,
      right: _topBarPadding.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildLegendButton(),
          SizedBox(height: _bottomButtonSpacing.h),
          _buildLocationButton(),
        ],
      ),
    );
  }

  Widget _buildLegendButton() {
    return FloatingActionButton(
      heroTag: 'legend_btn',
      backgroundColor: Colors.white,
      elevation: 6,
      highlightElevation: 8,
      mini: true,
      onPressed: _toggleLegend,
      child: Icon(
        _showLegend ? Icons.close : Icons.info_outline,
        color: Theme.of(context).primaryColor,
        size: 22.sp,
      ),
    );
  }

  Widget _buildLocationButton() {
    return FloatingActionButton(
      heroTag: 'location_btn',
      elevation: 6,
      highlightElevation: 8,
      onPressed: () {
        if (_currentLocation != null) {
          _animateToLocation(_currentLocation!);
        } else {
          _getCurrentLocation();
        }
      },
      child: Icon(
        _isLocationLoading ? Icons.gps_not_fixed : Icons.my_location,
        color: Colors.white,
        size: 24.sp,
      ),
    );
  }

  // ========================================================================
  // Loading States
  // ========================================================================

  Widget _buildLoadingPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            context.tr('loading_centers'),
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationLoadingOverlay() {
    return Positioned(
      bottom: _bottomPadding.h + 50.h + MediaQuery.of(context).padding.bottom,
      right: _topBarPadding.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: const [_defaultBoxShadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              context.tr('location_loading'),
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FILTER OVERLAY WIDGET
// ============================================================================

class _FilterOverlayWidget extends StatelessWidget {
  final MapProvidersCubit cubit;

  const _FilterOverlayWidget({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BlocBuilder<MapProvidersCubit, MapProvidersState>(
        builder: (context, state) {
          if (state is! MapProvidersLoaded) {
            return const SizedBox.shrink();
          }

          final selectedCount = state.selectedTypes.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedCount > 0
                          ? context.trWithCount('selected_count', selectedCount)
                          : context.tr('filter_by_type'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: Colors.grey[800],
                      ),
                    ),
                    if (selectedCount > 0)
                      GestureDetector(
                        onTap: () => cubit.clearFilters(),
                        child: Text(
                          context.tr('reset_filters'),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SizedBox(height: 10.h),
              // Filter chips
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildFilterChip(
                    context.tr('all_types'),
                    state.selectedTypes.isEmpty,
                    () => cubit.clearFilters(),
                    context,
                  ),
                  ..._typeIconMap.entries.map((entry) {
                    final type = entry.key;
                    final isSelected = state.selectedTypes.contains(type);
                    return _buildFilterChip(
                      type,
                      isSelected,
                      () => cubit.toggleType(type),
                      context,
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.lightImpact();
        onTap();
      },
      checkmarkColor: Colors.white,
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 12.sp,
      ),
    );
  }
}

// ============================================================================
// LEGEND WIDGET
// ============================================================================

class _LegendWidget extends StatelessWidget {
  final VoidCallback onClose;

  const _LegendWidget({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [_defaultBoxShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('legend_title'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onClose,
                  child: Icon(Icons.close, size: 20.sp),
                ),
              )
            ],
          ),
          const Divider(),
          // Legend items
          ..._typeIconMap.entries.map((e) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    e.value['icon'] as IconData,
                    color: e.value['color'] as Color,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    e.key,
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ============================================================================
// PROVIDER DETAILS SHEET
// ============================================================================

class _ProviderDetailsSheet extends StatelessWidget {
  final ProviderEntity provider;

  const _ProviderDetailsSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.all(24.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              // Provider name
              Text(
                provider.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8.h),

              // Provider type
              Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    provider.type,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),
              const Divider(),

              // Provider details
              _InfoRow(Icons.place, provider.address),
              _InfoRow(Icons.phone, provider.phone, isPhone: true),
              if (provider.discountPct.isNotEmpty)
                _InfoRow(Icons.discount, 'خصم: ${provider.discountPct}%'),

              SizedBox(height: 20.h),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl('tel:${provider.phone}'),
                      icon: const Icon(Icons.call),
                      label: Text(context.tr('call_button')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(provider.mapUrl),
                      icon: const Icon(Icons.map),
                      label: Text(context.tr('location_button')),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}

// ============================================================================
// INFO ROW WIDGET
// ============================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isPhone;

  const _InfoRow(
    this.icon,
    this.text, {
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 20.sp, color: Theme.of(context).primaryColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              textDirection: isPhone ? TextDirection.ltr : TextDirection.rtl,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BITMAP ICON CACHE
// ============================================================================

/// Manages and caches bitmap icons for provider types to improve performance
class _MapIconCache {
  final Map<String, BitmapDescriptor> _iconCache = {};
  final Map<String, BitmapDescriptor> _selectedIconCache = {};

  bool get isInitialized => _iconCache.isNotEmpty;

  /// Generate and cache icons for all provider types
  Future<void> generateTypeIcons(
    Map<String, Map<String, dynamic>> typeIconMap,
  ) async {
    try {
      for (final entry in typeIconMap.entries) {
        final type = entry.key;
        final iconData = entry.value['icon'] as IconData;
        final color = entry.value['color'] as Color;

        // Generate normal icons
        _iconCache[type] = await _BitmapGenerator.fromIcon(
          iconData,
          color,
          size: _iconDefaultSize.toInt(),
        );

        // Generate selected icons
        _selectedIconCache[type] = await _BitmapGenerator.fromIcon(
          iconData,
          color,
          size: _iconSelectedSize.toInt(),
          isSelected: true,
        );
      }

      // Generate default icons
      _iconCache['default'] = await _BitmapGenerator.fromIcon(
        Icons.location_on,
        Colors.blue,
        size: _iconDefaultSize.toInt(),
      );

      _selectedIconCache['default'] = await _BitmapGenerator.fromIcon(
        Icons.location_on,
        Colors.blue,
        size: _iconSelectedSize.toInt(),
        isSelected: true,
      );
    } catch (e) {
      debugPrint('Error generating icons: $e');
    }
  }

  /// Get icon for a provider type
  BitmapDescriptor? getIcon(String type) => _iconCache[type];

  /// Get selected icon for a provider type
  BitmapDescriptor? getSelectedIcon(String type) => _selectedIconCache[type];

  /// Get default icon
  BitmapDescriptor? getDefaultIcon() => _iconCache['default'];

  /// Get default selected icon
  BitmapDescriptor? getDefaultSelectedIcon() => _selectedIconCache['default'];

  /// Clear cache
  void dispose() {
    _iconCache.clear();
    _selectedIconCache.clear();
  }
}

// ============================================================================
// BITMAP GENERATOR
// ============================================================================

/// Generates bitmap icons from Flutter IconData
class _BitmapGenerator {
  static Future<BitmapDescriptor> fromIcon(
    IconData iconData,
    Color color, {
    int size = 80,
    bool isSelected = false,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double iconSize = size.toDouble();

    // Draw background circle
    final Paint backgroundPaint = Paint()
      ..color = isSelected ? color : Colors.white;
    canvas.drawCircle(
      Offset(iconSize / 2, iconSize / 2),
      iconSize / 2,
      backgroundPaint,
    );

    // Draw border circle
    final Paint borderPaint = Paint()
      ..color = isSelected ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _iconBorderWidth;
    canvas.drawCircle(
      Offset(iconSize / 2, iconSize / 2),
      iconSize / 2 - 2,
      borderPaint,
    );

    // Draw icon
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: iconSize * 0.6,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: isSelected ? Colors.white : color,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (iconSize - textPainter.width) / 2,
        (iconSize - textPainter.height) / 2,
      ),
    );

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}

// ============================================================================
// LOCATION SERVICE
// ============================================================================

/// Handles location permissions and location fetching
class _LocationService {
  static Future<LatLng?> getCurrentLocation(BuildContext context) async {
    try {
      // Check if location services are enabled
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDisabledDialog(context);
        return null;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog(context);
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  static void _showLocationDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(context.tr('location_disabled_title')),
        content: Text(context.tr('location_disabled_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }

  static void _showLocationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(context.tr('location_permission_title')),
        content: Text(context.tr('location_permission_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('ok')),
          ),
          TextButton(
            onPressed: () {
              Geolocator.openLocationSettings();
              Navigator.of(context).pop();
            },
            child: Text(context.tr('settings')),
          ),
        ],
      ),
    );
  }
}
