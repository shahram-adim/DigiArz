package com.digiarz.app;

import android.content.Context;
import android.content.SharedPreferences;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentActivity;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import org.json.JSONObject;

@CapacitorPlugin(name = "BiometricCredential")
public class BiometricCredentialPlugin extends Plugin {
    private static final String KEY_ALIAS = "digiarz.biometric.credentials.v1";
    private static final String PREFS = "digiarz_biometric_vault";
    private static final String CIPHERTEXT = "ciphertext";
    private static final String IV = "iv";

    @PluginMethod
    public void isAvailable(PluginCall call) {
        boolean available = BiometricManager.from(getContext()).canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG
        ) == BiometricManager.BIOMETRIC_SUCCESS;
        JSObject result = new JSObject();
        result.put("available", available);
        result.put("hasCredentials", hasSavedCredentials());
        call.resolve(result);
    }

    @PluginMethod
    public void hasCredentials(PluginCall call) {
        JSObject result = new JSObject();
        result.put("hasCredentials", hasSavedCredentials());
        call.resolve(result);
    }

    @PluginMethod
    public void saveCredentials(PluginCall call) {
        String email = call.getString("email");
        String password = call.getString("password");
        if (email == null || email.trim().isEmpty() || password == null || password.isEmpty()) {
            call.reject("ایمیل و رمز عبور معتبر لازم است.", "INVALID_CREDENTIALS");
            return;
        }
        try {
            ensureKey();
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, getSecretKey());
            authenticate(call, cipher, true, email.trim(), password, null, null);
        } catch (Exception error) {
            call.reject("راه‌اندازی مخزن امن ناموفق بود: " + error.getMessage(), "VAULT_INIT_FAILED");
        }
    }

    @PluginMethod
    public void getCredentials(PluginCall call) {
        SharedPreferences prefs = getContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        String encoded = prefs.getString(CIPHERTEXT, null);
        String encodedIv = prefs.getString(IV, null);
        if (encoded == null || encodedIv == null) {
            call.reject("اطلاعات ورود ذخیره‌شده وجود ندارد.", "NO_SAVED_CREDENTIALS");
            return;
        }
        try {
            byte[] iv = Base64.decode(encodedIv, Base64.NO_WRAP);
            byte[] ciphertext = Base64.decode(encoded, Base64.NO_WRAP);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, getSecretKey(), new GCMParameterSpec(128, iv));
            authenticate(call, cipher, false, null, null, ciphertext, null);
        } catch (Exception error) {
            call.reject("بازیابی مخزن امن ممکن نشد؛ ممکن است اثر انگشت دستگاه تغییر کرده باشد.", "VAULT_DECRYPT_FAILED");
        }
    }

    @PluginMethod
    public void clearCredentials(PluginCall call) {
        getContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply();
        try {
            KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
            keyStore.load(null);
            if (keyStore.containsAlias(KEY_ALIAS)) keyStore.deleteEntry(KEY_ALIAS);
        } catch (Exception ignored) { }
        call.resolve();
    }

    private boolean hasSavedCredentials() {
        SharedPreferences prefs = getContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        return prefs.contains(CIPHERTEXT) && prefs.contains(IV);
    }

    private void ensureKey() throws Exception {
        KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
        keyStore.load(null);
        if (keyStore.containsAlias(KEY_ALIAS)) {
            try {
                SecretKey existing = (SecretKey) keyStore.getKey(KEY_ALIAS, null);
                if (existing != null) {
                    Cipher probe = Cipher.getInstance("AES/GCM/NoPadding");
                    probe.init(Cipher.ENCRYPT_MODE, existing);
                    return;
                }
            } catch (
                android.security.keystore.KeyPermanentlyInvalidatedException |
                java.security.UnrecoverableKeyException invalidated
            ) {
                // A biometric enrollment change can permanently invalidate this key.
                // This path runs only when the user explicitly opts to save credentials again.
            }
            // The previous ciphertext cannot be recovered with an invalidated key.
            getContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply();
            keyStore.deleteEntry(KEY_ALIAS);
        }
        KeyGenerator generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
        KeyGenParameterSpec spec = new KeyGenParameterSpec.Builder(
            KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setRandomizedEncryptionRequired(true)
            .setUserAuthenticationRequired(true)
            .setInvalidatedByBiometricEnrollment(true)
            .setUserAuthenticationValidityDurationSeconds(-1)
            .build();
        generator.init(spec);
        generator.generateKey();
    }

    private SecretKey getSecretKey() throws Exception {
        KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
        keyStore.load(null);
        return (SecretKey) keyStore.getKey(KEY_ALIAS, null);
    }

    private void authenticate(
        PluginCall call, Cipher cipher, boolean encrypt, String email, String password,
        byte[] ciphertext, String unused
    ) {
        if (!(getActivity() instanceof FragmentActivity)) {
            call.reject("محیط اندروید برای احراز هویت بیومتریک آماده نیست.", "BIOMETRIC_UNAVAILABLE");
            return;
        }
        BiometricManager manager = BiometricManager.from(getContext());
        if (manager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            != BiometricManager.BIOMETRIC_SUCCESS) {
            call.reject("اثر انگشت یا بیومتریک قوی روی این دستگاه آماده نیست.", "BIOMETRIC_UNAVAILABLE");
            return;
        }
        BiometricPrompt.PromptInfo promptInfo = new BiometricPrompt.PromptInfo.Builder()
            .setTitle(encrypt ? "ذخیره امن اطلاعات DigiArz" : "ورود امن به DigiArz")
            .setSubtitle(encrypt ? "برای رمزنگاری اطلاعات ورود، اثر انگشت را تأیید کنید." : "برای بازیابی اطلاعات ورود، اثر انگشت را تأیید کنید.")
            .setNegativeButtonText("لغو")
            .setConfirmationRequired(false)
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .build();

        BiometricPrompt prompt = new BiometricPrompt(
            (FragmentActivity) getActivity(),
            ContextCompat.getMainExecutor(getContext()),
            new BiometricPrompt.AuthenticationCallback() {
                @Override
                public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult result) {
                    try {
                        Cipher authenticatedCipher = result.getCryptoObject().getCipher();
                        if (encrypt) {
                            JSONObject json = new JSONObject();
                            json.put("email", email);
                            json.put("password", password);
                            byte[] encrypted = authenticatedCipher.doFinal(json.toString().getBytes(StandardCharsets.UTF_8));
                            SharedPreferences prefs = getContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
                            prefs.edit()
                                .putString(IV, Base64.encodeToString(authenticatedCipher.getIV(), Base64.NO_WRAP))
                                .putString(CIPHERTEXT, Base64.encodeToString(encrypted, Base64.NO_WRAP))
                                .apply();
                            JSObject response = new JSObject();
                            response.put("saved", true);
                            call.resolve(response);
                        } else {
                            byte[] plain = authenticatedCipher.doFinal(ciphertext);
                            JSONObject json = new JSONObject(new String(plain, StandardCharsets.UTF_8));
                            JSObject response = new JSObject();
                            response.put("email", json.getString("email"));
                            response.put("password", json.getString("password"));
                            call.resolve(response);
                        }
                    } catch (Exception error) {
                        call.reject("عملیات مخزن امن ناموفق بود: " + error.getMessage(), "VAULT_OPERATION_FAILED");
                    }
                }

                @Override
                public void onAuthenticationError(int errorCode, CharSequence errString) {
                    call.reject(errString == null ? "احراز هویت بیومتریک لغو شد." : errString.toString(), "BIOMETRIC_AUTH_FAILED");
                }

                @Override
                public void onAuthenticationFailed() {
                    // Keep the system prompt open so the user can retry.
                }
            }
        );
        prompt.authenticate(promptInfo, new BiometricPrompt.CryptoObject(cipher));
    }
}
