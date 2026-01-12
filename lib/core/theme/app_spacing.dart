import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Application spacing constants for consistent layouts
class AppSpacing {
  AppSpacing._();

  // Base spacing units
  static double get xxs => 2.w;
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 12.w;
  static double get lg => 16.w;
  static double get xl => 20.w;
  static double get xxl => 24.w;
  static double get xxxl => 32.w;
  static double get huge => 48.w;

  // Vertical spacing
  static SizedBox get verticalXxs => SizedBox(height: xxs);
  static SizedBox get verticalXs => SizedBox(height: xs);
  static SizedBox get verticalSm => SizedBox(height: sm);
  static SizedBox get verticalMd => SizedBox(height: md);
  static SizedBox get verticalLg => SizedBox(height: lg);
  static SizedBox get verticalXl => SizedBox(height: xl);
  static SizedBox get verticalXxl => SizedBox(height: xxl);
  static SizedBox get verticalXxxl => SizedBox(height: xxxl);
  static SizedBox get verticalHuge => SizedBox(height: huge);

  // Horizontal spacing
  static SizedBox get horizontalXxs => SizedBox(width: xxs);
  static SizedBox get horizontalXs => SizedBox(width: xs);
  static SizedBox get horizontalSm => SizedBox(width: sm);
  static SizedBox get horizontalMd => SizedBox(width: md);
  static SizedBox get horizontalLg => SizedBox(width: lg);
  static SizedBox get horizontalXl => SizedBox(width: xl);
  static SizedBox get horizontalXxl => SizedBox(width: xxl);
  static SizedBox get horizontalXxxl => SizedBox(width: xxxl);

  // Padding presets
  static EdgeInsets get paddingAllXs => EdgeInsets.all(xs);
  static EdgeInsets get paddingAllSm => EdgeInsets.all(sm);
  static EdgeInsets get paddingAllMd => EdgeInsets.all(md);
  static EdgeInsets get paddingAllLg => EdgeInsets.all(lg);
  static EdgeInsets get paddingAllXl => EdgeInsets.all(xl);
  static EdgeInsets get paddingAllXxl => EdgeInsets.all(xxl);

  static EdgeInsets get paddingHorizontalSm => EdgeInsets.symmetric(horizontal: sm);
  static EdgeInsets get paddingHorizontalMd => EdgeInsets.symmetric(horizontal: md);
  static EdgeInsets get paddingHorizontalLg => EdgeInsets.symmetric(horizontal: lg);
  static EdgeInsets get paddingHorizontalXl => EdgeInsets.symmetric(horizontal: xl);
  static EdgeInsets get paddingHorizontalXxl => EdgeInsets.symmetric(horizontal: xxl);

  static EdgeInsets get paddingVerticalSm => EdgeInsets.symmetric(vertical: sm);
  static EdgeInsets get paddingVerticalMd => EdgeInsets.symmetric(vertical: md);
  static EdgeInsets get paddingVerticalLg => EdgeInsets.symmetric(vertical: lg);
  static EdgeInsets get paddingVerticalXl => EdgeInsets.symmetric(vertical: xl);
  static EdgeInsets get paddingVerticalXxl => EdgeInsets.symmetric(vertical: xxl);

  // Screen padding
  static EdgeInsets get screenPadding => EdgeInsets.symmetric(
        horizontal: lg,
        vertical: md,
      );

  static EdgeInsets get screenPaddingHorizontal => EdgeInsets.symmetric(horizontal: lg);

  // Card padding
  static EdgeInsets get cardPadding => EdgeInsets.all(lg);
  static EdgeInsets get cardPaddingCompact => EdgeInsets.all(md);

  // List item padding
  static EdgeInsets get listItemPadding => EdgeInsets.symmetric(
        horizontal: lg,
        vertical: md,
      );

  // Border radius
  static double get radiusXs => 4.r;
  static double get radiusSm => 8.r;
  static double get radiusMd => 12.r;
  static double get radiusLg => 16.r;
  static double get radiusXl => 20.r;
  static double get radiusXxl => 24.r;
  static double get radiusRound => 100.r;

  // Border radius presets
  static BorderRadius get borderRadiusXs => BorderRadius.circular(radiusXs);
  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadiusXxl => BorderRadius.circular(radiusXxl);
  static BorderRadius get borderRadiusRound => BorderRadius.circular(radiusRound);

  // Icon sizes
  static double get iconXs => 16.w;
  static double get iconSm => 20.w;
  static double get iconMd => 24.w;
  static double get iconLg => 32.w;
  static double get iconXl => 48.w;
  static double get iconXxl => 64.w;

  // Button heights
  static double get buttonHeightSm => 36.h;
  static double get buttonHeightMd => 44.h;
  static double get buttonHeightLg => 52.h;

  // Input field heights
  static double get inputHeightSm => 40.h;
  static double get inputHeightMd => 48.h;
  static double get inputHeightLg => 56.h;

  // Avatar sizes
  static double get avatarSm => 32.w;
  static double get avatarMd => 48.w;
  static double get avatarLg => 64.w;
  static double get avatarXl => 96.w;
}
