import 'dart:async';
import 'dart:convert';
import 'package:euro_medical_card/screen/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import '../model/dataModel.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  final String topProvidersUrl =
      "https://providers.euro-assist.com/api/top-providers";

  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  List<TopProvider> _topProviders = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(topProvidersUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] is List) {
          _topProviders = (jsonData['data'] as List)
              .map((item) => TopProvider.fromJson(item))
              .toList();
        } else {
          throw Exception(
              'Failed to load top providers: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load top providers: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = "فشل تحميل البيانات، تأكد من اتصال الإنترنت.";
      debugPrint('Error fetching top providers: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        bottom: false, // Prevent SafeArea from adding padding at the bottom
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
                        // Add padding at the bottom of the list to ensure it can scroll above the nav bar
                        SliverToBoxAdapter(
                          child: SizedBox(height: 100.h),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

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
    if (_topProviders.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShowData(
                      item: '', // item is not needed when searchOnly is true
                      searchOnly: true,
                    ),
                    settings: RouteSettings(
                      arguments: {
                        'searchName': topProvider.nameArabic,
                        'searchOnly': true,
                        'type': topProvider.typeArabic,
                      },
                    ),
                  ),
                );
              },
            );
          },
          childCount: _topProviders.length,
        ),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
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
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
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
