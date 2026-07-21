# Phase 1 — Auth & Onboarding Design

## New dependencies

- `shared_preferences` — for `onboardingSeen` flag
- `cloud_firestore` — for `users/{uid}` profile document

## 1. Splash (8.1) — real redirect logic

**File:** `lib/features/splash/presentation/splash_screen.dart`

StatefulWidget that resolves redirect destination in `initState`:

1. Show centered logo + gradient glow + loading indicator on `bg.base`
2. In `initState`, call `_resolveDestination()`:
   - Read `onboardingSeen` from `SharedPreferences`
   - If `false` → navigate to `/onboarding`
   - If `true`, check `FirebaseAuth.currentUser`
   - If `null` → navigate to `/login`
   - If not `null` → navigate to `/home`
3. Firebase Auth resolves from local cache — no network hang
4. Must complete within ~2s even fully offline

**Key detail:** await Firebase initialization before reading auth state. The `main.dart` already calls `Firebase.initializeApp()` before `runApp()`, so auth state is safe to read by the time `initState` runs.

## 2. Onboarding (8.2) — 5-slide PageView

**File:** `lib/features/onboarding/presentation/onboarding_screen.dart`

Full-bleed PageView with 5 slides:
1. Brand recap — "Welcome to She-Secure" + app icon
2. SOS — "One tap to alert your trusted contacts"
3. Trusted Contacts — "Add the people who matter most"
4. Fake Call — "A believable exit from uncomfortable situations"
5. Recordings — "Discreet evidence capture, stored only on your device"

Each slide: illustration area (gradient background with icon), title (Sora SemiBold), description (Inter Regular).

**Controls:**
- Dot indicator centered at bottom
- "Skip" text button top-right (visible on all slides except last)
- "Next" text button bottom-right (slides 1-4)
- "Get Started" elevated button bottom-right (slide 5)

**Behavior:**
- Skip → set `onboardingSeen = true` → navigate to `/login`
- Get Started → set `onboardingSeen = true` → navigate to `/login`
- Back gesture on first slide → no-op (don't exit)

## 3. Login/Signup (8.3) — Firebase Auth

### Login screen

**File:** `lib/features/auth/presentation/login_screen.dart`

Layout:
- App logo/icon at top
- Email `TextField` (keyboard type: email, autocorrect: false)
- Password `TextField` (obscure text, visibility toggle icon)
- "Log in" `ElevatedButton` (accent.brand color, loading state: spinner replaces label)
- "Forgot password?" `TextButton` (placeholder — not implemented in Phase 1, just a no-op link)
- "Don't have an account? Sign up" `TextButton` → navigates to `/signup`

**Validation:**
- Email: non-empty, basic format check
- Password: non-empty

**Firebase:**
- `FirebaseAuth.instance.signInWithEmailAndPassword(email: ..., password: ...)`
- On success → navigate to `/home`
- On error → map to human messages:
  - `user-not-found` → "No account found with this email"
  - `wrong-password` → "Incorrect password"
  - `invalid-email` → "Please enter a valid email"
  - `user-disabled` → "This account has been disabled"
  - `network-request-failed` → "Check your connection and try again"
  - Default → "Login failed. Please try again."

### Signup screen

**File:** `lib/features/auth/presentation/signup_screen.dart`

Layout:
- Name `TextField`
- Email `TextField`
- Password `TextField` (obscure, visibility toggle)
- Confirm Password `TextField` (obscure, visibility toggle)
- Age `TextField` (optional, number keyboard)
- Location `TextField` (optional)
- "Create account" `ElevatedButton` (accent.brand, loading state)

**Validation:**
- Name: non-empty
- Email: non-empty, basic format check
- Password: min 8 characters
- Confirm password: must match password (client-side, no network call)
- Age/location: genuinely optional

**Firebase:**
- `FirebaseAuth.instance.createUserWithEmailAndPassword(email: ..., password: ...)`
- On success → create `users/{uid}` Firestore doc with `{name, email, createdAt}`
- On success → navigate to `/home`
- On error → map to human messages:
  - `email-already-in-use` → "An account already exists with this email"
  - `weak-password` → "Password must be at least 8 characters"
  - `invalid-email` → "Please enter a valid email"
  - `network-request-failed` → "Check your connection and try again"
  - Default → "Signup failed. Please try again."

## 4. Profile (8.12, view-only)

**File:** `lib/features/profile/presentation/profile_screen.dart`

Layout:
- Avatar placeholder (circular, icon)
- Name (read-only Text)
- Email (read-only Text)
- Age (read-only Text, show "Not set" if null)
- Location (read-only Text, show "Not set" if null)
- "Log out" button → confirm bottom sheet → `FirebaseAuth.instance.signOut()` → navigate to `/login`

**Data:** Read from `users/{uid}` Firestore document via a Riverpod provider.

## Router changes

Update `app_router.dart`:
- Add redirect logic: if user is on splash, let them through; otherwise, no auth guard needed yet (Phase 1 doesn't have protected routes beyond splash)
- Keep all 14 routes

## Testing approach

### Splash tests (3 tests)
1. First launch (onboardingSeen=false) → verify navigates to `/onboarding`
2. Seen, not authenticated → verify navigates to `/login`
3. Seen, authenticated → verify navigates to `/home`

### Onboarding tests (2 tests)
1. Tap Skip → verify `onboardingSeen` set and navigates to `/login`
2. Tap through to Get Started → verify `onboardingSeen` set and navigates to `/login`

### Login tests (3 tests)
1. Empty email → verify error message
2. Short password → verify error message
3. Successful login → verify navigates to `/home`

### Signup tests (3 tests)
1. Password mismatch → verify error message, no network call
2. Short password → verify error message
3. Successful signup → verify navigates to `/home`
