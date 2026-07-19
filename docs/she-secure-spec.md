# She-Secure — v1 Build Specification

**For:** OpenCode (model: `opencode/big-pickle`) + the `obra/superpowers` skills plugin
**Stack:** Flutter (Android only, v1) · Firebase
**Prepared:** 2026-07-19

---

## 0. How to use this document

- This is the single source of truth. Don't invent scope that isn't here — if something feels missing, check **Section 14 (Open Questions)** and **Section 13 (Recommendations)** before assuming.
- **Work one phase at a time.** Big Pickle's context tends to degrade well before its advertised 200k tokens — practically, reliability drops off somewhere around 50–70k tokens in a single session. Section 12 breaks the build into 6 phases sized to fit comfortably inside that budget. Run `/brainstorm` once against Sections 1–2 to confirm scope, then `/write-plan` **per phase**, then `/execute-plan`. Don't ask it to plan all 12 screens in one shot.
- Every screen in Section 8 ships with **Acceptance Criteria** — feed these straight into superpowers' TDD loop (red → green → refactor) instead of re-deriving test cases from scratch.
- Sections or bullets tagged **🔒 PHASE 2 — NOT IN V1** are explicitly out of scope. If a task seems to require one of these, stop and flag it rather than quietly building it.
- Phone numbers and platform rules below were verified by web research on **2026-07-19**. Helpline numbers can change — re-check close to your actual release date. This is flagged again in Section 9.6.
- **Distribution: local APK only, no Play Store.** This spec has been updated accordingly — see the note at the end of Section 11. A few things that would otherwise be Play Store review concerns (SMS permission declarations, target-SDK requirements, store listing/privacy-policy requirements) simply don't apply. Where a piece of guidance below is about Android's own OS behavior rather than store policy, it still applies regardless of distribution method — each note below says which is which.

---

## 1. Project Overview

- **Name:** She-Secure (v1)
- **One-line:** A personal safety companion for women that gets help to the right people fast — SOS alerts, live location, trusted contacts, discreet recording, and a believable fake call, in one calm, confident app.
- **Platform:** Android only for v1. Phone form factor only (no tablet-specific layout pass).
- **Primary user:** A woman in Sindh, Pakistan (Karachi-first) who wants a fast, reliable way to alert people she trusts, and quick access to real emergency numbers, when something feels wrong.
- **Design feeling:** dark, bold, confident — Spotify's dark editorial calm crossed with Instagram's warm, card-based immediacy. Not clinical. Not delicate or pastel by default — this is a tool she's proud to have on her home screen, not a fragile-feeling one.
- **Non-negotiable product principle:** the SOS path must work even when everything else is going wrong — no internet, GPS still acquiring a fix, a permission half-granted. It must degrade gracefully and never silently do nothing. See Section 9.1.

---

## 2. Guardrails for the coding agent

1. **Android only.** Don't add iOS platform channels, `Info.plist` entries, or CocoaPods config in v1. Keep code reasonably platform-clean (avoid Android-only assumptions baked into shared business logic) so a Phase-2 iOS port isn't a rewrite, but don't spend time building iOS support now.
2. **Recordings never leave the device.** Video/audio/photo files and their metadata stay in local app-private storage (Section 9.4). Do not wire them to Firebase Storage or any network call unless a future task explicitly asks for a "share recording" action.
3. **Every dangerous-permission request needs a rationale screen first.** Show a short in-app explanation *before* triggering the OS permission dialog (contacts, camera, mic, location, SMS). Never fire a permission prompt cold on screen load.
4. **Every destructive action needs a confirm step.** Delete contact, delete recording, factory-reset settings, log out with unsynced data, delete account (Phase 2) — all need an explicit confirmation, styled as a bottom sheet (see Section 6), not a bare `AlertDialog`.
5. **No hidden background tracking, ever.** Whenever location is being read for longer than a single fix (i.e., during an active SOS), run it inside a foreground service with a persistent, visible notification ("She-Secure: sharing your location — tap to stop"). No Play Store review means no policy forcing this, but it's still required for two real reasons: Android's own battery/Doze management will kill a plain background location read that isn't backed by a foreground service, regardless of store, and a location feature that's invisible to the person carrying the phone is a bad idea in a personal-safety app on principle — see Section 11.
6. **Commit and run tests after each screen**, not after each phase. Small, verifiable increments matter more here than usual because a wrong assumption compounds fast across 12 screens.
7. **Don't fabricate content that needs to be true.** Emergency numbers (Section 9.6) and self-defense video links (Screen 10) must come from the verified seed data or from the app owner — never invent a phone number or a YouTube URL to fill a placeholder.

---

## 3. Tech stack (decided)

| Layer | Choice | Notes |
|---|---|---|
| Framework | Flutter (latest stable 3.x) | Run `flutter --version` at project init and pin it in `README.md`. |
| Language | Dart (null-safety, latest stable) | |
| State management | Riverpod (`flutter_riverpod`) | Clean testability, good fit for superpowers' TDD workflow. |
| Routing | `go_router` | Deep-linkable routes, listed in Section 5. |
| Backend | **Firebase** — Auth, Cloud Firestore, Firebase Storage (profile photos only), Firebase Cloud Messaging (Phase 2), Firebase Crashlytics | Rationale in Section 4. |
| Local structured storage | `hive` + `hive_flutter` | Recording metadata, fake-call presets, feature toggles. Pure Dart, no native SQL layer for the agent to get wrong. |
| Simple flags | `shared_preferences` | Onboarding-seen flag, first-launch checks. |
| Location | `geolocator` | GPS fix + accuracy + last-known fallback. |
| Maps | `google_maps_flutter` | Needs a Maps SDK for Android key — see Section 14. |
| Contacts | `flutter_contacts` | Modern permission handling, actively maintained. |
| SMS (silent send) | `telephony` | Calls Android `SmsManager` directly — genuinely silent, not just "skips a dialog." Android-only, which matches our platform decision. |
| SMS (fallback) | `url_launcher` (`sms:` scheme) | Opens native compose UI pre-filled, one tap to send. |
| WhatsApp | `url_launcher` (`wa.me` deep link) + `share_plus` | See Section 9.1 for why this can't be fully silent. |
| Camera / video / photo | `camera` | |
| Audio recording | `record` | |
| Fake call UI | `flutter_callkit_incoming` | Fully local on Android — no server/push infrastructure needed. |
| Scheduling (fake call) | `flutter_local_notifications` + `android_alarm_manager_plus` | Exact-alarm scheduling that survives Doze/background kill. |
| Foreground service (active SOS) | `flutter_foreground_task` | Keeps location + send-retry alive without being killed; shows the mandatory persistent notification. |
| Permissions | `permission_handler` + `app_settings` | Latter deep-links to OS settings when a permission is permanently denied. |
| Icons | Phosphor Icons (`phosphor_flutter`) | Bolder, more distinctive than default Material icons — fits the design direction in Section 6. |
| Fonts | Google Fonts: **Sora** (display), **Inter** (body/UI), **JetBrains Mono** (coordinates, timers, timestamps) | Loaded via `google_fonts` package. |

