import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:she_secure/shared/theme/app_colors.dart';
import 'package:she_secure/shared/theme/app_text_styles.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bgBase,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'SheSecure',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.accentBrand,
                ),
              ),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: PhosphorIconsBold.house,
                    label: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/home');
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsBold.usersThree,
                    label: 'Trusted Contacts',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/contacts');
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsBold.mapPin,
                    label: 'Location',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/location');
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsBold.videoCamera,
                    label: 'Recordings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/recordings');
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsBold.phoneCall,
                    label: 'Fake Call',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/fake-call');
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsBold.graduationCap,
                    label: 'Tutorial',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/tutorial');
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsBold.gearSix,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsBold.user,
                    label: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  _DrawerItem(
                    icon: PhosphorIconsBold.signOut,
                    label: 'Log out',
                    color: AppColors.accentAlert,
                    onTap: () async {
                      Navigator.pop(context);
                      final confirmed = await showModalBottomSheet<bool>(
                        context: context,
                        backgroundColor: AppColors.bgElevated,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.borderSubtle,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Log out?',
                                style: AppTextStyles.headingMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You\'ll need to sign in again to use SheSecure.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accentAlert,
                                      ),
                                      child: const Text('Log out'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.textPrimary;

    return ListTile(
      leading: Icon(icon, color: itemColor, size: 22),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(color: itemColor),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: const RoundedRectangleBorder(),
    );
  }
}
