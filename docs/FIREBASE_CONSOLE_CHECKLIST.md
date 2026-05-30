# Firebase Console Checklist

Project: `phobes-d428d` (see `.firebaserc`)

## Before production enforce

- [ ] Deploy `firestore.rules` and `firestore.indexes.json`
- [ ] Deploy Cloud Functions (`functions/`)
- [ ] Create `config/nova` document with `groq_api_key` (admin only)
- [ ] Grant first admin: `cd admin-cli && node set-admin.js --email you@example.com`
- [ ] App Check: enforce for Firestore, Cloud Functions, Storage (web: reCAPTCHA v3 site key in build)
- [ ] Authentication: enable Email, Google, Apple (iOS)
- [ ] Hosting: deploy `build/web` with CSP headers (`firebase.json`)

## Environment variables (CI)

| Variable | Used for |
|----------|----------|
| `FIREBASE_TOKEN` | Codemagic deploy |
| `RECAPTCHA_SITE_KEY` | Web App Check + build |
| `CM_KEYSTORE*` | Android signing |

## Verify after deploy

- [ ] Budget transaction updates account balance (rules allow owner balance write)
- [ ] Survey submit increments `responseCount` (Cloud Function trigger)
- [ ] `checkAccountAccess` callable blocks banned users
- [ ] Account delete removes user via `deleteUserAccount` callable

## Monitoring

- [ ] Crashlytics enabled (mobile) — add `firebase_crashlytics` and enable in Firebase Console → Crashlytics
- [ ] FCM: default channel + notification icons on Android; APNs key on iOS
- [ ] Review Firestore index suggestions in console
- [ ] Functions logs for Nova rate limits
