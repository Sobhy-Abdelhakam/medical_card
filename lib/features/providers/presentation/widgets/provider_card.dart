import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/provider_entity.dart';

/// A card widget displaying provider information
class ProviderCard extends StatelessWidget {
  final ProviderEntity provider;
  final VoidCallback? onTap;
  final VoidCallback? onCallTap;
  final VoidCallback? onLocationTap;

  const ProviderCard({
    super.key,
    required this.provider,
    this.onTap,
    this.onCallTap,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: provider.fullLogoUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: provider.fullLogoUrl,
                  placeholder: (context, url) => Icon(
                    Icons.business,
                    color: theme.colorScheme.primary,
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.business,
                    color: theme.colorScheme.primary,
                  ),
                )
              : Icon(
                  Icons.business,
                  color: theme.colorScheme.primary,
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
                if (provider.discountPct.isNotEmpty)
                  _InfoRow(
                    icon: Icons.discount_outlined,
                    text: provider.discountPct,
                    color: Colors.green.shade700,
                  ),
                if (provider.specialization != null &&
                    provider.specialization!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.medical_services_outlined,
                    text: provider.specialization!,
                    color: Colors.purple.shade700,
                  ),
                if (provider.package != null && provider.package!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.card_giftcard_outlined,
                    text: provider.package!,
                    color: Colors.orange.shade700,
                  ),
                if (provider.phone.isNotEmpty)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    text: provider.phone.replaceAll('/', ' / '),
                    color: Colors.blue.shade700,
                    isLink: true,
                    onTap: onCallTap,
                  ),
                if (provider.mapUrl.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onLocationTap,
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
          ),
        ],
      ),
    );
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
