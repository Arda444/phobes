# Phobes — Smoke Test Checklist

Run before each release. Mark each item pass/fail.

## Legal (landing / auth / account)

- [ ] Landing footer → Privacy Policy, Terms, Cookie Policy open full documents
- [ ] Auth footer → Privacy Policy link works
- [ ] Account → Privacy & Terms tiles open documents

## Auth

- [ ] Email sign-up and sign-in
- [ ] Google sign-in (web + mobile)
- [ ] Apple sign-in (iOS)
- [ ] Password reset email
- [ ] Banned user sees blocked screen
- [ ] Sign out

## Core modules

- [ ] Create / complete / delete task
- [ ] Create note, insert table, insert task card, save
- [ ] Calendar shows tasks + appointments
- [ ] Budget: add account, income/expense transaction, balance updates
- [ ] Habit: create, mark done, streak visible
- [ ] Medication: add, mark taken
- [ ] Appointment: create, view in calendar

## Teams & projects

- [ ] Create team, join by code
- [ ] Create project, add task in project
- [ ] Team kanban loads

## Nova AI

- [ ] Send message, receive reply
- [ ] Clear chat history (overflow menu)

## Admin (admin account only)

- [ ] Admin panel opens
- [ ] Dashboard stats load
- [ ] Push test sends via Cloud Function

## Web-specific

- [ ] App loads with reCAPTCHA App Check
- [ ] No console Firestore permission errors on main flows

## Build

- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all pass
- [ ] `cd rules_test; npm test` — Firestore rules pass (PowerShell; requires Firebase CLI + Java)
- [ ] `flutter build web --release` succeeds (with RECAPTCHA key)