---

## 4. Backend recommendation: Firebase

You weren't sure between Firebase and Supabase, so here's the call and the reasoning, given Android-only + a solo builder working through an AI coding agent:

- **FlutterFire has the deepest documentation footprint of any Flutter backend integration.** That matters more than usual here — Big Pickle is far less likely to hallucinate an API shape or a setup step when there's more real-world reference material to draw from.
- **Same ecosystem as Android/Play.** Auth, push notifications (Phase 2, for server-triggered fake calls), and Crashlytics all live in one console, one billing relationship, one set of docs.
- **Generous free tier (Spark plan)** comfortably covers this app's realistic usage for a long time before you'd need to think about cost.
- **Firestore's built-in offline persistence is a genuine feature fit, not just a convenience.** SOS events can write instantly to the local cache and sync when connectivity returns — no custom sync queue to build or debug.

Supabase would have been the better call if you wanted Postgres/SQL, full data portability or self-hosting, or heavy relational querying. None of that applies here, so: **Firebase.**

---

## 5. Information architecture & navigation

```
Splash
 └─ (first launch?) → Onboarding → Login/Signup → Home
 └─ (returning, authenticated) → Home
 └─ (returning, not authenticated) → Login/Signup → Home

Home (shell — hamburger left, gear icon right)
 ├─ Drawer (hamburger): Home · Trusted Contacts · Location · Recordings ·
 │                       Fake Call · Tutorial · Settings · Profile · Log out
 ├─ Gear icon (top right): → Settings directly
 ├─ Home body: SOS hero + horizontal quick-access shelf + recent SOS activity
 ├─ SOS (full-bleed screen, also reachable via the hero button on Home)
 ├─ Trusted Contacts
 ├─ Location
 ├─ Recordings
 ├─ Fake Call
 ├─ Tutorial
 ├─ Settings
 └─ Profile
```

**Routes (`go_router`):**

| Path | Screen |
|---|---|
| `/splash` | Splash |
| `/onboarding` | Onboarding |
| `/login` | Login |
| `/signup` | Signup |
| `/home` | Home shell |
| `/sos` | SOS |
| `/contacts` | Trusted Contacts |
| `/location` | Location |
| `/recordings` | Recordings |
| `/recordings/:id` | Recording detail/playback |
| `/fake-call` | Fake Call |
| `/tutorial` | Tutorial |
| `/settings` | Settings |
| `/profile` | Profile |

Note: the user explicitly specified hamburger-left + gear-right navigation and the exact feature list on Home — that structure is followed exactly as given, not redesigned. Design freedom (Section 6) is spent on color, type, motion, and card treatment, not on the navigation shape.

---

## 6. Design system

**Direction:** near-black Spotify-style base, Instagram-style warm gradient accent, used sparingly. Bold typography carries most of the personality — color is functional (it tells you what state something is in) more than decorative. Avoid the generic "AI app" tells: no cream-background-plus-terracotta, no acid-green-on-black-with-nothing-else, no dense hairline-rule broadsheet layout. This app should look like it was designed by someone who thought about *this* user, not templated.

### Color tokens

| Token | Hex | Use |
|---|---|---|
| `bg.base` | `#0B0B0F` | App background, near-black |
| `bg.elevated` | `#17171D` | Cards, sheets |
| `bg.elevated2` | `#202028` | Nested cards, input fields |
| `accent.alert` | `#FF3B5C` | SOS button, primary danger CTA, "urgent" state |
| `accent.alert.pressed` | `#E62E4D` | Pressed/active state of the above |
| `accent.brand` | `#7C5CFC` | Secondary actions, links, selected nav state, brand accent |
| `accent.safe` | `#2ED573` | Success, "you're safe," confirmations, completed states |
| `accent.warning` | `#FFB020` | Permission needed, caution, non-urgent alerts |
| `text.primary` | `#F5F5F7` | Headings, primary body text |
| `text.secondary` | `#9B9BA8` | Secondary text, captions, timestamps |
| `text.disabled` | `#55555F` | Disabled labels |
| `border.subtle` | `#2A2A33` | Card borders, dividers |
| `gradient.hero` | `linear-gradient(135deg, #FF3B5C 0%, #7C5CFC 100%)` | Used **once per screen, maximum** — SOS button glow, onboarding accents. This is the one place the design gets loud; everywhere else stays quiet and disciplined. |

Dark theme only for v1. Light theme is a 🔒 **PHASE 2** item — don't build a theme-switching abstraction beyond what Flutter's `ThemeData` gives you for free.

### Typography

| Role | Font | Weight/Size | Where |
|---|---|---|---|
| Display / H1 | Sora | Bold, 28–32 | Splash headline, onboarding titles |
| H2 | Sora | SemiBold, 22–24 | Screen titles |
| H3 / section label | Sora | SemiBold, 18 | Card section headers |
| Body | Inter | Regular, 15–16 | Paragraph text, form labels |
| Caption / meta | Inter | Medium, 12–13 | Timestamps, helper text |
| Button label | Sora | SemiBold, 16 | All buttons — gives CTAs the same confident weight Spotify gives its play/CTA buttons |
| Mono / data | JetBrains Mono | Regular/Medium, 13 | GPS coordinates, countdown timers, SOS event timestamps |

### Layout & components

