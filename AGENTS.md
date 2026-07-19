# She-Secure

Personal safety app for women. Flutter, Android only, Firebase backend. Built as a local APK — not published to the Play Store.

Full product spec, screen-by-screen requirements, and acceptance criteria live in **docs/she-secure-spec.md**. Read it before starting any task — it's the source of truth, this file is just a pointer.

Build in the phases defined in Section 12 of that spec, one phase per session. Don't jump ahead to a later phase or invent scope that isn't in the spec. Anything marked 🔒 PHASE 2 in the spec is out of scope unless explicitly asked for.

Once the Flutter project is scaffolded (Phase 0 complete), re-run `/init` so this file picks up real build/lint/test commands (`flutter test`, `flutter analyze`, etc.) alongside this context.