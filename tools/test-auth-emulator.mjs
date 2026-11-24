import assert from 'node:assert/strict';

// Local emulator only; never accept a production URL or emit credentials/tokens.
const host = process.env.FIREBASE_AUTH_EMULATOR_HOST;
assert.ok(host && /^(127\.0\.0\.1|localhost):\d+$/.test(host), 'Start this script with Firebase emulators:exec --only auth.');
const endpoint = `http://${host}/identitytoolkit.googleapis.com/v1/accounts:`;
async function auth(method, data) {
  const response = await fetch(`${endpoint}${method}?key=local-test-key`, {
    method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data),
  });
  return {ok: response.ok, body: await response.json()};
}
const email = `signup-${Date.now()}@example.com`;
const password = 'LocalTest123!';
const registered = await auth('signUp', {email, password, returnSecureToken: true});
assert.equal(registered.ok, true, 'Signup failed');
assert.ok(registered.body.localId);
const duplicate = await auth('signUp', {email, password, returnSecureToken: true});
assert.equal(duplicate.ok, false);
assert.equal(duplicate.body.error.message, 'EMAIL_EXISTS');
const wrong = await auth('signInWithPassword', {email, password: 'WrongPassword!', returnSecureToken: true});
assert.equal(wrong.ok, false);
const signedIn = await auth('signInWithPassword', {email, password, returnSecureToken: true});
assert.equal(signedIn.ok, true);
assert.equal(signedIn.body.localId, registered.body.localId);
const weak = await auth('signUp', {email: `weak-${Date.now()}@example.com`, password: '123', returnSecureToken: true});
assert.equal(weak.ok, false);
console.log('PASS: Firebase Auth emulator signup, duplicate email, wrong password, login, weak password.');