- **Corner radius:** 16–20px on cards and sheets, full round (999px) on the SOS button and avatars. Nothing sharp-cornered.
- **Spacing scale:** 4 / 8 / 12 / 16 / 20 / 24 / 32 — pick from this scale, don't invent arbitrary values.
- **Cards:** flat, subtle 1px `border.subtle` border, no heavy Material drop-shadows — soft ambient shadow at most (`0 8px 24px rgba(0,0,0,0.35)`).
- **Home feature shelf:** horizontally-scrollable row of rounded feature cards (Spotify "shelf" pattern) beneath the SOS hero — Trusted Contacts, Location, Recordings, Fake Call, Tutorial.
- **Confirmations & pickers:** use bottom sheets, not centered `AlertDialog`s — feels native to both reference apps and to modern Android.
- **Signature element:** the SOS button itself. A large circular button with a slow, continuous "breathing" ripple (scale + opacity pulse on `gradient.hero`) behind it — present on Home (medium) and on the SOS screen (large, full focal point). This is the one thing the whole app should be remembered by; keep it restrained (one ripple layer, ~2.5–3s cycle, ease-in-out) rather than busy.
- **Motion elsewhere:** minimal. Screen transitions: standard Material shared-axis. Card taps: quick scale-down (0.97) on press. No entrance animations on every list item — that reads as templated, not polished.
- **Haptics:** `HapticFeedback.heavyImpact()` on SOS press, `mediumImpact()` on contact add/remove and fake-call answer.

### Voice & microcopy

- Direct, calm, empowering. Never alarmist, never infantilizing.
- Buttons say exactly what they do: "Send SOS," "Add contact," "Start recording" — not "Submit" or "Continue."
- Empty states instruct, they don't apologize: *"No trusted contacts yet — add at least one so She-Secure knows who to alert."* with a clear CTA, not "Oops, nothing here!"
- Errors state what happened and what to do, in the app's voice: *"Couldn't reach Firebase — your SOS was saved and will sync when you're back online."* not "Something went wrong."

---

## 7. Data model

### Firestore (synced, per authenticated user)

Only account/profile data, trusted contacts, and SOS event history sync to Firebase. Everything else stays local (Section 9.4).

**`users/{uid}`**

| Field | Type | Notes |
|---|---|---|
| `name` | string | required |
| `email` | string | from Firebase Auth |
| `photoUrl` | string? | Firebase Storage path, optional |
| `age` | number? | optional, see Section 11 |
| `location` | string? | optional general area, not live GPS |
| `emergencyMessage` | string | default: `"I need help. This is my location: {link}. Sent via She-Secure at {time}."` — user-editable |
| `createdAt` | timestamp | |
| `settings` | map | feature toggles, mirrors local Hive box for cross-device consistency (Phase 2 multi-device) |

**`users/{uid}/trustedContacts/{contactId}`**

| Field | Type | Notes |
|---|---|---|
| `name` | string | |
| `phone` | string | E.164 format, required |
| `relationship` | string? | e.g. "Sister," "Best friend" |
| `photoUrl` | string? | pulled from device contact or set manually |
| `notifyVia` | array | `["sms"]` and/or `["whatsapp"]` |
| `priority` | number | send order, 1 = first |
| `createdAt` | timestamp | |

Cap at **5 trusted contacts** for v1 — keeps the SOS send loop fast and the UI simple. Revisit if users ask for more.

**`users/{uid}/sosEvents/{eventId}`**

| Field | Type | Notes |
|---|---|---|
| `timestamp` | timestamp | |
| `location` | geopoint + `accuracy` (number) | |
| `channelsAttempted` | array | e.g. `["sms:silent", "sms:fallback", "whatsapp:manual"]` |
| `contactsNotified` | array of contactIds | |
| `status` | string | `sent` \| `partial` \| `failed` \| `cancelled` |
| `recordingId` | string? | link to local recording metadata if auto-record was on |

SOS history is **append-only** — see the security rules draft in the Appendix. Nothing about a past SOS event should be editable or deletable from within the app; that's an integrity property worth keeping even though it's a personal-safety app, not a legal-evidence app.

### Local (Hive boxes, device-only, never synced)

| Box | Keys | Notes |
|---|---|---|
| `recordings` | recordingId → `{type, localPath, thumbnailPath, durationSec, fileSizeBytes, createdAt}` | See Section 9.4 |
| `fakeCallPresets` | presetId → `{callerName, avatarAsset, ringtone}` | |
| `featureToggles` | key → bool | auto-record on SOS, silent-send preferred, etc. — mirrors `users/{uid}/settings` when online |
| `onboardingSeen` (SharedPreferences) | bool | |

### Bundled asset (not a database at all)

`assets/data/helplines.json` — the emergency directory (Section 9.6). Bundled with the app so it works with **zero network dependency**, which matters more for this screen than for any other.

---

## 8. Screen-by-screen specs

Each screen lists **Purpose**, **Layout**, **Key interactions**, **Data**, **Edge cases**, and **Acceptance criteria** (use these directly as your test list).

### 8.1 Splash

**Purpose:** brand moment + route decision while auth/onboarding state resolves.

**Layout:** centered logo mark + wordmark on `bg.base`, subtle `gradient.hero` glow behind the logo, small loading indicator beneath.

**Key interactions:** none — this screen is transient (target: under 1.5s once state resolves).

**Data:** reads `onboardingSeen` (SharedPreferences) and Firebase Auth's current-user state.

**Edge cases:** cold start with no network — auth state resolves from local cache, doesn't hang waiting on a network call.

**Acceptance criteria:**
- First-ever launch → routes to Onboarding.
- Onboarding seen, not authenticated → routes to Login.
- Onboarding seen, authenticated → routes to Home.
- No hang longer than ~2s even fully offline.

---

### 8.2 Onboarding

**Purpose:** first-run walkthrough of what the app does and how to use each feature.

**Layout:** full-bleed `PageView`, 4–5 slides (Splash brand recap → SOS → Trusted Contacts → Fake Call → Recordings), dot indicator, "Skip" top-right, "Next" bottom-right becoming "Get Started" on the final slide.

**Key interactions:** swipe or tap Next between slides; Skip jumps straight to Login/Signup; Get Started does the same.

**Data:** writes `onboardingSeen = true` on Skip or completion.

**Edge cases:** back gesture on first slide does nothing harmful (no crash, just no-op or exits slide view); rotating mid-onboarding doesn't lose slide position (not a huge concern phone-only, but don't reset to slide 0).

