# Phobes Admin CLI

Firebase Admin SDK scripts for managing the Phobes backend.

## ⚠️ Security Warning

**NEVER commit `serviceAccountKey.json` or any `*serviceAccountKey*.json` files.**

Service account keys grant full admin access to the Firebase project. If a key is accidentally committed:
1. Revoke it immediately: Firebase Console → Project Settings → Service Accounts
2. Generate a new key
3. Remove from Git history with `git filter-repo` (or an equivalent history-rewrite tool)

## Setup

1. Download your service account key from Firebase Console:
   - Project Settings → Service Accounts → Generate new private key
2. Save it as `serviceAccountKey.json` in this directory (it is gitignored)
3. Install dependencies: `npm install`

## Usage

```bash
# Grant admin claim to a user
node set-admin.js <user-uid>
```

## Secure Key Storage Alternatives

Instead of storing the key as a file, consider:
- **Environment variable**: `GOOGLE_APPLICATION_CREDENTIALS=/path/outside/project/key.json`
- **Secret Manager**: Use Google Cloud Secret Manager
- **CI/CD**: Inject key as a protected CI/CD variable, never store locally
