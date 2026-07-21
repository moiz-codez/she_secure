# Phase 2a — Home Shell + Trusted Contacts

**Spec sections:** 8.4 (Home), 8.6 (Trusted Contacts), 7 (Data model), 5 (Navigation), 6 (Design), 9.2 (Trusted Contacts rules)

**Scope:** Home shell with navigation + Trusted Contacts CRUD. NOT in scope: SOS (8.5), Location (8.7) — those are separate rounds.

**Acceptance criteria (from spec):**
- Home: Every drawer item and shelf card navigates correctly
- Home: Renders and is fully navigable with zero network connectivity
- Home: SOS hero is reachable within one tap from a cold Home screen load
- Contacts: Can add, edit, reorder, and delete a contact end to end
- Contacts: Manual entry works fully with contacts permission denied
- Contacts: Cap of 5 is enforced with a clear, specific message
- Contacts: At least one contact with at least one enabled channel is required before SOS will allow a send

---

## Task 1: Add dependencies

**Packages to add (pubspec.yaml):**
- `flutter_contacts: ^1.1.0` — phone contacts picker for "Add from contacts"
- `permission_handler: ^11.3.0` — contacts permission rationale before OS prompt
- `share_plus: ^10.0.0` — needed for sharing location later, but also useful for contact sharing
- `url_launcher: ^6.3.0` — needed for phone dialer, also useful for sharing

**Packages already present:** cloud_firestore, shared_preferences, firebase_auth, go_router, flutter_riverpod, phosphor_flutter, google_fonts

Run `flutter pub get`.

---

## Task 2: Data layer — Contacts repository

**File:** `lib/features/contacts/data/contacts_repository.dart`

Firestore CRUD for `users/{uid}/trustedContacts/{contactId}`:

```dart
// Model
class TrustedContact {
  final String id;
  final String name;
  final String phone; // E.164 format
  final String? relationship;
  final String? photoUrl;
  final List<String> notifyVia; // ["sms"] and/or ["whatsapp"]
  final int priority; // 1 = first, determines send order
  final DateTime createdAt;
}

// Repository
class ContactsRepository {
  final String uid;
  
  Stream<List<TrustedContact>> watchContacts(); // ordered by priority
  Future<void> addContact(TrustedContact contact);
  Future<void> updateContact(TrustedContact contact);
  Future<void> deleteContact(String contactId);
  Future<void> reorderContacts(List<String> orderedIds);
  Future<bool> hasValidContact(); // at least one contact with one enabled channel
}
```

**Firestore path:** `users/{uid}/trustedContacts`
**Ordering:** by `priority` ascending (1 = first to be notified)
**Cap:** 5 contacts max — enforced in repository, not just UI

**Test:** Unit test for repository methods (mock Firestore).

---

## Task 3: Data layer — User profile + recent SOS events

**File:** `lib/features/home/data/home_repository.dart`

```dart
class HomeRepository {
  final String uid;
  
  Stream<Map<String, dynamic>?> watchUserProfile(); // users/{uid}
  Stream<List<Map<String, dynamic>>> watchRecentSosEvents(); // last 3, ordered by timestamp desc
}
```

**Firestore paths:**
- `users/{uid}` — for greeting + avatar
- `users/{uid}/sosEvents` — ordered by `timestamp` desc, limited to 3

**Test:** Unit test for repository methods.

---

## Task 4: Home shell — UI skeleton

**File:** `lib/features/home/presentation/home_screen.dart` (replace stub)

**Layout per spec 8.4:**
1. AppBar: hamburger (left, opens Drawer) + gear icon (right, → Settings)
2. Greeting: "Hi, {name}" + small profile avatar (tap → Profile)
3. SOS hero: large circular button with breathing gradient ripple animation
4. Horizontal quick-access shelf: Trusted Contacts · Location · Recordings · Fake Call · Tutorial
5. "Recent activity": last 3 SOS events (if any) with timestamp + status chip; "View all" → SOS screen

**Drawer contents (spec 8.4):**
Home · Trusted Contacts · Location · Recordings · Fake Call · Tutorial · Settings · Profile · Log out (with confirm)

**SOS hero animation:**
- Continuous "breathing" ripple: scale + opacity pulse on `gradient.hero` gradient
- One ripple layer, ~2.5–3s cycle, ease-in-out
- Tap → navigates to SOS screen (does NOT fire SOS directly)

**Quick-access shelf:**
- Horizontally-scrollable row of rounded cards (Spotify "shelf" pattern)
- Each card: icon + label, tap → navigates to respective screen
- Items: Trusted Contacts, Location, Recordings, Fake Call, Tutorial

**Recent activity:**
- If no events: show placeholder "No recent activity yet"
- If events exist: last 3 with timestamp + status chip (sent/partial/failed/cancelled)
- "View all" link → navigates to SOS screen's history tab (stub for now)

**Edge cases (spec 8.4):**
- Zero trusted contacts → SOS hero still tappable (SOS screen handles the blocking prompt)
- Offline → shelf and drawer still fully navigable, recent activity shows cached Firestore data

**Test:** Widget tests for Home screen.

---

## Task 5: Home shell — Navigation wiring

