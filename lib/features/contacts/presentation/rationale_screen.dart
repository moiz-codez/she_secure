import 'package:flutter/material.dart';
import 'package:she_secure/shared/theme/app_colors.dart';
import 'package:she_secure/shared/theme/app_text_styles.dart';

class RationaleScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const RationaleScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Contacts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              'Access phone contacts?',
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'SheSecure needs access to your phone contacts to let you quickly add trusted contacts from your address book.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'What we access:',
              style: AppTextStyles.sectionLabel,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.person,
              text: 'Contact names and phone numbers',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.lock,
              text: 'Only used for adding trusted contacts',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.storage,
              text: 'Not stored or shared with anyone',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accentBrand),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
