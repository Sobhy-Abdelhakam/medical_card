import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/member_card_entity.dart';
import '../cubit/member_card_cubit.dart';
import '../cubit/member_card_state.dart';

/// Member Card page displaying the user's membership card
class MemberCardPage extends StatefulWidget {
  const MemberCardPage({super.key});

  @override
  State<MemberCardPage> createState() => _MemberCardPageState();
}

class _MemberCardPageState extends State<MemberCardPage> {
  @override
  void initState() {
    super.initState();
    context.read<MemberCardCubit>().loadMemberCard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<MemberCardCubit>().refreshMemberCard(),
          child: BlocBuilder<MemberCardCubit, MemberCardState>(
            builder: (context, state) {
              if (state is MemberCardLoading) {
                return _buildLoadingState();
              }

              if (state is MemberCardError) {
                return _buildErrorState(state.message);
              }

              if (state is MemberCardLoaded || state is MemberCardRefreshing) {
                final card = state is MemberCardLoaded
                    ? state.card
                    : (state as MemberCardRefreshing).card;
                return _buildCardContent(card, state is MemberCardRefreshing);
              }

              return _buildEmptyState();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          AppSpacing.verticalLg,
          Text(
            'جاري تحميل البطاقة...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 40.w,
                    color: AppColors.error,
                  ),
                ),
                AppSpacing.verticalLg,
                Text(
                  'حدث خطأ',
                  style: AppTypography.titleLarge,
                ),
                AppSpacing.verticalSm,
                Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.verticalXxl,
                SizedBox(
                  width: 200.w,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<MemberCardCubit>().loadMemberCard();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.credit_card_outlined,
                    size: 40.w,
                    color: AppColors.info,
                  ),
                ),
                AppSpacing.verticalLg,
                Text(
                  'لا توجد بطاقة',
                  style: AppTypography.titleLarge,
                ),
                AppSpacing.verticalSm,
                Text(
                  'لم يتم العثور على بطاقة عضوية مرتبطة بحسابك',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(MemberCardEntity card, bool isRefreshing) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.verticalMd,
          _buildCardHeader(),
          AppSpacing.verticalXxl,
          _buildMembershipCard(card),
          AppSpacing.verticalXxl,
          _buildCardDetails(card),
          AppSpacing.verticalXxl,
          _buildQrSection(card),
          AppSpacing.verticalXxl,
          if (isRefreshing)
            const LinearProgressIndicator(
              backgroundColor: AppColors.surfaceVariant,
            ),
          AppSpacing.verticalHuge,
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Column(
      children: [
        Text(
          'بطاقة العضوية',
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        AppSpacing.verticalXs,
        Text(
          'اعرض بطاقتك للحصول على الخصومات',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMembershipCard(MemberCardEntity card) {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Card content
          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/icons/logo.png',
                      height: 40.h,
                      color: Colors.white,
                    ),
                    _buildStatusBadge(card.status),
                  ],
                ),
                const Spacer(),
                Text(
                  card.memberNumber,
                  style: AppTypography.headlineLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalMd,
                Text(
                  card.memberName,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                AppSpacing.verticalXs,
                Text(
                  card.clubName,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MemberCardStatus status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case MemberCardStatus.active:
        bgColor = AppColors.success;
        textColor = Colors.white;
        break;
      case MemberCardStatus.expired:
        bgColor = AppColors.error;
        textColor = Colors.white;
        break;
      case MemberCardStatus.suspended:
        bgColor = AppColors.warning;
        textColor = Colors.white;
        break;
      default:
        bgColor = Colors.white.withValues(alpha: 0.2);
        textColor = Colors.white;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.borderRadiusRound,
      ),
      child: Text(
        status.displayName,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCardDetails(MemberCardEntity card) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل البطاقة',
              style: AppTypography.titleMedium,
            ),
            AppSpacing.verticalLg,
            _buildDetailRow('اسم العضو', card.memberName),
            _buildDetailRow('رقم العضوية', card.memberNumber),
            _buildDetailRow('اسم النادي', card.clubName),
            _buildDetailRow('الحالة', card.status.displayName),
            if (card.validFrom != null)
              _buildDetailRow(
                'تاريخ البدء',
                _formatDate(card.validFrom!),
              ),
            if (card.validUntil != null)
              _buildDetailRow(
                'تاريخ الانتهاء',
                _formatDate(card.validUntil!),
                isLast: true,
                highlight: card.isExpired,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isLast = false,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: highlight ? AppColors.error : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }

  Widget _buildQrSection(MemberCardEntity card) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            Text(
              'رمز QR',
              style: AppTypography.titleMedium,
            ),
            AppSpacing.verticalLg,
            Container(
              width: 180.w,
              height: 180.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: card.qrCode != null
                  ? CachedNetworkImage(
                      imageUrl: card.qrCode!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => _buildQrPlaceholder(),
                    )
                  : _buildQrPlaceholder(),
            ),
            AppSpacing.verticalMd,
            Text(
              'اعرض هذا الرمز عند مقدم الخدمة',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalLg,
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Copy member number to clipboard
                Clipboard.setData(ClipboardData(text: card.memberNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تم نسخ رقم العضوية'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('نسخ رقم العضوية'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: 80.w,
            color: AppColors.textHint,
          ),
          AppSpacing.verticalSm,
          Text(
            'QR Code',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