**Acceptance criteria:**
- Skip and "Get Started" both set `onboardingSeen` and never show onboarding again on relaunch.
- Each slide accurately previews the feature it names (no placeholder/lorem content).

---

### 8.3 Login / Signup

**Purpose:** Firebase Auth email/password entry point.

**Layout — Login:** email, password, "Log in" (primary button, styled with `accent.brand` — `accent.alert` is reserved for danger/SOS only, never used for routine actions like this), "Forgot password?" link, "Don't have an account? Sign up" link.

**Layout — Signup:** name, email, profile picture (choice of 6–8 bundled preset avatar illustrations, or upload from gallery/camera — uploads go to Firebase Storage at `users/{uid}/profile.jpg`), password, confirm password, age (optional, numeric), location (optional, free-text city/area — not a live GPS capture at signup), "Create account."

**Key interactions:** inline validation (email format, password match, min-length); password visibility toggle; loading state on submit disables the button and shows a spinner in place of the label (button never disappears, never both loading and tappable).

**Data:** Firebase Auth (`createUserWithEmailAndPassword`, `signInWithEmailAndPassword`); on signup, also creates the `users/{uid}` Firestore document.

**Edge cases:** email already in use → clear inline error, not a generic toast; weak password → inline strength hint before submit, not just a rejected-after-submit error; offline signup attempt → clear "check your connection" state, form data preserved so nothing is retyped; confirm-password mismatch caught client-side before hitting Firebase at all.

