'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const java = fs.readFileSync('android-native/BiometricCredentialPlugin.java', 'utf8');
const html = fs.readFileSync('index.html', 'utf8');
const nativeSetup = fs.readFileSync('scripts/prepare-android-native.sh', 'utf8');

test('native credential vault uses Android Keystore AES-GCM and requires per-use authentication', () => {
  assert.match(java, /KeyStore\.getInstance\("AndroidKeyStore"\)/);
  assert.match(java, /Cipher\.getInstance\("AES\/GCM\/NoPadding"\)/);
  assert.match(java, /\.setUserAuthenticationRequired\(true\)/);
  assert.match(java, /\.setUserAuthenticationValidityDurationSeconds\(-1\)/);
  assert.match(java, /\.setInvalidatedByBiometricEnrollment\(true\)/);
  assert.match(java, /BIOMETRIC_STRONG/);
});

test('explicit re-enrollment recovers from an invalidated Android Keystore key', () => {
  assert.match(java, /KeyPermanentlyInvalidatedException/);
  assert.match(java, /UnrecoverableKeyException/);
  assert.match(java, /probe\.init\(Cipher\.ENCRYPT_MODE, existing\)/);
  assert.match(java, /previous ciphertext cannot be recovered with an invalidated key/);
  assert.match(java, /getSharedPreferences\(PREFS, Context\.MODE_PRIVATE\)\.edit\(\)\.clear\(\)\.apply\(\)/);
  assert.match(java, /keyStore\.deleteEntry\(KEY_ALIAS\)/);
});

test('persistent preferences contain ciphertext and IV, not plaintext credential fields', () => {
  assert.match(java, /putString\(CIPHERTEXT, Base64\.encodeToString\(encrypted/);
  assert.match(java, /putString\(IV, Base64\.encodeToString\(authenticatedCipher\.getIV\(\)/);
  assert.doesNotMatch(java, /putString\(["'](?:email|password)["']/);
  assert.match(java, /authenticatedCipher\.doFinal\(ciphertext\)/);
});

test('user can explicitly clear encrypted credentials and the Android Keystore alias', () => {
  assert.match(java, /getSharedPreferences\(PREFS, Context\.MODE_PRIVATE\)\.edit\(\)\.clear\(\)\.apply\(\)/);
  assert.match(java, /keyStore\.deleteEntry\(KEY_ALIAS\)/);
  assert.match(html, /clearBiometricCredentialsBtn/);
  assert.match(html, /vault\.clearCredentials\(\)/);
});

test('biometric enrollment is opt-in and biometric login revalidates with Supabase', () => {
  assert.match(html, /saveCredentialsForBiometric/);
  assert.match(html, /if\(\$\('saveCredentialsForBiometric'\)\?\.checked\)/);
  assert.match(html, /vault\.saveCredentials\(\{email,password\}\)/);
  assert.match(html, /vault\.getCredentials\(\)/);
  assert.match(html, /supabaseClient\.auth\.signInWithPassword\(\{email:credentials\.email,password:credentials\.password\}\)/);
});

test('Capacitor native setup registers the biometric plugin and adds AndroidX Biometric', () => {
  assert.match(nativeSetup, /registerPlugin\(BiometricCredentialPlugin\.class\)/);
  assert.match(nativeSetup, /androidx\.biometric:biometric:1\.1\.0/);
});
