import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:she_secure/features/contacts/data/contacts_providers.dart';
import 'package:she_secure/shared/theme/app_colors.dart';
import 'package:she_secure/shared/theme/app_text_styles.dart';
import 'add_contact_sheet.dart';
import 'edit_contact_sheet.dart';
import 'confirm_delete_sheet.dart';
import 'phone_import_sheet.dart';
import 'rationale_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Contacts'),
        actions: [
          if (!_isReordering)
            IconButton(
              icon: const Icon(PhosphorIconsBold.arrowsDownUp),
              onPressed: () => setState(() => _isReordering = true),
              tooltip: 'Reorder contacts',
            )
          else
            TextButton(
              onPressed: () => setState(() => _isReordering = false),
              child: const Text('Done'),
            ),
        ],
      ),
      body: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return _EmptyState(
              onAdd: () => _showAddOptions(context),
            );
          }
          return _isReordering
              ? _ReorderableList(
                  contacts: contacts,
                  onReorder: _handleReorder,
                )
              : _ContactList(
                  contacts: contacts,
                  onTap: (contact) => _showEditSheet(context, contact),
                  onDelete: (contact) => _showDeleteSheet(context, contact),
                );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, st) => Center(
          child: Text(
            'Something went wrong',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final contacts =
              ref.read(contactsStreamProvider).valueOrNull ?? const [];
          if (contacts.length >= 5) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'You can add up to 5 trusted contacts. Remove one first to add another.',
                ),
              ),
            );
            return;
          }
          _showAddOptions(context);
        },
        backgroundColor: AppColors.accentBrand,
        child: const Icon(PhosphorIconsBold.plus, color: AppColors.textPrimary),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddOptionsSheet(
        onPhoneImport: () => _showRationale(context),
        onManualAdd: () => _showAddSheet(context),
      ),
    );
  }

  void _showRationale(BuildContext context) {
    Navigator.pop(context); // Close options sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RationaleScreen(
          onContinue: () {
            Navigator.pop(context); // Close rationale
            _showPhoneImport(context);
          },
        ),
      ),
    );
  }

  void _showPhoneImport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PhoneImportSheet(),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddContactSheet(),
    );
  }

  void _showEditSheet(BuildContext context, dynamic contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditContactSheet(contact: contact),
    );
  }

  void _showDeleteSheet(BuildContext context, dynamic contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ConfirmDeleteSheet(
        contactName: contact.name,
        onConfirm: () async {
          final repo = ref.read(contactsRepositoryProvider);
          await repo.deleteContact(contact.id);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    final contacts = ref.read(contactsStreamProvider).valueOrNull;
    if (contacts == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reordered = List.from(contacts);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    final orderedIds = reordered.map<String>((c) => c.id).toList();
    final repo = ref.read(contactsRepositoryProvider);
    await repo.reorderContacts(orderedIds);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsBold.usersThree,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'No trusted contacts yet',
              style: AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add at least one so SheSecure knows who to alert.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(PhosphorIconsBold.plus),
              label: const Text('Add contact'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactList extends StatelessWidget {
  final List<dynamic> contacts;
  final void Function(dynamic) onTap;
  final void Function(dynamic) onDelete;

  const _ContactList({
    required this.contacts,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _ContactTile(
          contact: contact,
          onTap: () => onTap(contact),
          onDelete: () => onDelete(contact),
        );
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  final dynamic contact;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ContactTile({
    required this.contact,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(contact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.accentAlert,
        child: const Icon(
          PhosphorIconsBold.trash,
          color: AppColors.textPrimary,
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.accentBrand.withValues(alpha: 0.2),
          child: Text(
            contact.name[0].toUpperCase(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.accentBrand,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          contact.name,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            if (contact.relationship != null) ...[
              Text(
                contact.relationship!,
                style: AppTextStyles.captionSmall,
              ),
              const SizedBox(width: 8),
            ],
            if (contact.notifyVia.contains('sms'))
              Icon(
                PhosphorIconsBold.chatCircle,
                size: 14,
                color: AppColors.accentSafe,
              ),
            if (contact.notifyVia.contains('whatsapp')) ...[
              const SizedBox(width: 4),
              Icon(
                PhosphorIconsBold.whatsappLogo,
                size: 14,
                color: AppColors.accentSafe,
              ),
            ],
          ],
        ),
        trailing: const Icon(
          PhosphorIconsBold.caretRight,
          color: AppColors.textDisabled,
          size: 16,
        ),
      ),
    );
  }
}

class _ReorderableList extends StatelessWidget {
  final List<dynamic> contacts;
  final void Function(int, int) onReorder;

  const _ReorderableList({
    required this.contacts,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: contacts.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return ReorderableDragStartListener(
          key: ValueKey(contact.id),
          index: index,
          child: ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.accentBrand.withValues(alpha: 0.2),
              child: Text(
                contact.name[0].toUpperCase(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.accentBrand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              contact.name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Priority ${index + 1}',
              style: AppTextStyles.captionSmall,
            ),
          ),
        );
      },
    );
  }
}

class _AddOptionsSheet extends StatelessWidget {
  final VoidCallback onPhoneImport;
  final VoidCallback onManualAdd;

  const _AddOptionsSheet({
    required this.onPhoneImport,
    required this.onManualAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            'Add contact',
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accentBrand.withValues(alpha: 0.2),
              child: const Icon(
                PhosphorIconsBold.addressBook,
                color: AppColors.accentBrand,
              ),
            ),
            title: const Text('From phone contacts'),
            subtitle: Text(
              'Import from your address book',
              style: AppTextStyles.captionSmall,
            ),
            onTap: onPhoneImport,
          ),
          const Divider(height: 1),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accentBrand.withValues(alpha: 0.2),
              child: const Icon(
                PhosphorIconsBold.pencilSimple,
                color: AppColors.accentBrand,
              ),
            ),
            title: const Text('Add manually'),
            subtitle: Text(
              'Enter name and phone number',
              style: AppTextStyles.captionSmall,
            ),
            onTap: onManualAdd,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