**Acceptance criteria:**
- Enforce password minimum 8 characters (stricter than Firebase's default 6) with a visible strength hint.
- Confirm-password mismatch blocks submission with an inline message, no network call made.
- Successful signup lands on Home, not back on Login.
- Age and location fields are genuinely optional — signup succeeds with both left blank.
- Auth errors map to specific, human messages (not raw Firebase exception text).

---

### 8.4 Home

**Purpose:** command center — everything is one tap away, SOS is unmissable.

**Layout:** `AppBar` with hamburger (left, opens Drawer) and gear icon (right, → Settings). Body, top to bottom:
1. Greeting (`"Hi, {name}"`) + small profile avatar (tap → Profile)
2. SOS hero — large circular SOS button, breathing gradient ripple, short subtext ("Press and hold isn't required — one tap alerts your trusted contacts.")
3. Horizontal quick-access shelf: Trusted Contacts · Location · Recordings · Fake Call · Tutorial (rounded cards, icon + label)
4. "Recent activity" — last 3 SOS events (if any) with timestamp + status chip; "View all" → SOS screen's history tab

**Drawer contents:** Home · Trusted Contacts · Location · Recordings · Fake Call · Tutorial · Settings · Profile · Log out (with confirm).

**Key interactions:** tapping the SOS hero navigates to the SOS screen (it does **not** fire SOS directly from Home — see 8.5 for why); shelf cards navigate to their respective screens.

**Data:** reads `users/{uid}` for name/avatar, last 3 `sosEvents`.

**Edge cases:** zero trusted contacts → SOS hero still tappable, but the SOS screen itself surfaces a blocking prompt to add a contact first (can't meaningfully send an SOS to nobody); offline → shelf and drawer still fully navigable, "Recent activity" shows cached Firestore data with a small "offline" indicator if applicable.

**Acceptance criteria:**
- Every drawer item and shelf card navigates correctly.
- Home renders and is fully navigable with zero network connectivity.
- SOS hero is reachable within one tap from a cold Home screen load.

---

### 8.5 SOS

**Purpose:** the core safety action. Full logic lives in Section 9.1 — this is the screen spec.

**Layout:** full-bleed `bg.base`, huge circular SOS button center-stage (the signature element, largest instance in the app), tab or segmented control at the top for "Send SOS" vs "History."

**Key interactions:**
- Tap SOS button → **3-second cancellable countdown** (large countdown number + a big "Cancel" button) → on countdown completion, dispatch begins automatically per Section 9.1. This is a deliberate default: fast enough to feel instant, but guards against pocket-dials on the single most consequential button in the app. Toggleable to "send immediately, no countdown" in Settings for users who want zero delay.
- While dispatching: full-screen status view — per-contact rows showing `sending → sent` / `sending → fallback needed` states live, not a spinner with no detail.
- After dispatch: confirmation state with a clear "I'm safe now" action that ends the foreground service/tracking and marks the event resolved.
- History tab: reverse-chronological list of past `sosEvents`, each expandable to show which channels/contacts were used.

**Data:** writes to `sosEvents`, reads `trustedContacts`, triggers the foreground service (Section 11).

**Edge cases:** zero trusted contacts → blocking prompt with a direct "Add a contact" CTA before the SOS button is usable; GPS fix slow/unavailable → dispatch proceeds with last-known location (clearly labeled "last known, Xm ago") rather than blocking on a fresh fix; all send channels fail (no SIM, no data) → event still logs locally as `failed`, screen surfaces the real helpline numbers (Section 9.6) as an immediate next step, not just an error toast.

**Acceptance criteria:**
- Countdown is genuinely cancellable up to the last moment before dispatch starts.
- SOS event is logged to local Hive/Firestore-offline-cache even with zero connectivity.
- "I'm safe now" reliably stops the foreground service and location updates.
- With zero trusted contacts, the send path is blocked with a clear path to fix it — never a silent no-op.

---

### 8.6 Trusted Contacts

**Purpose:** manage who gets alerted.

**Layout:** list of contact cards (avatar, name, relationship, channels), "+ Add contact" button (top or FAB), reorder handles for priority (drag to reorder, since priority determines send order).

**Key interactions:** "Add" offers "From phone contacts" (via `flutter_contacts`, with rationale screen before the permission prompt) or "Add manually" (name + phone required, relationship + photo optional); tap a contact → edit sheet; swipe or an explicit delete icon → confirm sheet → delete; per-contact toggle for SMS/WhatsApp channels.

**Data:** `users/{uid}/trustedContacts`.

**Edge cases:** duplicate phone number added twice → warn, don't silently create a duplicate; contacts permission denied → manual-entry path still fully works, denial doesn't block the feature; hitting the 5-contact cap → clear message explaining the cap, not a disabled button with no explanation.

**Acceptance criteria:**
- Can add, edit, reorder, and delete a contact end to end.
- Manual entry works fully with contacts permission denied.
- Cap of 5 is enforced with a clear, specific message.
- At least one contact with at least one enabled channel is required before SOS will allow a send (validated here and re-validated in 8.5).

---

### 8.7 Location

**Purpose:** live map, one-tap location sharing, and the offline-first emergency helpline directory.

**Layout:** map view (current location marker, accuracy circle) filling the top ~60% of the screen; "Share my location" button below the map; helpline directory below that, grouped by category (Police, Ambulance/Rescue, Fire, Women's Support, Cyber Harassment) as a scrollable list of cards, each with name, number, one-tap call button, and a short description.

**Key interactions:** "Share my location" opens the share sheet (`share_plus`) with a pre-filled message containing a static Google Maps pin link — see Section 9.3 for why this is a static link in v1, not a live-updating one; tapping a helpline card's call button launches the dialer via `url_launcher` (`tel:` scheme) with the number pre-filled, user taps to actually place the call (never auto-dial without a tap — that would be genuinely dangerous if triggered accidentally).

**Data:** `geolocator` for the live fix; `assets/data/helplines.json` for the directory (bundled, not fetched — must work offline).

**Edge cases:** location permission denied → map area shows a clear rationale + "Open Settings" CTA instead of a blank/broken map; the helpline directory still renders and is fully usable regardless of location permission or connectivity state — it must never depend on either.

**Acceptance criteria:**
- Helpline directory renders and every call button works with airplane mode on and location permission denied.
- "Share my location" produces a working, correctly-formatted map link in the shared message.
- Denied location permission degrades the map area gracefully, doesn't crash or blank-screen the rest of the screen.

---

### 8.8 Recordings

**Purpose:** discreet local capture of video, audio, or photo evidence.

**Layout:** three capture mode tabs/buttons (Video, Audio, Photo) at the top; big capture button; below, a reverse-chronological history grid/list with thumbnails, duration/size, and timestamp.

**Key interactions:** tap capture button → rationale screen (first time only) → OS permission prompt → capture UI; tap a history item → detail/playback screen with play/pause (video/audio) or full view (photo), delete (confirm sheet), and share (opens the OS share sheet so she can send a specific piece of evidence to a trusted contact, lawyer, or the police — a one-directional, explicit, user-initiated action, never automatic).

**Data:** local `hive` box `recordings`; actual media files live in `getApplicationDocumentsDirectory()` (app-private, no broad storage permission required under Android scoped storage).

**Edge cases:** storage running low → warn before capture starts, not after a failed write; camera/mic permission denied → clear rationale + settings deep-link, capture button disabled with an explanation rather than silently failing; app killed mid-recording → in-progress file is either safely finalized or cleanly discarded, never left as a corrupt partial file cluttering history.

**Acceptance criteria:**
- Can capture, view, and delete each of the three media types end to end, fully offline.
- Deleting a recording removes both the Hive entry and the underlying file (no orphaned files).
- Recordings never appear in any network request/log — verify with a network inspector during testing.

---

### 8.9 Fake Call

**Purpose:** a believable incoming call to help exit an uncomfortable situation.

**Layout:** caller name field (free text) with a row of presets ("Mom," "Boss," "Unknown") that fill the field; avatar picker (bundled preset avatars); delay selector as chips (Now, 5s, 30s, 1 min, 5 min) plus a custom time picker; two buttons — "Start Call Now" (immediate, mostly for testing/instant use) and "Schedule Call" (uses the selected delay).

**Key interactions:** "Start Call Now" or a fired schedule triggers `flutter_callkit_incoming`'s native-feeling incoming-call UI (ringtone, swipe/tap to answer or decline); answering opens an in-call screen (elapsed-time counter, mute/speaker buttons — cosmetic only, no real call) that can be ended at any time with a normal end-call tap.

**Data:** local `hive` box `fakeCallPresets`; scheduling handled by `android_alarm_manager_plus` so it fires even if the app was backgrounded or the phone was briefly locked.

**Edge cases:** phone in Do Not Disturb / silent mode → the call still visually appears (that's the whole point) even if audio is suppressed by system settings, which is expected and fine; app force-killed by the user *after* scheduling → exact-alarm scheduling should still fire (this is the reason `android_alarm_manager_plus` is specified over a plain in-app `Timer`, which would die with the app); scheduling requires `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` on Android 12+ — request this permission with its own rationale screen, distinct from the others.

**Acceptance criteria:**
- A scheduled call fires at the correct time even if the app is backgrounded (not force-quit) in between.
- Answer/decline both behave correctly and cleanly return to the app.
- Caller name and avatar shown in the fake call UI exactly match what was configured.

---

### 8.10 Tutorial

**Purpose:** ongoing reference — how to use each feature, plus self-defense video links.

**Layout:** list of expandable "how to" cards, one per feature (SOS, Trusted Contacts, Location, Recordings, Fake Call), each with a short explanation and the key steps; below that, a "Learn self-defense" section listing curated video links.

**Key interactions:** tapping a video link opens it externally (`url_launcher`) in the YouTube app or browser — v1 does **not** embed a YouTube player in-app (avoids an extra WebView dependency for a feature that doesn't need to be embedded; revisit if you later want a more polished in-app experience).

**Data:** static content bundled with the app; video links come from a curated list the app owner supplies and verifies before launch — see the note in Section 2, guardrail 7. This spec does not invent specific video URLs.

**Edge cases:** offline → the "how to" content still fully renders (it's static); tapping a video link offline shows a clear "you're offline" state rather than a silent failure.

**Acceptance criteria:**
- All "how to" content renders correctly offline.
- Every video link that is present actually opens correctly (validate against whatever list the app owner provides).

---

### 8.11 Settings

**Purpose:** feature toggles, permission management, and reset.

**Layout:** grouped list — "Safety behavior" (SOS countdown on/off, auto-record on SOS trigger, silent-send-preferred vs. always-confirm), "Permissions" (a row per permission — Location, Contacts, Camera, Microphone, SMS, Notifications — each showing current status and, if denied, a "Fix in Settings" deep link via `app_settings`), "App" (Restore factory defaults, App version, Privacy/about).

**Key interactions:** toggles apply immediately, no separate "Save" button; "Restore factory defaults" → confirm sheet clearly explaining exactly what resets (local settings and onboarding state) versus what's preserved (account, trusted contacts, SOS history, recordings) — this distinction matters and should never be ambiguous to the user.

**Data:** reads/writes the local `featureToggles` Hive box (and mirrors to `users/{uid}/settings` when online); reads live permission status via `permission_handler`.

**Edge cases:** a permission revoked by the OS *after* being granted (user goes into Android settings independently) → this screen's status row reflects that on next view, not stale cached state.

**Acceptance criteria:**
- Every toggle persists across app restart.
- Permission status rows are always accurate to actual current OS state when the screen is opened.
- "Restore factory defaults" never touches account data, trusted contacts, SOS history, or recordings — verify explicitly in tests.

---

### 8.12 Profile

**Purpose:** view and edit account info.

**Layout:** avatar (tap to change — same preset/upload picker as signup), name, email (editable, requires re-auth), age, location, "Change password" (separate flow, requires re-auth), "Log out."

**Key interactions:** editing email or password re-prompts for the current password (`reauthenticateWithCredential`) before the change is allowed — this is a Firebase Auth requirement for sensitive changes, not optional.

**Data:** `users/{uid}`, Firebase Auth profile.

**Edge cases:** re-auth failure (wrong password) → clear inline error, change not applied, no partial state; offline → profile is viewable from cache but edits are disabled with a clear "you're offline" explanation rather than silently failing on submit.

**Acceptance criteria:**
- Name/age/location edits save correctly and reflect immediately in the UI.
- Email and password changes both correctly require and validate re-authentication.
- Offline state disables editing with a clear message rather than allowing a doomed submit.

---

## 9. Feature deep-dives

### 9.1 SOS send logic — silent attempt, automatic fallback

This is the most important logic in the app. Sequence, once the countdown (Section 8.5) completes:

1. **Capture location.** Request a fresh GPS fix with a short timeout (~5s). If it doesn't resolve in time, use the last-known location instead and label it as such in the outgoing message and the logged event — don't block the whole send on a slow fix.
2. **Start local recording**, only if "auto-record on SOS" is enabled in Settings (default: on, but user-toggleable — some situations genuinely call for recording to draw more attention, not less).
3. **Build the message** from the user's `emergencyMessage` template (default: *"I need help. This is my location: {link}. Sent via She-Secure at {time}."*), substituting the real link and timestamp.
4. **For each trusted contact, in priority order, attempt SMS:**
   - If `SEND_SMS` permission is granted, send silently via the `telephony` package (direct `SmsManager` call — no compose UI, no user interaction).
   - If permission isn't granted, or the silent send throws (no SIM, radio unavailable, etc.), **fall back** to opening the native SMS compose screen (`url_launcher`, `sms:` scheme) pre-filled with the recipient and message — one tap to send. This is the "automatic fallback to one-tap" behavior you chose.
   - Record the outcome per contact (`sent` / `fallback-shown` / `failed`) — surfaced live on the SOS screen (Section 8.5), not hidden behind a spinner.
5. **WhatsApp is never silent — be upfront about this in the UI, not just in this doc.** This one isn't a store-policy thing, so sideloading doesn't change it: WhatsApp's own app simply doesn't expose any way for another app to send a message through it without the user tapping send inside WhatsApp itself. There's no consumer API, silent or otherwise. Two options, both one-tap: (a) a `wa.me` deep link pre-filled with the first-priority contact's number and the message, or (b) the native Android share sheet (`share_plus`) with the message text, which lets WhatsApp's own contact/group picker handle multiple recipients if the user has pre-made a "SOS Contacts" WhatsApp group (recommended — see Section 13). Treat WhatsApp as a deliberate secondary action the user can trigger from the SOS confirmation screen, not part of the automatic dispatch loop.
6. **Log the `sosEvent`** to Firestore (or the local offline cache if unreachable — Firestore syncs it automatically once back online).
7. **If every channel fails** (no SIM, no data, permission fully denied) — the event still logs locally, and the SOS screen immediately surfaces the real emergency numbers from Section 9.6 as the next step. Never let a total failure look like success, and never let it dead-end with nothing actionable on screen.

### 9.2 Trusted Contacts rules

Covered fully in Section 8.6. Key constraint worth restating here since it gates 9.1: **SOS must require at least one trusted contact with at least one enabled channel before it will attempt a send.** Validate this in both the Trusted Contacts screen and the SOS screen — don't rely on just one checkpoint.

### 9.3 Location sharing — v1 vs. Phase 2

**v1 (what's specified above):** a **static** Google Maps pin link (`https://www.google.com/maps?q={lat},{lng}`) generated at send time and included in the SOS message and in the "Share my location" button on the Location screen. It's accurate at the moment it's sent, but it does not update after that.

🔒 **PHASE 2 — NOT IN V1: a genuinely live-updating tracker link.** This would need a small public web page (Firebase Hosting) reading a Firestore document via an unguessable session-ID token, updated periodically while an SOS is active, with a security rule that only allows public read while a `live` flag is true and an `expiresAt` timestamp hasn't passed (auto-expire for privacy — a location link that stays live forever is a liability, not a feature). This is real, buildable work — a hosted page, a security rule, an expiry mechanism — and is deliberately out of v1 scope so the core SOS loop ships first.

### 9.4 Recording storage policy

Covered in Section 8.8. Restated because it's a product decision, not just a technical one: recordings are **evidence a woman may need to control tightly**, potentially against someone with access to her accounts or cloud backups. Keeping them local-only by default isn't a limitation to work around later — it's the safer default. If a future version adds optional cloud backup, it should be an explicit, off-by-default opt-in with its own clear explanation, not a silent sync.

### 9.5 Fake Call scheduling & CallKit

Covered in Section 8.9. One more platform note: `flutter_callkit_incoming` gives Android a very convincing, near-system incoming-call UI **entirely locally, with no backend needed**, because Android's telecom framework allows a foreground app to present this UI directly. (iOS would need real CallKit + PushKit + a push server to achieve the same effect while backgrounded — one more reason Android-only was the right call for v1 speed.)

### 9.6 Helpline directory — verified data (⚠️ re-verify before shipping)

Numbers below were confirmed via web research on 2026-07-19 from official/reputable sources (Sindh Police, Sindh Emergency Rescue Service, Sindh Government Women Development Department, Digital Rights Foundation). **Helpline numbers and hours can and do change — verify each of these again shortly before your actual release, and periodically after that.** Ship this as a bundled JSON asset (Section 7), not a hard-coded value buried in widget code, so updating it later is a one-file change. Full seed data is in the Appendix.

| Service | Number | Category | Notes |
|---|---|---|---|
| Police (Madadgar) | **15** | Police | Sindh Police emergency line |
| Rescue (ambulance/fire) | **1122** | Ambulance / Fire | Sindh Emergency Rescue Service, all Sindh divisions |
| Edhi Foundation Ambulance | **115** | Ambulance | Nationwide |
| Chhipa Ambulance | **1020** | Ambulance | Sindh |
| Fire Brigade | **16** | Fire | |
| Sindh Women Development Dept. Helpline | **1094** | Women's Support | 24/7 — harassment, domestic abuse, legal guidance. **Do not confuse with Punjab's 1043**, a different province's line. |
| Cyber Harassment Helpline (Digital Rights Foundation) | **0800-39393** | Cyber Harassment | Toll-free, roughly 9am–5pm (days vary by source — verify); legal advice, digital security support, counselling |
| Madadgaar National Helpline | **1098** | Women / Child Protection | |

---

## 10. Permissions matrix

| Permission | Why | Requested when | If denied |
|---|---|---|---|
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | SOS location, map, "share my location" | First time Location screen or SOS is opened, after a rationale screen | Location screen shows a clear rationale + Settings deep-link; SOS still attempts a send using IP-based rough location or omits location with a clear note, rather than blocking the whole feature |
| `SEND_SMS` | Silent SOS SMS (Section 9.1) | First time SOS is set up (Trusted Contacts or SOS screen), after a rationale screen | SOS automatically uses the one-tap compose fallback (Section 9.1) — the feature still works, just not silently |
| `READ_CONTACTS` | "Add from phone contacts" | Only when that specific option is tapped, after a rationale screen | Manual contact entry still fully works |
| `CAMERA` | Recordings (video/photo) | First time that capture mode is opened | Capture button disabled with explanation; other capture modes unaffected |
| `RECORD_AUDIO` | Recordings (audio, and video's audio track) | First time audio/video capture is opened | Same as above |
| `POST_NOTIFICATIONS` (Android 13+) | Foreground service notification during active SOS; fake call notifications | App start or first SOS/fake call use | Foreground service can still run but the OS may present it less prominently — explain this tradeoff in the rationale screen |
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` (Android 12+) | Reliable fake-call scheduling | First time "Schedule Call" is used | Falls back to inexact scheduling with a clear warning that timing may drift |
| Foreground service permissions (incl. location type, Android 14+) | Keeps SOS location/retry alive without being killed | Automatically declared, tied to `ACCESS_FINE_LOCATION` | N/A — required for the feature to be reliable at all |
| `VIBRATE` | Haptic feedback | Normal permission, no runtime prompt | N/A |
| `INTERNET` | Firebase sync, maps, sharing | Normal permission, no runtime prompt | N/A |

---

## 11. Security, privacy & compliance notes

**Distribution is a local APK, not the Play Store — so several store-review-specific items from the previous draft no longer apply and have been removed:** the `SEND_SMS` "core functionality" declaration, Play Console listing requirements, and target-SDK-version mandates are all a Play Store thing, not an Android OS thing, and don't come into play when you build, sign, and sideload the APK yourself. Concretely, this means silent SMS sending (Section 9.1) can be the primary path without any submission risk — request the runtime `SEND_SMS` permission once, and there's no reviewer to satisfy. What's left below is guidance that holds regardless of how the app reaches the phone, because it's either enforced by Android itself or just good practice for an app handling this kind of data:

- **Firestore security rules** (full draft in the Appendix): every document is scoped to `request.auth.uid == userId`. `sosEvents` are create/read-only from the client — no update or delete, preserving event integrity.
- **Transparency over stealth, as a product choice.** With no store enforcing this, it's entirely your call now — but it's still worth keeping: a visible, persistent notification any time location is being read beyond a single fix (Section 2, guardrail 5), and no feature that could plausibly be repurposed to track someone else without their knowledge. This is about the app being honest with *her*, not about satisfying a reviewer. The disguise-icon idea in Section 13 is about hiding the app from someone else looking at her phone, which is a different thing from hiding what the app does from her — worth keeping that distinction if you build it.
- **Data minimization.** Age and location at signup are optional and should stay that way — nothing in this spec requires them to build the SOS flow. Don't add validation that quietly makes them required.
- **Recordings** — see Section 9.4. Local-only by default is a privacy decision, not just a technical shortcut, and matters just as much for a private-use app as a published one.
- 🔒 **PHASE 2 (optional now, not required):** an explicit "Delete my account and all my data" flow. Less urgent without a public release, but still good practice if this app ever ends up on more than one device or gets shared with anyone else.

**Local build & install, practically:**
- Build a release APK with `flutter build apk --release` (found under `build/app/outputs/flutter-apk/`).
- Generate your own upload keystore (`keytool -genkey -v -keystore ~/she-secure-key.jks ...`) and configure `key.properties` / `build.gradle` to sign with it — the debug key works for quick testing, but a real release key avoids signature-mismatch errors if you ever reinstall over an existing copy with data intact.
- Install via `adb install app-release.apk`, or transfer the APK to the phone and install directly — the phone will need "Install unknown apps" allowed for whichever app you use to open it (browser, file manager, etc.).
- Because this never touches Play Protect's app review, Play Protect may still show a routine "unknown app" warning on install — that's normal for any sideloaded APK, not a sign of a real problem.

---

## 12. Build phases / roadmap

Sized so each phase fits comfortably in one `/write-plan` → `/execute-plan` cycle without blowing past Big Pickle's reliable context window.

**Phase 0 — Foundation.** Flutter project scaffold, folder structure (`lib/core`, `lib/features/<feature>/{presentation,domain,data}`, `lib/shared/theme`, `lib/shared/widgets`), theme/design tokens from Section 6 wired into `ThemeData`, `go_router` skeleton with all routes stubbed, Firebase project connected (`flutterfire configure`), Riverpod provider scaffolding. No real feature logic yet — this phase ends when the app runs, shows a themed empty shell, and routes between stub screens.

**Phase 1 — Auth & onboarding.** Splash (8.1), Onboarding (8.2), Login/Signup (8.3), basic Profile view (8.12, view-only is fine here — full edit can land in Phase 4).

**Phase 2 — Core safety loop.** Home shell (8.4), Trusted Contacts (8.6), SOS (8.5) including the full logic in 9.1, Location (8.7) including the offline helpline directory. **This phase is the real MVP** — a build that stops here is already a genuinely useful safety tool.

**Phase 3 — Evidence & deterrence.** Recordings (8.8), Fake Call (8.9).

**Phase 4 — Polish & support.** Settings (8.11), Tutorial (8.10), full Profile editing (8.12), a pass over every screen's empty/error/offline states against the Acceptance Criteria in Section 8, an accessibility pass (contrast, tap targets, screen reader labels).

**Phase 5 — 🔒 explicitly out of v1, listed here so it's never accidentally started early:**
- Live-updating location tracker link (9.3)
- Hardware-button SOS trigger (volume/power button combo)
- WhatsApp group automation beyond a manual deep link
- iOS support
- Light theme
- Optional opt-in cloud backup of recordings
- "Delete my account and data" flow
- Remote-updatable helpline directory (vs. bundled asset)
- Urdu/Sindhi localization
- Multi-device settings sync polish

---

## 13. Recommendations beyond your original spec

These aren't in your original feature list — flagged clearly as optional additions worth considering, not silently folded into the "required" spec above.

1. **A discreet/disguise mode for the app icon and name.** For a safety app specifically aimed at situations involving domestic abuse or harassment, someone with access to her phone finding an obviously-named "She-Secure" app can itself be a risk. A Settings option to switch to a neutral icon/label (e.g., looking like a notes or weather app) is a common, genuinely valuable pattern in this app category. Worth a Phase 2 slot.
2. **"Delete my account and my data."** Not in your list, but good practice (and increasingly a legal expectation) for any app holding personal safety data. See Section 11.
3. **A pre-made WhatsApp "SOS Contacts" group.** Since WhatsApp can't be triggered silently (9.1), the best real-world UX is coaching the user, during onboarding or Trusted Contacts setup, to create a WhatsApp group with her trusted contacts herself — then the app's WhatsApp button just opens that group directly, turning a multi-tap problem into a two-tap one.
4. **Evidence sharing from Recordings** (8.8 already includes this) — worth calling out again as valuable, not just incidental: being able to hand a specific recording to a trusted contact or authority in one deliberate action matters for this app's actual purpose.
5. **Urdu/Sindhi localization**, later — the primary user base is Sindh, Pakistan; English-only is a reasonable v1 scope call given everything else here, but it's the most obvious next investment after launch.

---

## 14. Open questions — only you can decide these

A handful of small decisions this document couldn't make for you:

- **App package name** (e.g., `com.yourname.shesecure`) — still needed for Firebase project setup and to build a valid APK, even without Play Console registration.
- **Google Maps API key** — needs a Google Cloud project with billing enabled and the Maps SDK for Android turned on (the free usage tier is generous, but the key itself requires that setup regardless of distribution method).
- **Exact SOS countdown length** — this doc defaults to 3 seconds; adjust if that feels too fast or too slow once you're actually testing it on a phone.
- **Whether "auto-record on SOS" defaults on or off** — this doc defaults it to on, toggleable; worth deciding deliberately since it affects both storage use and the emotional weight of pressing the button.
- **Curated self-defense video list** for the Tutorial screen (Section 8.10) — this doc deliberately does not invent URLs; you'll need to supply and verify a real list before launch.
- **Your own release keystore** — see the "Local build & install" note in Section 11 before your first release build.

---

## Appendix

### A. Firestore security rules (draft)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, update: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow delete: if false; // account deletion is a Phase 2 dedicated flow, not a raw doc delete

      match /trustedContacts/{contactId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /sosEvents/{eventId} {
        allow read, create: if request.auth != null && request.auth.uid == userId;
        allow update, delete: if false; // append-only, preserves event integrity
      }
    }
  }
}
```

### B. `assets/data/helplines.json` (seed data)

```json
{
  "lastVerified": "2026-07-19",
  "verifyBeforeShip": true,
  "categories": [
    {
      "category": "Police",
      "entries": [
        { "name": "Police Emergency (Madadgar)", "number": "15", "description": "Sindh Police emergency helpline." }
      ]
    },
    {
      "category": "Ambulance & Rescue",
      "entries": [
        { "name": "Rescue 1122", "number": "1122", "description": "Sindh Emergency Rescue Service — ambulance, fire, rescue." },
        { "name": "Edhi Foundation Ambulance", "number": "115", "description": "Nationwide free ambulance service." },
        { "name": "Chhipa Ambulance", "number": "1020", "description": "Ambulance service, Sindh." }
      ]
    },
    {
      "category": "Fire",
      "entries": [
        { "name": "Fire Brigade", "number": "16", "description": "Fire emergency services." }
      ]
    },
    {
      "category": "Women's Support",
      "entries": [
        { "name": "Sindh Women Development Department Helpline", "number": "1094", "description": "24/7 — harassment, domestic abuse, legal guidance. Sindh-specific; do not confuse with Punjab's 1043." },
        { "name": "Madadgaar National Helpline", "number": "1098", "description": "Women and child protection support." }
      ]
    },
    {
      "category": "Cyber Harassment",
      "entries": [
        { "name": "Digital Rights Foundation — Cyber Harassment Helpline", "number": "0800-39393", "description": "Toll-free. Legal advice, digital security support, counselling for online harassment. Hours vary by source (~9am–5pm) — verify." }
      ]
    }
  ]
}
```

### C. Full package list (`pubspec.yaml` reference)

```
flutter_riverpod
go_router
firebase_core
firebase_auth
cloud_firestore
firebase_storage
firebase_messaging      # wired but unused until Phase 2
firebase_crashlytics
hive
hive_flutter
shared_preferences
geolocator
google_maps_flutter
flutter_contacts
telephony
url_launcher
share_plus
camera
record
flutter_callkit_incoming
flutter_local_notifications
android_alarm_manager_plus
flutter_foreground_task
permission_handler
app_settings
phosphor_flutter
google_fonts
```

---

*End of spec. Build one phase at a time, test as you go, and keep this file as the reference — but don't be afraid to update it as real device testing surfaces things a document can't predict.*
