import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../model/dataModel.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  final String allProvidersUrl =
      "https://providers.euro-assist.com/api/arabic-providers";
  final String topProvidersUrl =
      "https://providers.euro-assist.com/api/top-providers";

  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  List<ServiceProvider> _allServiceProviders = [];
  List<ServiceProvider> _filteredProviders = [];
  List<TopProvider> _topProviders = [];
  List<String> _cities = [];

  // Filter and search state
  String? _selectedCity;
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _fetchAllData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch all data in parallel
      final responses = await Future.wait([
        http.get(Uri.parse(allProvidersUrl)),
        http.get(Uri.parse(topProvidersUrl)),
      ]);

      // Process all providers response
      if (responses[0].statusCode == 200) {
        final List<dynamic> dataList = json.decode(responses[0].body);
        final Set<String> citySet = {};
        final providersList = dataList.map((item) {
          final provider = ServiceProvider.fromJson(item);
          if (provider.city.isNotEmpty) citySet.add(provider.city);
          return provider;
        }).toList();

        _allServiceProviders = providersList;
        _cities = citySet.toList()..sort();
      } else {
        throw Exception('Failed to load service providers');
      }

      // Process top providers response
      if (responses[1].statusCode == 200) {
        final jsonData = json.decode(responses[1].body);
        if (jsonData['success'] == true && jsonData['data'] is List) {
          _topProviders = (jsonData['data'] as List)
              .map((item) => TopProvider.fromJson(item))
              .toList();
        }
      } // Silently fail for top providers if needed

      _applyFilters();
    } catch (e) {
      _errorMessage = "فشل تحميل البيانات، تأكد من اتصال الإنترنت.";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProviders = _allServiceProviders.where((provider) {
        final searchTearm = _searchController.text.toLowerCase();
        final matchesCity =
            _selectedCity == null || provider.city == _selectedCity;
        final matchesSearch = searchTearm.isEmpty ||
            provider.name.toLowerCase().contains(searchTearm);
        return matchesCity && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: _isLoading
              ? _buildLoading()
              : _errorMessage != null
                  ? _buildError()
                  : RefreshIndicator(
                      onRefresh: _fetchAllData,
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          _buildSectionTitle("كبار الشركاء"),
                          _buildTopProvidersGrid(),
                          _buildSectionTitle("ابحث في الشبكة الطبية"),
                          _buildFiltersSection(),
                          _buildProvidersSliverList(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildLoading() =>
      const Center(child: CircularProgressIndicator());

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _fetchAllData,
              child: const Text("إعادة المحاولة"),
            )
          ],
        ),
      );

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Text(
          title,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTopProvidersGrid() {
    if (_topProviders.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              MediaQuery.of(context).orientation == Orientation.landscape
                  ? 4
                  : 2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 0.9,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final topProvider = _topProviders[index];
            return _TopProviderCard(
              provider: topProvider,
              onTap: () {
                _searchController.text = topProvider.nameArabic;
                // Scroll to the list
                final targetPosition = _scrollController.position.maxScrollExtent / 2;
                _scrollController.animateTo(
                  targetPosition,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
            );
          },
          childCount: _topProviders.length,
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                ),
                filled: true,
                fillColor: Colors.grey[200],
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
                  ),
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
      ),
    );
  }

  Widget _buildProvidersSliverList() {
    if (_filteredProviders.isEmpty && _searchController.text.isNotEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text("لا توجد نتائج مطابقة للبحث")),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final provider = _filteredProviders[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: _ServiceProviderCard(provider: provider),
          );
        },
        childCount: _filteredProviders.length,
      ),
    );
  }
}

// --- WIDGETS ---

class _TopProviderCard extends StatelessWidget {
  final TopProvider provider;
  final VoidCallback onTap;

  const _TopProviderCard({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  provider.logoUrl,
                  height: 80.w,
                  width: 80.w,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.business, size: 80.w, color: Colors.grey),
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: Text(
                  provider.nameArabic,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceProviderCard extends StatelessWidget {
  final ServiceProvider provider;

  const _ServiceProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.name,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 8.h),
            _InfoRow(icon: Icons.category, text: provider.type),
            if (provider.city.isNotEmpty)
              _InfoRow(icon: Icons.location_city, text: provider.city),
            if (provider.address.isNotEmpty)
              _InfoRow(icon: Icons.place, text: provider.address),
            if (provider.discount.isNotEmpty)
              _InfoRow(
                  icon: Icons.discount,
                  text: provider.discount,
                  color: Colors.green),
            if (provider.phone.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: ElevatedButton.icon(
                  onPressed: () => _showCallDialog(context, provider.phone),
                  icon: const Icon(Icons.phone),
                  label: const Text("اتصال"),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
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
          title: const Text('اختر رقم للاتصال'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: numbers
                  .map((number) => ListTile(
                        leading: const Icon(Icons.phone),
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 18.w, color: color ?? Colors.grey[700]),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }
}