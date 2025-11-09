import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../model/dataModel.dart';

class ShowData extends StatefulWidget {
  final String item;
  const ShowData({required this.item, super.key});

  @override
  State<ShowData> createState() => _ShowDataState();
}

class _ShowDataState extends State<ShowData> {
  // --- State Variables ---
  bool _isLoading = true;
  String? _errorMessage;

  List<ServiceProvider> _allServiceProviders = [];
  List<ServiceProvider> _filteredProviders = [];
  List<String> _cities = [];

  // --- Filtering and Searching ---
  String? _selectedCity;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- Data Fetching ---
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url =
          "https://providers.euro-assist.com/api/arabic-providers?type=${Uri.encodeComponent(widget.item)}";
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> dataList = json.decode(response.body);
        final Set<String> citySet = {};
        final providersList = dataList.map((item) {
          final provider = ServiceProvider.fromJson(item);
          if (provider.city.isNotEmpty) {
            citySet.add(provider.city);
          }
          return provider;
        }).toList();

        setState(() {
          _allServiceProviders = providersList;
          _cities = citySet.toList()..sort();
          _applyFilters(); // Apply initial filters (which will be none)
        });
      } else {
        throw Exception('خطأ في تحميل البيانات: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = "فشل تحميل البيانات، تأكد من اتصال الإنترنت.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Filtering Logic ---
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      final searchQuery = _searchController.text.toLowerCase();
      _filteredProviders = _allServiceProviders.where((provider) {
        final matchesCity =
            _selectedCity == null || provider.city == _selectedCity;
        final matchesSearch = searchQuery.isEmpty ||
            provider.name.toLowerCase().contains(searchQuery);
        return matchesCity && matchesSearch;
      }).toList();
    });
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
        body: RefreshIndicator(
          onRefresh: _fetchData,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary));
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
              )
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
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم...',
              prefixIcon: const Icon(Icons.search),
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
            DropdownButtonFormField<String>(
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCity = newValue;
                  _applyFilters();
                });
              },
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('كل المدن'),
                ),
                ..._cities.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
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
    return ListView.builder(
      padding: EdgeInsets.all(12.w),
      itemCount: _filteredProviders.length,
      itemBuilder: (context, index) {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                      color: Colors.green.shade700),
                if (provider.specialization != null &&
                    provider.specialization!.isNotEmpty)
                  _InfoRow(
                      icon: Icons.medical_services_outlined,
                      text: provider.specialization!,
                      color: Colors.purple.shade700),
                if (provider.package != null && provider.package!.isNotEmpty)
                  _InfoRow(
                      icon: Icons.card_giftcard_outlined,
                      text: provider.package!,
                      color: Colors.orange.shade700),
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
          )
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: const Text('اختر رقم للاتصال'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: numbers
                  .map((number) => ListTile(
                        leading: Icon(Icons.phone,
                            color: Theme.of(context).primaryColor),
                        title: Text(number),
                        onTap: () {
                          Navigator.of(context).pop();
                          _makePhoneCall(context, number);
                        },
                      ))
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إجراء المكالمة')),
      );
    }
  }

  Future<void> _openLocationOnMap(BuildContext context, String mapUrl) async {
    final Uri uri = Uri.parse(mapUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح خرائط جوجل')),
      );
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
