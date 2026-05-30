# Phobes

Flutter productivity app: tasks, notes, calendar, budget, medication, habits, appointments, teams, books, corkboard, and Nova AI.

**Platforms:** Android, iOS, Web

## Quick start

```bash
flutter pub get
flutter run
```

## Commands

See [CLAUDE.md](CLAUDE.md) for full contributor docs:

- `flutter analyze` — must be clean before commit
- `flutter gen-l10n` — after editing `lib/l10n/app_en.arb` or `app_tr.arb`
- Web release: `dart run tool/generate_icon_manifest.dart` then `flutter build web --release --dart-define=RECAPTCHA_SITE_KEY="<key>"`
- Functions: `cd functions && npm install && cd .. && firebase deploy --only functions`

## Docs

- [Smoke test checklist](docs/SMOKE_TEST.md)
- [Firebase Console checklist](docs/FIREBASE_CONSOLE_CHECKLIST.md)
- [Launch checklist](docs/LAUNCH_CHECKLIST.md)

## Architecture

Facade `FirebaseService` delegates to domain services. State: `StreamBuilder` + `StatefulWidget`. Routing: `go_router`. Nova AI via Cloud Functions (Groq key server-side only).
