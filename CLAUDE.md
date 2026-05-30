# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run on device/emulator
flutter run

# Analyze (must be clean before committing)
flutter analyze

# Regenerate l10n after editing lib/l10n/app_*.arb
flutter gen-l10n
# Or: .\scripts\gen_l10n.ps1
# Merge batch JSON into ARBs: dart run tool/merge_l10n.dart tool/l10n_batches/<batch>.json
# Status: dart run tool/arb_status.dart

# Build web (inject reCAPTCHA key at compile time)
dart run tool/generate_icon_manifest.dart
flutter build web --release --no-wasm-dry-run --dart-define=RECAPTCHA_SITE_KEY="<your_key>"
# Or: .\scripts\build_web_release.ps1 -RecaptchaSiteKey "<your_key>"
# After adding new Icons.* in lib/, re-run generate_icon_manifest before web release.

# Build Android APK
flutter build apk --release

# Deploy Cloud Functions (Nova AI proxy)
cd functions && npm install && cd .. && firebase deploy --only functions
```

Run unit tests: `flutter test` (see `test/README.md`). Firestore rules (PowerShell): `cd rules_test; npm install; npm test`.

## Architecture

**Phobes** is a Flutter productivity app (tasks, notes, calendar, budget, medication, habits, appointments, teams, AI chat) targeting Android, iOS, and Web.

### Data Layer — Facade + Specialized Services

`lib/services/firebase_service.dart` is a **thin facade** singleton that delegates to specialized sub-services. Screens can use `FirebaseService()` for convenience, but prefer the direct specialized service when only one domain is needed:

| Service | Responsibility |
|---|---|
| `AuthService` | Sign-in, sign-up, sign-out |
| `TaskService` | Task CRUD + XP |
| `NoteService` | Notes + notebooks |
| `TeamService` | Teams + projects |
| `HabitService` | Habits + streaks |
| `MedicationService` | Medications + stock |
| `AppointmentService` | Appointments + service groups |
| `BudgetTransactionService` | Transactions + atomic balance |
| `BudgetAccountService` | Accounts + assets |
| `BudgetDebtService` | Debts + limits + goals |
| `BudgetAnalyticsService` | All analytics (async + local) |
| `BudgetService` | Thin facade over the four budget sub-services |
| `NotificationService` | Local notifications + in-app (Firestore) notifications |
| `NovaApiService` | Routes LLM requests via Firebase Cloud Functions |
| `NovaContextBuilder` | Builds RAG context from all modules |
| `NovaNlpService` | Deterministic Turkish NLP (no network) |
| `NovaToolHandler` | Dispatches AI tool calls to pending-action strings |
| `HomeWidgetUpdater` | iOS/Android home widget updates |

### Nova AI

`NovaService` orchestrates the AI assistant. The Groq API key lives **only in Firebase Cloud Functions** (`functions/src/index.ts`). The client calls `novaChat` / `novaSimplePrompt` via `cloud_functions` package — the key is never exposed to the client.

### Calendar

`CalendarController` (`lib/screens/calendar/calendar_controller.dart`) combines all 6 data streams (tasks, appointments, client appointments, notes, medications, habits) into a single `Stream<CalendarData>` with 50 ms debounce. The `CalendarScreen` uses one `StreamBuilder<CalendarData>` instead of 4 nested StreamBuilders.

### State Management
No provider/riverpod/bloc. State is:
- **`StreamBuilder`** for Firestore real-time data directly in widgets
- **`StatefulWidget` + `setState`** for local UI state
- **`ValueNotifier`** for global theme/accent color (`PhobesTheme`, `lib/core/phobes_theme.dart`)
- **`ModuleSettingsService`** for enabling/disabling modules (SharedPreferences)

### Routing
Manual `Navigator.push` / `Navigator.pop` throughout — no named routes or go_router.

### Models
All in `lib/models/`. Each model has:
- `toMap()` → for Firestore writes
- `factory fromFirestore(DocumentSnapshot)` → for reads
- `copyWith(...)` → for immutable updates

### Key Architectural Patterns

**Notes module** (`lib/screens/notes/`) uses **flutter_quill** with multi-page support. Each page has its own `QuillController`, `FocusNode`, `ScrollController`. Custom embed builders live in `*_embed.dart` files and must wrap JSON parsing in try-catch — corrupt Firestore data otherwise crashes the whole note. Shared embed utilities are in `embed_utils.dart`.

**Teams module** relies on Firestore document fields (`memberIds`, `adminIds`, `ownerId` arrays) for role checks. **Client-side only** — Firestore Security Rules are the authoritative guard.

**Nova AI chat** (`lib/screens/chat/nova_chat_screen.dart`) uses Groq (llama-3.1-8b-instant) via Firebase Cloud Functions. `NovaService` builds context from user's tasks/notes/appointments before each message, with 30 s cache.

**Budget module** (`lib/screens/budget/`) is split into 5 tab files under `lib/screens/budget/tabs/`. Each tab is a standalone `StatefulWidget` — only the `BudgetScreen` scaffold holds cross-tab state (`selectedAccountId`).

**Navigation** — `MainNavigationScreen` coordinates 5 tabs. `PremiumNavBar` (`lib/widgets/home/premium_nav_bar.dart`) is the glassmorphic bottom bar. `HomeWidgetUpdater` handles iOS/Android widget refreshes.

### Theming
`PhobesTheme` (dark/light/AMOLED) and accent color are `ValueNotifier` statics. Wrap the root widget in `AnimatedBuilder` for dynamic theme switching. All text uses `GoogleFonts.outfit(...)`.

### Localization
ARB files: `lib/l10n/app_en.arb` (template, ~67 KB) and `lib/l10n/app_tr.arb` (~41 KB). Always run `flutter gen-l10n` after editing ARBs. Access via `AppLocalizations.of(context)` with null-safe fallback: `l10n?.key ?? 'English fallback'`.

`DateFormat` calls that display month names must pass locale explicitly: `DateFormat('d MMM', 'tr')`.

### Platform Notes
- Web: Firestore persistence is disabled (`kIsWeb` check in `main.dart`)
- App Check: web uses reCAPTCHA v3 (key injected via `--dart-define`), mobile uses PlayIntegrity/DeviceCheck
- `admin-cli/` contains Firebase Admin scripts — **never commit service account key files**; keep them outside the project directory or use environment variables

### Security
- Firestore rules in `firestore.rules` — all collections have explicit rules; `config/nova` is admin-only (API key server-side)
- Team `update` rule uses `diff().affectedKeys()` to prevent members from escalating to admin
- `joinCode` generation uses `Random.secure()` with 8-char alphanumeric (33^8 combinations)
