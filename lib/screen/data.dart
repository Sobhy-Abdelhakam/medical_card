import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../model/dataModel.dart';

class ShowData extends StatefulWidget {
  final String item;
  final bool searchOnly;
  const ShowData({required this.item, this.searchOnly = false, super.key});

  @override
  State<ShowData> createState() => _ShowDataState();
}

class _ShowDataState extends State<ShowData> {
  // --- State Variables ---
  static const int _minSearchCharacters = 3;
  bool _isLoading = true;
  String? _errorMessage;

  List<ServiceProvider> _allServiceProviders = [];
  List<ServiceProvider> _filteredProviders = [];
  List<String> _cities = [];
  String? _searchType;
  bool _searchOnlyMode = false;
  String _searchQuery = '';
  String? _searchNameParam;
  Map<String, dynamic>? _paginationMeta;
  int _currentPage = 1;
  int _lastPage = 1;
  int _perPage = 25;
  bool _isLoadingMore = false;

  // --- Filtering and Searching ---
  String? _selectedCity;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool get _hasMorePages => _currentPage < _lastPage;

  @override
  void initState() {
    super.initState();
    _searchOnlyMode = widget.searchOnly;
    if (widget.item.isNotEmpty) _searchType = widget.item;
    // This logic is restored from the old version to handle arguments correctly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      bool searchOnlyArg = _searchOnlyMode;
      String? typeArg = _searchType;
      String? searchNameArg;

      if (args is Map) {
        final dynamic providedSearch =
            args['searchName'] ?? args['search'] ?? args['search_text'];
        if (providedSearch != null &&
            providedSearch.toString().trim().isNotEmpty) {
          searchNameArg = providedSearch.toString().trim();
        }
        if (args['searchOnly'] == true) searchOnlyArg = true;
        if (args['type'] != null && args['type'].toString().isNotEmpty) {
          typeArg = args['type'].toString();
        }
      }

      setState(() {
        _searchOnlyMode = searchOnlyArg;
        _searchType = typeArg;
        if (searchNameArg != null && searchNameArg.isNotEmpty) {
          _searchNameParam = searchNameArg;
        }
      });

      _fetchData(
        searchOnly: searchOnlyArg,
        typeOverride: typeArg,
        searchNameOverride: searchNameArg,
      );
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- Data Fetching (Restored Logic) ---
  Future<void> _fetchData({
    bool? searchOnly,
    String? typeOverride,
    String? searchNameOverride,
    String? searchQueryOverride,
    int? pageOverride,
    bool append = false,
  }) async {
    if (!mounted) return;
    final int targetPage = pageOverride ?? 1;
    final bool isLoadMore = append && targetPage > 1;
    final String currentSearchQuery =
        (searchQueryOverride ?? _searchController.text).trim();
    final String? normalizedSearchNameOverride = searchNameOverride != null
        ? searchNameOverride.trim().isNotEmpty
            ? searchNameOverride.trim()
            : null
        : null;
    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        if (searchOnly != null) _searchOnlyMode = searchOnly;
        if (typeOverride != null) _searchType = typeOverride;
        if (normalizedSearchNameOverride != null) {
          _searchNameParam = normalizedSearchNameOverride;
        }
        _searchQuery = currentSearchQuery;
        if (targetPage == 1) {
          _paginationMeta = null;
          _currentPage = 1;
          _lastPage = 1;
        }
      });
    } else {
      setState(() {
        _isLoadingMore = true;
        _errorMessage = null;
      });
    }

    try {
      String url = "https://providers.euro-assist.com/api/arabic-providers";
      final bool shouldSearchOnly = searchOnly ?? _searchOnlyMode;
      final String? rawType = typeOverride ?? _searchType;
      final String? effectiveType =
          (rawType != null && rawType.trim().isNotEmpty)
              ? rawType.trim()
              : null;
      String? searchNameParam = normalizedSearchNameOverride ??
          (_searchNameParam != null && _searchNameParam!.trim().isNotEmpty
              ? _searchNameParam!.trim()
              : null);

      if (shouldSearchOnly) {
        searchNameParam ??=
            currentSearchQuery.isNotEmpty ? currentSearchQuery : null;
        if (searchNameParam == null || searchNameParam.isEmpty) {
          setState(() {
            _allServiceProviders = [];
            _filteredProviders = [];
            _cities = [];
            _paginationMeta = null;
            _currentPage = 1;
            _lastPage = 1;
            _isLoading = false;
          });
          return;
        }
        _searchNameParam = searchNameParam;
      }

      final List<String> queryParams = [];

      if (shouldSearchOnly) {
        queryParams.add("searchName=${Uri.encodeComponent(_searchNameParam!)}");
        if (effectiveType != null && effectiveType.isNotEmpty) {
          queryParams.add("type=${Uri.encodeComponent(effectiveType)}");
        }
        if (currentSearchQuery.isNotEmpty) {
          queryParams.add("search=${Uri.encodeComponent(currentSearchQuery)}");
        }
      } else {
        if (effectiveType != null && effectiveType.isNotEmpty) {
          queryParams.add("type=${Uri.encodeComponent(effectiveType)}");
        }
        if (currentSearchQuery.isNotEmpty) {
          queryParams.add("search=${Uri.encodeComponent(currentSearchQuery)}");
        }
      }

      final bool usePagination = !shouldSearchOnly;

      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join('&')}";
      }

      if (usePagination) {
        final List<String> paginationParams = [
          "paginate=1",
          "page=$targetPage",
          "per_page=$_perPage",
        ];
        url += queryParams.isNotEmpty
            ? "&${paginationParams.join('&')}"
            : "?${paginationParams.join('&')}";
      }

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);
        Map<String, dynamic>? paginationMeta;
        Map<String, dynamic>? metaInfo;
        List<dynamic>? rawDataList;

        if (decodedBody is Map<String, dynamic>) {
          if (decodedBody['success'] == false) {
            final String message =
                decodedBody['message']?.toString() ?? 'خطأ غير متوقع';
            throw Exception(message);
          }

          if (decodedBody['data'] is List) {
            rawDataList = List<dynamic>.from(
              decodedBody['data'] as List<dynamic>,
            );
          }

          if (usePagination) {
            if (decodedBody['pagination'] is Map) {
              paginationMeta = Map<String, dynamic>.from(
                decodedBody['pagination'] as Map<dynamic, dynamic>,
              );
            }
            if (decodedBody['meta'] is Map) {
              metaInfo = Map<String, dynamic>.from(
                decodedBody['meta'] as Map<dynamic, dynamic>,
              );
            }
          }
        } else if (decodedBody is List) {
          rawDataList = List<dynamic>.from(decodedBody);
        }

        if (rawDataList == null) {
          throw Exception('تنسيق الاستجابة غير متوقع');
        }

        final existingIds = isLoadMore
            ? _allServiceProviders.map((p) => p.id).toSet()
            : <int>{};
        final List<ServiceProvider> fetchedProviders = rawDataList
            .map(
              (item) => ServiceProvider.fromJson(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item as Map),
              ),
            )
            .where((provider) => !existingIds.contains(provider.id))
            .toList();

        final List<ServiceProvider> combinedProviders = isLoadMore
            ? [..._allServiceProviders, ...fetchedProviders]
            : fetchedProviders;

        final Set<String> citySet = {
          for (final provider in combinedProviders)
            if (provider.city.isNotEmpty) provider.city,
        };

        setState(() {
          if (usePagination) {
            _paginationMeta = paginationMeta ?? metaInfo ?? _paginationMeta;
            _currentPage = _parseInt(
              (paginationMeta ?? metaInfo)?['current_page'],
              targetPage,
            );
            _lastPage = _parseInt(
              (paginationMeta ?? metaInfo)?['last_page'],
              _currentPage,
            );
            _perPage = _parseInt(
              (paginationMeta ?? metaInfo)?['per_page'],
              _perPage,
            );
          } else {
            _paginationMeta = null;
            _currentPage = 1;
            _lastPage = 1;
          }
          _allServiceProviders = combinedProviders;
          _cities = citySet.toList()..sort();
          _applyFilters(rebuild: false);
        });
      } else {
        throw Exception('خطأ في تحميل البيانات: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      if (isLoadMore) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل المزيد من النتائج')),
        );
      } else {
        setState(() {
          _errorMessage = "فشل تحميل البيانات، تأكد من اتصال الإنترنت.";
        });
      }
    } finally {
      if (!mounted) return;
      setState(() {
        if (isLoadMore) {
          _isLoadingMore = false;
        } else {
          _isLoading = false;
        }
      });
    }
  }

  // --- Filtering Logic ---
  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {
      _searchQuery = _searchController.text.trim();
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (_searchOnlyMode) return;

    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _applyFilters();
    });
  }

  void _onSearchButtonPressed() {
    final String query = _searchController.text.trim();
    if (query.length < _minSearchCharacters) return;

    FocusScope.of(context).unfocus();

    if (_searchOnlyMode) {
      _fetchData(
        searchOnly: true,
        typeOverride: _searchType,
        searchNameOverride: _searchNameParam,
        searchQueryOverride: query,
      );
    } else {
      _fetchData(searchQueryOverride: query);
    }
  }

  void _applyFilters({bool rebuild = true}) {
    if (!mounted) return;
    final query = _searchQuery.toLowerCase();
    final bool applySearchFilter =
        !_searchOnlyMode && query.length >= _minSearchCharacters;
    final filtered = _allServiceProviders.where((provider) {
      final matchesCity =
          _selectedCity == null || provider.city == _selectedCity;
      final matchesSearch = !applySearchFilter ||
          query.isEmpty ||
          provider.name.toLowerCase().contains(query) ||
          provider.city.toLowerCase().contains(query) ||
          provider.district.toLowerCase().contains(query) ||
          provider.address.toLowerCase().contains(query) ||
          provider.type.toLowerCase().contains(query) ||
          provider.phone.toLowerCase().contains(query) ||
          (provider.specialization != null &&
              provider.specialization!.toLowerCase().contains(query)) ||
          (provider.package != null &&
              provider.package!.toLowerCase().contains(query));
      return matchesCity && matchesSearch;
    }).toList();

    if (rebuild) {
      setState(() {
        _filteredProviders = filtered;
      });
    } else {
      _filteredProviders = filtered;
    }
  }

  // --- UI Build Methods ---
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(widget.item, style: const TextStyle(color: Colors.white)),
          elevation: 2,
        ),
        body: RefreshIndicator(onRefresh: _fetchData, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _fetchData,
                child: const Text("إعادة المحاولة"),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildFilterControls(),
        Expanded(
          child: _filteredProviders.isEmpty
              ? _buildEmptyState()
              : _buildProvidersList(),
        ),
      ],
    );
  }

  Widget _buildFilterControls() {
    final bool canStartSearch = _searchQuery.length >= _minSearchCharacters;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              if (canStartSearch) _onSearchButtonPressed();
            },
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: canStartSearch ? _onSearchButtonPressed : null,
                icon: const Icon(Icons.manage_search),
                tooltip: 'ابدأ البحث',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            ),
          ),
          SizedBox(height: 12.h),
          // City Filter Dropdown
          if (_cities.isNotEmpty)
            DropdownButtonFormField<String?>(
              value: _selectedCity,
              hint: const Text('اختر مدينة'),
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCity = newValue;
                  _applyFilters(rebuild: false);
                });
              },
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('كل المدن'),
                ),
                ..._cities.map<DropdownMenuItem<String?>>((String value) {
                  return DropdownMenuItem<String?>(
                    value: value,
                    child: Text(value),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProvidersList() {
    final bool canLoadMore = _hasMorePages;
    return ListView.builder(
      padding: EdgeInsets.all(12.w),
      itemCount: _filteredProviders.length + (canLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _filteredProviders.length) {
          if (_isLoadingMore) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: OutlinedButton.icon(
              onPressed: canLoadMore ? _loadNextPage : null,
              icon: const Icon(Icons.expand_more),
              label: const Text('تحميل المزيد'),
            ),
          );
        }
        final provider = _filteredProviders[index];
        return _ProviderCard(provider: provider);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60.w, color: Colors.grey.shade400),
          SizedBox(height: 16.h),
          Text(
            "لا توجد نتائج مطابقة",
            style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNextPage() async {
    if (!_hasMorePages || _isLoadingMore) return;
    await _fetchData(pageOverride: _currentPage + 1, append: true);
  }

  int _parseInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    if (value is num) return value.toInt();
    return fallback;
  }
}

// --- Custom Widgets ---

class _ProviderCard extends StatelessWidget {
  final ServiceProvider provider;

  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.business,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          provider.name,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            provider.city,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Column(
              children: [
                const Divider(),
                if (provider.address.isNotEmpty)
                  _InfoRow(icon: Icons.place_outlined, text: provider.address),
                if (provider.discount.isNotEmpty)
                  _InfoRow(
                    icon: Icons.discount_outlined,
                    text: provider.discount,
                    color: Colors.green.shade700,
                  ),
                if (provider.specialization != null &&
                    provider.specialization!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.medical_services_outlined,
                    text: provider.specialization!,
                    color: Colors.purple.shade700,
                  ),
                if (provider.package != null && provider.package!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.card_giftcard_outlined,
                    text: provider.package!,
                    color: Colors.orange.shade700,
                  ),
                if (provider.phone.isNotEmpty)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    text: provider.phone.replaceAll('/', ' / '),
                    color: Colors.blue.shade700,
                    isLink: true,
                    onTap: () => _showCallDialog(context, provider.phone),
                  ),
                if (provider.mapUrl.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _openLocationOnMap(context, provider.mapUrl),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('افتح في خرائط جوجل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCallDialog(BuildContext context, String phoneNumbers) {
    final numbers = phoneNumbers
        .split('/')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: const Text('اختر رقم للاتصال'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: numbers
                  .map(
                    (number) => ListTile(
                      leading: Icon(
                        Icons.phone,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(number),
                      onTap: () {
                        Navigator.of(context).pop();
                        _makePhoneCall(context, number);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر إجراء المكالمة')));
    }
  }

  Future<void> _openLocationOnMap(BuildContext context, String mapUrl) async {
    final Uri uri = Uri.parse(mapUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح خرائط جوجل')));
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final bool isLink;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.color,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: InkWell(
        onTap: isLink ? onTap : null,
        borderRadius: BorderRadius.circular(8.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18.w, color: color ?? Colors.grey.shade700),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isLink ? Colors.blue.shade700 : null,
                  decoration: isLink ? TextDecoration.underline : null,
                  decorationColor: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
