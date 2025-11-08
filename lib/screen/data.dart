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
  String get apiUrl => "https://providers.euro-assist.com/api/arabic-providers";

  List<ServiceProvider> allServiceProviders = [];
  List<ServiceProvider> filteredProviders = [];
  List<String> cities = [];
  String? selectedCity;
  bool isLoading = false;
  String? errorMessage;

  final ScrollController _scrollController = ScrollController();

  // Provider name filter
  List<String> providerNames = [];
  String? selectedProviderName;

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchProviderNames();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      bool searchOnlyArg = widget.searchOnly;
      String? typeArg;

      if (args is Map) {
        if (args['search'] != null && args['search'].toString().isNotEmpty) {
          setState(() {
            searchQuery = args['search'];
            _searchController.text = searchQuery;
          });
        }

        if (args['searchOnly'] == true) searchOnlyArg = true;
        if (args['type'] != null) {
          typeArg = args['type'];
        }
      }

      fetchData(searchOnly: searchOnlyArg, type: typeArg);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // No pagination in new API, so no infinite scroll needed
  }

  Future<void> fetchProviderNames() async {
    try {
      final response = await http.get(Uri.parse(
          "https://providers.euro-assist.com/api/arabic-providers/distinct/names"));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          providerNames = List<String>.from(jsonData['names'] ?? []);
        });
      }
    } catch (e) {
      // ignore error
    }
  }

  Future<void> fetchData({bool? searchOnly, String? type}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      allServiceProviders.clear();
      filteredProviders.clear();
      cities.clear();
    });

    try {
      String url = apiUrl;

      if (searchOnly ?? widget.searchOnly) {
        if (searchQuery.isNotEmpty) {
          url += "?search=${Uri.encodeComponent(searchQuery)}";
        }
      } else {
        bool hasQuery = false;
        if (type != null && type.isNotEmpty) {
          url += "?type=${Uri.encodeComponent(type)}";
          hasQuery = true;
        } else if (widget.item.isNotEmpty) {
          url += "?type=${Uri.encodeComponent(widget.item)}";
          hasQuery = true;
        }
        if (searchQuery.isNotEmpty) {
          url +=
              "${hasQuery ? '&' : '?'}search=${Uri.encodeComponent(searchQuery)}";
        }
      }
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
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
        throw Exception('خطأ في تحميل البيانات:  {response.statusCode}');
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

  void filterData() {
    setState(() {
      filteredProviders = allServiceProviders
          .where((provider) =>
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone,
                    size: isLandscape ? 28.w : 32.w,
                    color: Theme.of(context).colorScheme.primary,
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
                            leading:
                                Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: isLandscape
            ? null
            : AppBar(
                iconTheme: const IconThemeData(color: Colors.white),
                backgroundColor: Theme.of(context).colorScheme.primary,
                title: Text(widget.item,
                    style: const TextStyle(color: Colors.white)),
              ),
        body: SafeArea(
          top: !isLandscape,
          child: RefreshIndicator(
            onRefresh: () async {
              await fetchData();
            },
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
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
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isLandscape ? 16.w : 8.w,
                              vertical: isLandscape ? 8.h : 0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: selectedCity,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.w),
                                        borderSide: BorderSide(
                                            color: Theme.of(context).colorScheme.primary,
                                            width: 1.w),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: isLandscape ? 8.h : 12.h,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    hint: Text(
                                      "اختر المدينة",
                                      style: TextStyle(
                                          fontSize:
                                              isLandscape ? 14.sp : 16.sp),
                                    ),
                                    isExpanded: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedCity = newValue;
                                        filterData();
                                      });
                                    },
                                    items: cities.map<DropdownMenuItem<String>>(
                                        (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                              fontSize:
                                                  isLandscape ? 14.sp : 16.sp),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Search box
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: isLandscape ? 16.w : 8.w,
                                vertical: 8.h),
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (value) async {
                                searchQuery = value.trim();
                                await fetchData();
                              },
                              decoration: InputDecoration(
                                hintText: 'ابحث باسم مقدم الخدمة...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.w),
                                  borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary, width: 1.w),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 12.h),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: isLandscape ? 8.h : 0),
                          Expanded(
                            child: filteredProviders.isEmpty
                                ? Center(
                                    child: Text(
                                      "لا توجد بيانات متاحة",
                                      style: TextStyle(
                                          fontSize:
                                              isLandscape ? 14.sp : 16.sp),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isLandscape ? 16.w : 8.w,
                                      vertical: 8.h,
                                    ),
                                    itemCount: filteredProviders.length,
                                    itemBuilder: (context, index) {
                                      final provider = filteredProviders[index];
                                      return GestureDetector(
                                        onTap: () => _showProviderDetailsPopup(
                                            provider, isLandscape),
                                        child: Card(
                                          margin: EdgeInsets.symmetric(
                                            horizontal: isLandscape ? 4.w : 8.w,
                                            vertical: 8.h,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.w),
                                          ),
                                          elevation: 2,
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal:
                                                  isLandscape ? 12.w : 16.w,
                                              vertical:
                                                  isLandscape ? 8.h : 12.h,
                                            ),
                                            leading: Icon(
                                              Icons.business,
                                              color: Theme.of(context).colorScheme.primary,
                                              size: isLandscape ? 28.w : 32.w,
                                            ),
                                            title: Text(
                                              provider.name,
                                              style: TextStyle(
                                                fontSize:
                                                    isLandscape ? 16.sp : 18.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Padding(
                                              padding:
                                                  EdgeInsets.only(top: 8.h),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (provider.city.isNotEmpty)
                                                    _infoRow(Icons.location_on,
                                                        provider.city),
                                                  if (provider
                                                      .address.isNotEmpty)
                                                    _infoRow(Icons.place,
                                                        provider.address),
                                                  if (provider.phone.isNotEmpty)
                                                    _infoRow(Icons.phone,
                                                        provider.phone,
                                                        isLink: true,
                                                        onTap: () {
                                                      _showCallDialog(context,
                                                          provider.phone);
                                                    }),
                                                  if (provider
                                                      .discount.isNotEmpty)
                                                    _infoRow(Icons.discount,
                                                        provider.discount,
                                                        color: Colors.green),
                                                  if (provider.specialization !=
                                                          null &&
                                                      provider.specialization!
                                                          .isNotEmpty)
                                                    _infoRow(
                                                        Icons.medical_services,
                                                        provider
                                                            .specialization!,
                                                        color: Colors.purple),
                                                  if (provider.package !=
                                                          null &&
                                                      provider
                                                          .package!.isNotEmpty)
                                                    _infoRow(
                                                        Icons.card_giftcard,
                                                        provider.package!,
                                                        color: Colors.orange),
                                                  if (provider
                                                      .mapUrl.isNotEmpty)
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          top: 8.h),
                                                      child:
                                                          ElevatedButton.icon(
                                                        onPressed: () =>
                                                            _openLocationOnMap(
                                                                provider
                                                                    .mapUrl),
                                                        icon: Icon(Icons.map),
                                                        label: const Text(
                                                            'افتح في خرائط جوجل'),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.blue,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.w),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                          ),
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
                      )),
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
