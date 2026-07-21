# Task 5: Signup form + Firebase Auth + tests

## What I implemented

**SignupScreen** — full signup form with Firebase Auth and Firestore profile creation.

### Features
- Full Name, Email, Password, Confirm Password fields with validation
- Firebase Auth `createUserWithEmailAndPassword` 
- Firestore write: `users/{uid}` with name, email, createdAt
- Loading state (button disabled + spinner)
- Error handling via SnackBar for FirebaseAuthException
- Navigate to `/home` on success
- Link to `/login` for existing accounts

### Validation rules
- Name: required
- Email: required, must contain `@`
- Password: required, minimum 6 characters
- Confirm: must match password

## Files changed

| File | Action |
|------|--------|
| `lib/features/auth/presentation/signup_screen.dart` | Rewritten (stub → full form) |
| `test/widget_test.dart` | Updated (added 3 signup tests) |

## Tests (10/10 passing)

- **Onboarding:** first page, next page, skip completes
- **Login:** fields present, empty validation, email format, password length
- **Signup:** fields present (4), empty validation (name/email/password), password mismatch

## Issues / Concerns

None. All tests pass, `flutter analyze` clean.
