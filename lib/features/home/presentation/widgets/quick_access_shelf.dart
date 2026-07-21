import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:she_secure/shared/theme/app_colors.dart';
import 'package:she_secure/shared/theme/app_text_styles.dart';

class QuickAccessShelf extends StatelessWidget {
  const QuickAccessShelf({super.key});

  static const _items = [
    _ShelfItem(
      label: 'Trusted\nContacts',
      icon: PhosphorIconsBold.usersThree,
      route: '/contacts',
    ),
    _ShelfItem(
      label: 'Location',
      icon: PhosphorIconsBold.mapPin,
      route: '/location',
    ),
    _ShelfItem(
      label: 'Recordings',
      icon: PhosphorIconsBold.videoCamera,
      route: '/recordings',
    ),
    _ShelfItem(
      label: 'Fake\nCall',
      icon: PhosphorIconsBold.phoneCall,
      route: '/fake-call',
    ),
    _ShelfItem(
      label: 'Tutorial',
      icon: PhosphorIconsBold.graduationCap,
      route: '/tutorial',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _ShelfCard(
            label: item.label,
            icon: item.icon,
            onTap: () => context.push(item.route),
          );
        },
      ),
    );
  }
}

class _ShelfItem {
  final String label;
  final IconData icon;
  final String route;

  const _ShelfItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class _ShelfCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ShelfCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.accentBrand, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.captionSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
