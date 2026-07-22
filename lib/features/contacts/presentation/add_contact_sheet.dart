import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_secure/features/contacts/data/contacts_repository.dart';
import 'package:she_secure/features/contacts/data/contacts_providers.dart';
import 'package:she_secure/features/contacts/data/trusted_contact.dart';
import 'package:she_secure/shared/theme/app_colors.dart';
import 'package:she_secure/shared/theme/app_text_styles.dart';

class AddContactSheet extends ConsumerStatefulWidget {
  const AddContactSheet({super.key});

  @override
  ConsumerState<AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<AddContactSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  bool _notifyViaSms = true;
  bool _notifyViaWhatsapp = false;
  bool _isLoading = false;
  String? _capError;

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
      final contacts = ref.read(contactsStreamProvider).valueOrNull ?? [];

      if (contacts.length >= 5) {
        setState(() {
          _capError =
              'You can add up to 5 trusted contacts. Remove one first to add another.';
          _isLoading = false;
        });
        return;
      }

      final notifyVia = <String>[];
      if (_notifyViaSms) notifyVia.add('sms');
      if (_notifyViaWhatsapp) notifyVia.add('whatsapp');

      final contact = TrustedContact(
        id: '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        relationship: _relationshipController.text.trim().isEmpty
            ? null
            : _relationshipController.text.trim(),
        notifyVia: notifyVia,
        priority: contacts.length + 1,
        createdAt: DateTime.now(),
      );

      await repo.addContact(contact);
      if (mounted) Navigator.pop(context);
    } on ContactsLimitException catch (e) {
      if (mounted) {
        setState(() {
          _capError = e.toString();
        });
      }
    } on DuplicatePhoneException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add contact')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add contact',
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: 20),
              if (_capError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentAlert.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accentAlert.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _capError!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.accentAlert,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'Enter contact name',
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
                  hintText: '+92xxxxxxxxxx',
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
                  hintText: 'e.g. Sister, Best friend',
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
                    : const Text('Add contact'),
              ),
            ],
          ),
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
