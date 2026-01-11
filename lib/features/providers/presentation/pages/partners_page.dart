import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../di/injection_container.dart';
import '../../domain/entities/top_provider_entity.dart';
import '../cubit/top_providers/top_providers_cubit.dart';
import '../pages/providers_list_page.dart';
import '../widgets/widgets.dart';

/// Page displaying top/featured providers in a grid
class PartnersPage extends StatefulWidget {
  const PartnersPage({super.key});

  @override
  State<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage> {
  late final TopProvidersCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<TopProvidersCubit>();
    _cubit.loadTopProviders();
  }

  void _onProviderTap(BuildContext context, TopProviderEntity provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProvidersListPage(
          searchName: provider.nameArabic,
          type: provider.typeArabic,
          searchOnly: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<TopProvidersCubit, TopProvidersState>(
            builder: (context, state) {
              return switch (state) {
                TopProvidersInitial() => const LoadingStateWidget(),
                TopProvidersLoading() => const LoadingStateWidget(),
                TopProvidersError(:final message) => ErrorStateWidget(
                    message: message,
                    onRetry: () => _cubit.loadTopProviders(),
                  ),
                TopProvidersLoaded(:final providers) => RefreshIndicator(
                    onRefresh: () => _cubit.refresh(),
                    child: CustomScrollView(
                      slivers: [
                        _buildSectionTitle('كبار الشركاء'),
                        _buildProvidersGrid(providers),
                        SliverToBoxAdapter(
                          child: SizedBox(height: 100.h),
                        ),
                      ],
                    ),
                  ),
              };
            },
          ),
        ),
      ),
    );
  }

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

  Widget _buildProvidersGrid(List<TopProviderEntity> providers) {
    if (providers.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyStateWidget(
          title: 'لا توجد بيانات',
          icon: Icons.business_outlined,
        ),
      );
    }

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
            final provider = providers[index];
            return TopProviderCard(
              provider: provider,
              onTap: () => _onProviderTap(context, provider),
            );
          },
          childCount: providers.length,
        ),
      ),
    );
  }
}
