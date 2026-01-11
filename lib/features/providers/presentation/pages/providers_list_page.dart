import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../di/injection_container.dart';
import '../../domain/entities/provider_entity.dart';
import '../cubit/providers_list/providers_list_cubit.dart';
import '../widgets/widgets.dart';

/// Page for displaying a list of providers with search and filter
class ProvidersListPage extends StatefulWidget {
  final String? type;
  final String? searchName;
  final bool searchOnly;

  const ProvidersListPage({
    super.key,
    this.type,
    this.searchName,
    this.searchOnly = false,
  });

  @override
  State<ProvidersListPage> createState() => _ProvidersListPageState();
}

class _ProvidersListPageState extends State<ProvidersListPage> {
  late final ProvidersListCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCity;

  static const int _minSearchChars = 3;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ProvidersListCubit>();
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    if (widget.searchOnly && widget.searchName != null) {
      _cubit.loadProviders(
        searchName: widget.searchName,
        type: widget.type,
        paginate: false,
      );
    } else {
      _cubit.loadProviders(
        type: widget.type,
        paginate: true,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted() {
    final query = _searchController.text.trim();
    if (query.length < _minSearchChars) return;

    FocusScope.of(context).unfocus();
    _cubit.applySearch(query);
  }

  void _onCityChanged(String? city) {
    setState(() => _selectedCity = city);
    _cubit.filterByCity(city);
  }

  Future<void> _openPhoneDialog(ProviderEntity provider) async {
    final numbers = provider.phone
        .split('/')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (numbers.isEmpty) return;

    if (numbers.length == 1) {
      await _makePhoneCall(numbers.first);
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                      _makePhoneCall(number);
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
      ),
    );
  }

  Future<void> _makePhoneCall(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إجراء المكالمة')),
        );
      }
    }
  }

  Future<void> _openMap(String mapUrl) async {
    final uri = Uri.parse(mapUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح خرائط جوجل')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: Text(
              widget.type ?? 'مقدمي الخدمات',
              style: const TextStyle(color: Colors.white),
            ),
            elevation: 2,
          ),
          body: RefreshIndicator(
            onRefresh: () => _cubit.refresh(),
            child: Column(
              children: [
                _buildFilterControls(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            onSubmitted: (_) => _onSearchSubmitted(),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: _searchController.text.length >= _minSearchChars
                    ? _onSearchSubmitted
                    : null,
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
          // City Filter
          BlocBuilder<ProvidersListCubit, ProvidersListState>(
            builder: (context, state) {
              if (state is! ProvidersListLoaded ||
                  state.availableCities.isEmpty) {
                return const SizedBox.shrink();
              }

              return DropdownButtonFormField<String?>(
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
                onChanged: _onCityChanged,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('كل المدن'),
                  ),
                  ...state.availableCities.map(
                    (city) => DropdownMenuItem<String?>(
                      value: city,
                      child: Text(city),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<ProvidersListCubit, ProvidersListState>(
      builder: (context, state) {
        return switch (state) {
          ProvidersListInitial() => const LoadingStateWidget(
              message: 'جاري تحميل البيانات...',
            ),
          ProvidersListLoading() => const LoadingStateWidget(
              message: 'جاري تحميل البيانات...',
            ),
          ProvidersListError(:final message) => ErrorStateWidget(
              message: message,
              onRetry: _loadInitialData,
            ),
          ProvidersListLoaded(:final providers, :final hasMorePages, :final isLoadingMore) =>
            providers.isEmpty
                ? const EmptyStateWidget(
                    title: 'لا توجد نتائج مطابقة',
                    icon: Icons.search_off,
                  )
                : _buildProvidersList(providers, hasMorePages, isLoadingMore),
        };
      },
    );
  }

  Widget _buildProvidersList(
    List<ProviderEntity> providers,
    bool hasMorePages,
    bool isLoadingMore,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(12.w),
      itemCount: providers.length + (hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= providers.length) {
          if (isLoadingMore) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: OutlinedButton.icon(
              onPressed: () => _cubit.loadNextPage(),
              icon: const Icon(Icons.expand_more),
              label: const Text('تحميل المزيد'),
            ),
          );
        }

        final provider = providers[index];
        return ProviderCard(
          provider: provider,
          onCallTap: () => _openPhoneDialog(provider),
          onLocationTap: () => _openMap(provider.mapUrl),
        );
      },
    );
  }
}
