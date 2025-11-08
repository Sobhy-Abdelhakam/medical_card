import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../model/dataModel.dart';
import 'data.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  String get apiUrl => "https://providers.euro-assist.com/api/arabic-providers";
  final String topProvidersUrl =
      "https://providers.euro-assist.com/api/top-providers";

  List<ServiceProvider> allServiceProviders = [];
  List<ServiceProvider> filteredProviders = [];
  List<String> cities = [];
  String? selectedCity;
  bool isLoading = false;
  String? errorMessage;

  List<TopProvider> topProviders = [];
  bool isLoadingTopProviders = false;
  String? topProvidersError;

  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // Hardcoded major partners

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchTopProviders();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      allServiceProviders.clear();
      filteredProviders.clear();
      cities.clear();
    });

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> dataList = json.decode(response.body);
        Set<String> citySet = Set.from(cities);
        List<ServiceProvider> providersList = [];

        for (var item in dataList) {
          final provider = ServiceProvider.fromJson(item);
          providersList.add(provider);
          if (provider.city.isNotEmpty) citySet.add(provider.city);
        }

        setState(() {
          allServiceProviders = providersList;
          cities = citySet.toList();
          filterData();
        });
      } else {
        throw Exception('خطأ في تحميل البيانات: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = "فشل تحميل البيانات، تأكد من اتصال الإنترنت.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTopProviders() async {
    setState(() {
      isLoadingTopProviders = true;
      topProvidersError = null;
      topProviders.clear();
    });
    try {
      final response = await http
          .get(Uri.parse(topProvidersUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] is List) {
          setState(() {
            topProviders = (jsonData['data'] as List)
                .map((item) => TopProvider.fromJson(item))
                .toList();
          });
        } else {
          throw Exception('خطأ في تحميل كبار الشركاء');
        }
      } else {
        throw Exception('خطأ في تحميل كبار الشركاء: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        topProvidersError = "فشل تحميل كبار الشركاء";
      });
    } finally {
      setState(() {
        isLoadingTopProviders = false;
      });
    }
  }

  void filterData() {
    setState(() {
      filteredProviders = allServiceProviders
          .where((provider) =>
              (selectedCity == null || provider.city == selectedCity))
          .toList();
    });
  }

  void searchPartner(String searchTerm) {
    setState(() {
      searchQuery = searchTerm;
      filteredProviders = allServiceProviders
          .where((provider) =>
              provider.name.toLowerCase().contains(searchTerm.toLowerCase()) &&
              (selectedCity == null || provider.city == selectedCity))
          .toList();
    });
  }

  List<String> _splitPhoneNumbers(String phoneNumbers) {
    return phoneNumbers
        .split('/')
        .map((number) => number.trim())
        .where((number) => number.isNotEmpty)
        .toList();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'تعذر فتح تطبيق الهاتف';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر الاتصال: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCallDialog(BuildContext context, String phoneNumbers) {
    final theme = Theme.of(context);
    final List<String> numbers = _splitPhoneNumbers(phoneNumbers);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 80.w : 20.w,
            vertical: isLandscape ? 20.h : 80.h,
          ),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone,
                    size: isLandscape ? 28.w : 32.w,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'اختر رقم للاتصال',
                  style: TextStyle(
                    fontSize: isLandscape ? 16.sp : 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  height: isLandscape ? 120.h : null,
                  child: SingleChildScrollView(
                    child: Column(
                      children: numbers.map((number) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: ListTile(
                            leading: Icon(Icons.phone,
                                color: theme.colorScheme.primary),
                            title: Text(
                              number,
                              style: TextStyle(
                                fontSize: isLandscape ? 14.sp : 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _makePhoneCall(number);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('إلغاء'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          top: !isLandscape,
          child: RefreshIndicator(
            onRefresh: () async {
              await fetchData();
              await fetchTopProviders();
            },
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: theme.colorScheme.primary))
                : errorMessage != null
                    ? Center(
                        child: Text(
                          errorMessage!,
                          style:
                              TextStyle(fontSize: isLandscape ? 14.sp : 16.sp),
                        ),
                      )
                    : Column(
                        children: [
                          if (!isLandscape) SizedBox(height: 8.h),
                          // Top Providers Horizontal List
                          if (isLoadingTopProviders)
                            SizedBox(
                              height: 100.h,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: theme.colorScheme.primary)),
                            )
                          else if (topProvidersError != null)
                            Padding(
                              padding: EdgeInsets.all(8.w),
                              child: Text(topProvidersError!,
                                  style: TextStyle(color: Colors.red)),
                            )
                          else if (topProviders.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isLandscape ? 24.w : 16.w),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16.w,
                                  mainAxisSpacing: 16.h,
                                  childAspectRatio:
                                      0.95, // Adjust for card shape
                                ),
                                itemCount: topProviders.length,
                                itemBuilder: (context, idx) {
                                  final top = topProviders[idx];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ShowData(
                                            item: '',
                                            searchOnly: true,
                                            key: UniqueKey(),
                                          ),
                                          settings: RouteSettings(
                                            arguments: {
                                              'search': top.nameArabic,
                                              'searchOnly': true,
                                              'type': top
                                                  .typeArabic, // Add the type field here
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18.w),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(16.w),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12.w),
                                              child: Image.network(
                                                top.logoUrl,
                                                height: 80.w,
                                                width: 80.w,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Icon(Icons.broken_image,
                                                        size: 80.w),
                                              ),
                                            ),
                                            SizedBox(height: 16.h),
                                            Text(
                                              top.nameArabic,
                                              style: TextStyle(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (!isLandscape) SizedBox(height: 8.h),

                          SizedBox(height: 16.h),

                          // City Filter
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text,
      {bool isLink = false, Color color = Colors.grey, VoidCallback? onTap}) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isLandscape ? 16.w : 18.w, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: isLink
                  ? InkWell(
                      onTap: onTap,
                      child: Text(
                        text.replaceAll('/', ' / '),
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontSize: isLandscape ? 12.sp : 14.sp,
                        ),
                      ),
                    )
                  : Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: isLandscape ? 12.sp : 14.sp),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLocationOnMap(String mapUrl) async {
    final Uri uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح خرائط جوجل')),
      );
    }
  }

  void _showProviderDetailsPopup(ServiceProvider provider, bool isLandscape) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provider.name,
                    style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
                SizedBox(height: 12.h),
                Divider(),
                if (provider.type.isNotEmpty)
                  _infoRow(Icons.category, provider.type),
                if (provider.city.isNotEmpty)
                  _infoRow(Icons.location_on, provider.city),
                if (provider.address.isNotEmpty)
                  _infoRow(Icons.place, provider.address),
                if (provider.phone.isNotEmpty)
                  _infoRow(Icons.phone, provider.phone, isLink: true,
                      onTap: () {
                    _showCallDialog(context, provider.phone);
                  }),
                if (provider.discount.isNotEmpty)
                  _infoRow(Icons.discount, provider.discount,
                      color: Colors.green),
                if (provider.specialization != null &&
                    provider.specialization!.isNotEmpty)
                  _infoRow(Icons.medical_services, provider.specialization!,
                      color: Colors.purple),
                if (provider.package != null && provider.package!.isNotEmpty)
                  _infoRow(Icons.card_giftcard, provider.package!,
                      color: Colors.orange),
                if (provider.mapUrl.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: ElevatedButton.icon(
                      onPressed: () => _openLocationOnMap(provider.mapUrl),
                      icon: Icon(Icons.map),
                      label: Text('افتح في خرائط جوجل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.w),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
