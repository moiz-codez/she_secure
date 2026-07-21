# She-Secure

Personal safety app for women. Flutter, Android only, Firebase backend. Built as a local APK — not published to the Play Store.

Full product spec, screen-by-screen requirements, and acceptance criteria live in **docs/she-secure-spec.md**. Read it before starting any task — it's the source of truth, this file is just a pointer.

Build in the phases defined in Section 12 of that spec, one phase per session. Don't jump ahead to a later phase or invent scope that isn't in the spec. Anything marked 🔒 PHASE 2 in the spec is out of scope unless explicitly asked for.

## Git workflow
After completing and reviewing each task, commit with a descriptive message
using conventional commit style: `type(scope): description`, e.g.
`feat(auth): add Firebase email/password signup with validation`,
`fix(splash): add onboarding + auth-state redirect logic`,
`test(router): verify redirect outcomes for splash screen`.
Push after each commit — `git push origin <current branch>`. If working
directly on `main`, push to `main`. If working in a feature branch/worktree
for the current plan, push that branch — don't assume `main`.

Before starting a new phase, tag the last known-good commit:
`git tag phase-N-complete && git push origin phase-N-complete`
(where N is the phase just finished). If a phase goes badly wrong,
this is the rollback point.

Once the Flutter project is scaffolded (Phase 0 complete), re-run `/init` so this file picks up real build/lint/test commands (`flutter test`, `flutter analyze`, etc.) alongside this context.