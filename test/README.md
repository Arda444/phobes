# Phobes tests

## Flutter unit & widget tests

```bash
flutter test
```

| File | Coverage |
|------|----------|
| `models_security_test.dart` | Task/Note parsing |
| `budget_transaction_logic_test.dart` | BudgetTransaction |
| `budget_analytics_local_test.dart` | Analytics local computations |
| `survey_model_test.dart` | Survey models |
| `calendar_data_test.dart` | CalendarData + date range |
| `calendar_controller_test.dart` | Stream merge + debounce |
| `widget/auth_header_test.dart` | Auth header UI (no Firebase) |
| `widget/note_toolbar_test.dart` | Note toolbar chips |

## Firestore rules (Node.js + emulator)

Requires [Firebase CLI](https://firebase.google.com/docs/cli) and Java (Firestore emulator).

**PowerShell:**
```powershell
cd rules_test; npm install; npm test
```

**Bash / CMD:**
```bash
cd rules_test && npm install && npm test
```

Uses `@firebase/rules-unit-testing` with `firebase emulators:exec` on an **ephemeral free port** (`rules_test/run-tests.js`), so a busy fixed port does not block CI or local runs.

If tests still fail with a port error, stop a stale emulator: `Get-NetTCPConnection -LocalPort 19080 -ErrorAction SilentlyContinue | Select OwningProcess` then end that process in Task Manager, or run `firebase emulators:kill`.