**Wire drawer navigation:**
- Home → `/home`
- Trusted Contacts → `/contacts`
- Location → `/location`
- Recordings → `/recordings`
- Fake Call → `/fake-call`
- Tutorial → `/tutorial`
- Settings → `/settings`
- Profile → `/profile`
- Log out → confirm sheet → sign out → `/login`

**Wire shelf navigation:**
- Trusted Contacts → `/contacts`
- Location → `/location`
- Recordings → `/recordings`
- Fake Call → `/fake-call`
- Tutorial → `/tutorial`

**Wire AppBar navigation:**
- Hamburger → opens Drawer
- Gear icon → `/settings`
- Profile avatar → `/profile`

**Test:** Widget tests for navigation.

---

## Task 6: Trusted Contacts — List UI

**File:** `lib/features/contacts/presentation/contacts_screen.dart` (replace stub)

**Layout per spec 8.6:**
- AppBar: "Trusted Contacts" title
- List of contact cards (avatar, name, relationship, channels)
- "+ Add contact" button (FAB)
- Reorder handles for priority (drag to reorder)

**Contact card:**
- Avatar (first letter of name, or photo if available)
- Name (bold)
- Relationship (if set)
- Channel indicators: SMS icon + WhatsApp icon (enabled/disabled)
- Reorder handle (drag icon on right)
- Tap → edit sheet
- Swipe right → delete icon → confirm sheet → delete

**Empty state:**
"No trusted contacts yet — add at least one so She-Secure knows who to alert." with a clear CTA button.

**Test:** Widget tests for contacts list.

---

## Task 7: Trusted Contacts — Add/Edit/Delete/Reorder

**Add contact flow:**
1. FAB tap → bottom sheet with two options:
   - "From phone contacts" → rationale screen → OS permission prompt → phone contacts picker
   - "Add manually" → form sheet (name + phone required, relationship + photo optional)
2. Save → writes to Firestore, appears in list

**Edit contact flow:**
1. Tap contact → bottom sheet with same fields as add, pre-filled
2. Save → updates Firestore

**Delete contact flow:**
1. Swipe right → delete icon
2. Tap delete → confirm bottom sheet: "Remove {name} from your trusted contacts? They won't be alerted during an SOS."
3. Confirm → deletes from Firestore

**Reorder flow:**
1. Long-press or drag handle → reorder mode
2. Drag to new position
3. Release → updates priority field for all contacts

**Rationale screen (before contacts permission):**
"Why does She-Secure need your contacts? To let you quickly add trusted contacts from your phone. She-Secure only reads names and phone numbers — it never shares or uploads your contact list." with "Allow" and "Skip — add manually" buttons.

**Edge cases (spec 8.6):**
- Duplicate phone number → warn "This number is already in your contacts"
- Contacts permission denied → manual entry still works
- 5-contact cap → "You've reached the maximum of 5 trusted contacts. Remove one to add another." (not a disabled button)

**Test:** Widget tests for add/edit/delete/reorder flows.

---

## Task 8: End-to-end verification

1. Run `flutter test` — all tests pass
2. Run `flutter analyze` — zero issues
3. Verify all acceptance criteria from spec
4. Verify navigation from Home to all screens
5. Verify contacts CRUD works with Firestore (mock)
6. Verify reorder updates priority correctly
7. Verify 5-contact cap is enforced
8. Verify duplicate phone number warning
9. Verify manual entry works without contacts permission

---

## Files to create/modify

| File | Action |
|------|--------|
| `pubspec.yaml` | Add flutter_contacts, permission_handler, share_plus, url_launcher |
| `lib/features/contacts/data/contacts_repository.dart` | Create |
| `lib/features/contacts/data/trusted_contact.dart` | Create (model) |
| `lib/features/home/data/home_repository.dart` | Create |
| `lib/features/home/presentation/home_screen.dart` | Replace stub |
| `lib/features/contacts/presentation/contacts_screen.dart` | Replace stub |
| `lib/features/contacts/presentation/add_contact_sheet.dart` | Create |
| `lib/features/contacts/presentation/edit_contact_sheet.dart` | Create |
| `lib/features/contacts/presentation/confirm_delete_sheet.dart` | Create |
| `lib/features/contacts/presentation/rationale_screen.dart` | Create |
| `lib/features/home/presentation/widgets/sos_hero_button.dart` | Create |
| `lib/features/home/presentation/widgets/quick_access_shelf.dart` | Create |
| `lib/features/home/presentation/widgets/recent_activity.dart` | Create |
| `lib/features/home/presentation/widgets/app_drawer.dart` | Create |
| `test/home_test.dart` | Create |
| `test/contacts_test.dart` | Create |
| `test/contacts_repository_test.dart` | Create |
| `test/home_repository_test.dart` | Create |

---

## Commit strategy (per spec guardrail 6: commit after each screen)

1. `feat(deps): add flutter_contacts, permission_handler, share_plus, url_launcher`
2. `feat(contacts): add Firestore repository and trusted contact model`
3. `feat(home): add user profile and recent SOS events repository`
4. `feat(home): build home shell with greeting, SOS hero, shelf, recent activity, drawer`
5. `feat(contacts): build contacts list with empty state and reorder`
6. `feat(contacts): add contact flow with manual entry and phone contacts picker`
7. `feat(contacts): edit, delete, and channel toggle flows`
8. `test: add home and contacts widget and repository tests`
9. `verify: Phase 2a acceptance criteria all pass`
