import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_secure/features/contacts/data/contacts_repository.dart';
import 'package:she_secure/features/contacts/data/contacts_providers.dart';
import 'package:she_secure/features/contacts/data/trusted_contact.dart';
import 'package:she_secure/shared/theme/app_colors.dart';
import 'package:she_secure/shared/theme/app_text_styles.dart';

class PhoneImportSheet extends ConsumerStatefulWidget {
  const PhoneImportSheet({super.key});

  @override
  ConsumerState<PhoneImportSheet> createState() => _PhoneImportSheetState();
}

class _PhoneImportSheetState extends ConsumerState<PhoneImportSheet> {
  List<Contact>? _contacts;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      final withPhones = contacts
          .where((c) => c.phones.isNotEmpty)
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

      setState(() {
        _contacts = withPhones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error =
            'Failed to load contacts. You can add contacts manually instead.';
        _isLoading = false;
      });
    }
  }

  Future<void> _importContact(Contact phoneContact) async {
    try {
      final repo = ref.read(contactsRepositoryProvider);
      final contacts = ref.read(contactsStreamProvider).valueOrNull ?? [];

      final contact = TrustedContact(
        id: '',
        name: phoneContact.displayName,
        phone: phoneContact.phones.first.number,
        relationship: null,
        notifyVia: ['sms'],
        priority: contacts.length + 1,
        createdAt: DateTime.now(),
      );

      await repo.addContact(contact);
      if (mounted) Navigator.pop(context);
    } on ContactsLimitException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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
          const SnackBar(content: Text('Failed to import contact')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text(
                  'Select contact',
                  style: AppTextStyles.headingMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _error!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Add manually instead'),
                  ),
                ],
              ),
            )
          else if (_contacts == null || _contacts!.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No contacts with phone numbers found',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                itemCount: _contacts!.length,
                itemBuilder: (context, index) {
                  final contact = _contacts![index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.accentBrand.withValues(alpha: 0.2),
                      child: Text(
                        contact.displayName.isNotEmpty
                            ? contact.displayName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.accentBrand,
                        ),
                      ),
                    ),
                    title: Text(contact.displayName),
                    subtitle: Text(
                      contact.phones.first.number,
                      style: AppTextStyles.captionSmall,
                    ),
                    onTap: () => _importContact(contact),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
