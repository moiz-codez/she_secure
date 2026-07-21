import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_secure/features/contacts/data/contacts_repository.dart';
import 'package:she_secure/features/contacts/data/contacts_providers.dart';
import 'package:she_secure/shared/theme/app_colors.dart';
import 'package:she_secure/shared/theme/app_text_styles.dart';

class EditContactSheet extends ConsumerStatefulWidget {
  final dynamic contact;

  const EditContactSheet({super.key, required this.contact});

  @override
  ConsumerState<EditContactSheet> createState() => _EditContactSheetState();
}

class _EditContactSheetState extends ConsumerState<EditContactSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _relationshipController;
  late bool _notifyViaSms;
  late bool _notifyViaWhatsapp;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _phoneController = TextEditingController(text: widget.contact.phone);
    _relationshipController = TextEditingController(
      text: widget.contact.relationship ?? '',
    );
    _notifyViaSms = widget.contact.notifyVia.contains('sms');
    _notifyViaWhatsapp = widget.contact.notifyVia.contains('whatsapp');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(contactsRepositoryProvider);

      final notifyVia = <String>[];
      if (_notifyViaSms) notifyVia.add('sms');
      if (_notifyViaWhatsapp) notifyVia.add('whatsapp');

      final updated = widget.contact.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        relationship: _relationshipController.text.trim().isEmpty
            ? null
            : _relationshipController.text.trim(),
        notifyVia: notifyVia,
      );

      await repo.updateContact(updated);
      if (mounted) Navigator.pop(context);
    } on DuplicatePhoneException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update contact')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Edit contact',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone *',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship (optional)',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Notify via',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ChannelToggle(
                  label: 'SMS',
                  isSelected: _notifyViaSms,
                  onChanged: (v) => setState(() => _notifyViaSms = v),
                ),
                const SizedBox(width: 12),
                _ChannelToggle(
                  label: 'WhatsApp',
                  isSelected: _notifyViaWhatsapp,
                  onChanged: (v) => setState(() => _notifyViaWhatsapp = v),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save changes'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ChannelToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _ChannelToggle({
    required this.label,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentBrand.withValues(alpha: 0.2)
              : AppColors.bgElevated2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accentBrand : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.accentBrand : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
