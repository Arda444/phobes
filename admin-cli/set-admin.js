/**
 * Grants Firebase Auth custom claim { admin: true } for a user.
 *
 * Usage:
 *   node set-admin.js <firebase-auth-uid>
 *   node set-admin.js --email user@example.com
 *
 * Requires ./serviceAccountKey.json (never commit this file).
 */
const admin = require('firebase-admin');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function resolveUid(argv) {
  const uidArg = argv.find((a) => !a.startsWith('-'));
  if (uidArg && !uidArg.includes('@')) {
    return uidArg;
  }
  const emailFlag = argv.indexOf('--email');
  const email =
    emailFlag >= 0 ? argv[emailFlag + 1] : uidArg?.includes('@') ? uidArg : null;
  if (!email) {
    console.error(
      'Usage: node set-admin.js <uid>\n       node set-admin.js --email user@example.com',
    );
    process.exit(1);
  }
  const user = await admin.auth().getUserByEmail(email);
  return user.uid;
}

async function makeAdmin() {
  try {
    const uid = await resolveUid(process.argv.slice(2));
    await admin.auth().setCustomUserClaims(uid, { admin: true });
    await admin.firestore().collection('users').doc(uid).set(
      { role: 'Admin' },
      { merge: true }
    );

    const updated = await admin.auth().getUser(uid);
    console.log(`✅ "${updated.email ?? uid}" is now admin.`);
    console.log(`   UID: ${updated.uid}`);
    console.log(`   Claims: ${JSON.stringify(updated.customClaims)}`);
    console.log('🔄 Sign out and sign in again in the app.');
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exitCode = 1;
  } finally {
    process.exit();
  }
}

makeAdmin();
