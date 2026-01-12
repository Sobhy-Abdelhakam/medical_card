import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Empty state widget
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40.w,
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.verticalLg,
            Text(
              title,
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              AppSpacing.verticalSm,
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              AppSpacing.verticalXxl,
              SizedBox(
                width: 200.w,
                child: AppPrimaryButton(
                  text: buttonText!,
                  onPressed: onButtonPressed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state widget
class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onRetry;
  final IconData? icon;

  const AppErrorState({
    super.key,
    this.title = 'حدث خطأ',
    required this.message,
    this.buttonText,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
                icon ?? Icons.error_outline_rounded,
                size: 40.w,
                color: AppColors.error,
              ),
            ),
            AppSpacing.verticalLg,
            Text(
              title,
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSm,
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.verticalXxl,
              SizedBox(
                width: 200.w,
                child: AppPrimaryButton(
                  text: buttonText ?? 'إعادة المحاولة',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Network error state widget
class AppNetworkError extends StatelessWidget {
  final VoidCallback? onRetry;

  const AppNetworkError({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: 'لا يوجد اتصال',
      message: 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً',
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
    );
  }
}

/// Info banner widget
class AppInfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onDismiss;

  const AppInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.backgroundColor,
    this.textColor,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.infoLight,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: (textColor ?? AppColors.info).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: textColor ?? AppColors.info,
            size: AppSpacing.iconMd,
          ),
          AppSpacing.horizontalMd,
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: textColor ?? AppColors.info,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            AppSpacing.horizontalSm,
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                color: textColor ?? AppColors.info,
                size: AppSpacing.iconSm,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Success banner widget
class AppSuccessBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const AppSuccessBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AppInfoBanner(
      message: message,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: AppColors.successLight,
      textColor: AppColors.success,
      onDismiss: onDismiss,
    );
  }
}

/// Warning banner widget
class AppWarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const AppWarningBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AppInfoBanner(
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: AppColors.warningLight,
      textColor: AppColors.warning,
      onDismiss: onDismiss,
    );
  }
}
