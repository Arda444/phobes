# Phobes — Store & Launch Checklist (Faz 5)

## Android (Play Store)

- [ ] Signed AAB from Codemagic `android-workflow`
- [ ] Play Console: internal testing track
- [ ] Privacy policy URL in store listing
- [ ] Data safety form completed
- [ ] Force-update tested via Admin → Version Management

## iOS (App Store)

- [ ] Apple Developer account + provisioning profiles
- [ ] Replace `--no-codesign` build with signed archive in CI
- [ ] App Store Connect metadata + privacy nutrition labels
- [ ] Calendar / notification usage descriptions in `Info.plist`

## Web

- [ ] `RECAPTCHA_SITE_KEY` in Codemagic (set in Environment variables — required for production App Check)
- [ ] Firebase Hosting live with CSP
- [ ] Custom domain (optional)

## Legal & ops

- [x] Privacy policy page (landing footer, auth footer, account, About)
- [x] Terms of service & cookie policy (same entry points)
- [x] Support contact email in app (`phobes_contact_screen`)
- [ ] Crashlytics + FCM production channels configured
