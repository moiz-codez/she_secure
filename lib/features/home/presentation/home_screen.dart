import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:she_secure/features/home/data/home_providers.dart';
import 'package:she_secure/shared/theme/app_colors.dart';
import 'package:she_secure/shared/theme/app_text_styles.dart';
import 'widgets/sos_hero_button.dart';
import 'widgets/quick_access_shelf.dart';
import 'widgets/recent_activity.dart';
import 'widgets/app_drawer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(PhosphorIconsBold.list),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: profileAsync.when(
          data: (profile) => Text(
            'Hi, ${profile?.name ?? 'there'}',
            style: AppTextStyles.headingMedium,
          ),
          loading: () => const Text('Hi...'),
          error: (e, st) => const Text('Hi'),
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsBold.gearSix),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Offline indicator
            const _OfflineIndicator(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
                  // Profile avatar tap target
                  Center(
                    child: GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: profileAsync.when(
                        data: (profile) => CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.accentBrand.withValues(alpha: 0.2),
                          child: Text(
                            (profile?.name ?? profile?.email ?? '?')[0].toUpperCase(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.accentBrand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        loading: () => const CircleAvatar(
                          radius: 20,
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (e, st) => const CircleAvatar(
                          radius: 20,
                          child: Icon(Icons.person, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SOS hero
                  Center(
                    child: SosHeroButton(
                      onPressed: () => context.push('/sos'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Press and hold isn\'t required — one tap alerts your trusted contacts.',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quick access shelf
                  const QuickAccessShelf(),
                  const SizedBox(height: 32),

                  // Recent activity
                  const RecentActivity(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineIndicator extends StatelessWidget {
  const _OfflineIndicator();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc('placeholder')
          .snapshots()
          .handleError((_) {}),
      builder: (context, snapshot) {
        final isOffline = snapshot.hasData &&
            snapshot.data!.metadata.isFromCache;

        if (!isOffline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: AppColors.accentAlert.withValues(alpha: 0.2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 16,
                color: AppColors.accentAlert,
              ),
              const SizedBox(width: 8),
              Text(
                'Offline — showing cached data',
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.accentAlert,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
