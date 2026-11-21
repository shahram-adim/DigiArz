(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.DigiArzAndroidBiometric = api;
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  const DEFAULT_STORAGE_KEY = 'digiarz.auth.session.v1';
  const DEFAULT_SECURE_KEY = 'digiarz.auth.session.v1';
  const MAX_SECURE_BYTES = 7168;

  function byteLength(value) {
    if (typeof TextEncoder !== 'undefined') return new TextEncoder().encode(value).length;
    return unescape(encodeURIComponent(value)).length;
  }

  function registerNativePlugins(capacitor) {
    if (!capacitor || typeof capacitor.isNativePlatform !== 'function' ||
        !capacitor.isNativePlatform() || typeof capacitor.registerPlugin !== 'function') {
      throw new Error('پل ارتباطی امن اندروید در دسترس نیست.');
    }
    return {
      biometric: capacitor.registerPlugin('NativeBiometric'),
      app: capacitor.registerPlugin('App')
    };
  }

  function createSecureStorage(options) {
    const opts = options || {};
    const plugin = opts.plugin;
    const storageKey = opts.storageKey || DEFAULT_STORAGE_KEY;
    const secureKey = opts.secureKey || DEFAULT_SECURE_KEY;
    const local = opts.localStorage || (typeof localStorage !== 'undefined' ? localStorage : null);
    const onState = typeof opts.onState === 'function' ? opts.onState : function () {};
    const maxBytes = Number.isFinite(opts.maxBytes) ? opts.maxBytes : MAX_SECURE_BYTES;

    if (!plugin || typeof plugin.isDataSaved !== 'function' ||
        typeof plugin.getSecureData !== 'function' || typeof plugin.setData !== 'function' ||
        typeof plugin.deleteData !== 'function' || typeof plugin.isAvailable !== 'function') {
      throw new Error('افزونهٔ محافظت نشست اندروید کامل بارگذاری نشده است.');
    }

    let cachedValue = null;
    let locked = false;
    let promptInProgress = false;
    let readAttempted = false;
    let readPromise = null;
    let pendingWrites = Promise.resolve();
    let preserveDelete = false;
    let secureSaved = false;
    let lastError = null;

    function enqueue(task) {
      const next = pendingWrites.then(task, task);
      pendingWrites = next.catch(function () {});
      return next;
    }

    async function hasSecureSession() {
      try {
        const result = await plugin.isDataSaved({ key: secureKey });
        secureSaved = !!result?.isSaved;
        return secureSaved;
      } catch (error) {
        lastError = error;
        return false;
      }
    }

    async function readSecure(force) {
      if (cachedValue !== null) return cachedValue;
      if (locked && !force) return null;
      if (readPromise) return readPromise;
      if (readAttempted && !force) return null;
      readAttempted = true;

      readPromise = (async function () {
        const saved = await hasSecureSession();
        if (!saved) {
          locked = false;
          return null;
        }
        promptInProgress = true;
        onState('prompting');
        try {
          const result = await plugin.getSecureData({
            key: secureKey,
            title: 'بازگشایی حساب DigiArz',
            subtitle: 'برای دسترسی به نشست امن، اثر انگشت را تأیید کنید.',
            description: 'اطلاعات ورود فقط روی همین دستگاه و به‌صورت رمزگذاری‌شده نگهداری می‌شود.',
            negativeButtonText: 'لغو'
          });
          if (!result || typeof result.value !== 'string' || !result.value) {
            throw new Error('نشست امن قابل بازیابی نیست.');
          }
          cachedValue = result.value;
          secureSaved = true;
          locked = false;
          lastError = null;
          onState('unlocked');
          return cachedValue;
        } catch (error) {
          lastError = error;
          onState('locked', error);
          // Cancellation/failure never deletes the encrypted record.
          return null;
        } finally {
          promptInProgress = false;
        }
      })();

      try {
        return await readPromise;
      } finally {
        readPromise = null;
      }
    }

    return {
      async getItem(key) {
        if (key !== storageKey) return local ? local.getItem(key) : null;
        return readSecure(false);
      },

      setItem(key, value) {
        if (key !== storageKey) {
          if (local) local.setItem(key, value);
          return Promise.resolve();
        }
        if (typeof value !== 'string') return Promise.reject(new TypeError('Supabase storage value must be a string.'));
        return enqueue(async function () {
          cachedValue = value;
          locked = false;
          readAttempted = true;
          if (byteLength(value) > maxBytes) {
            lastError = new Error('اندازه نشست از حد امن ذخیره‌سازی اندروید بیشتر است.');
            try { await plugin.deleteData({ key: secureKey }); } catch (_) {}
            secureSaved = false;
            onState('memory-only', lastError);
            return;
          }

          try {
            const availability = await plugin.isAvailable({ useFallback: false });
            if (!availability?.strongBiometryIsAvailable) {
              try { await plugin.deleteData({ key: secureKey }); } catch (_) {}
              secureSaved = false;
              onState('memory-only', new Error('اثر انگشت قوی روی دستگاه فعال نیست.'));
              return;
            }
            await plugin.setData({
              key: secureKey,
              value: value,
              accessControl: 1,
              authValidityDuration: 0,
              title: 'محافظت از نشست DigiArz',
              negativeButtonText: 'لغو'
            });
            secureSaved = true;
            lastError = null;
            onState('saved');
          } catch (error) {
            lastError = error;
            // Never fall back to plaintext. Keep this login alive in memory only.
            try { await plugin.deleteData({ key: secureKey }); } catch (_) {}
            secureSaved = false;
            onState('memory-only', error);
          }
        });
      },

      removeItem(key) {
        if (key !== storageKey) {
          if (local) local.removeItem(key);
          return Promise.resolve();
        }
        return enqueue(async function () {
          cachedValue = null;
          readAttempted = true;
          if (preserveDelete) return;
          await plugin.deleteData({ key: secureKey });
          secureSaved = false;
          locked = false;
          onState('deleted');
        });
      },

      async unlock() {
        locked = false;
        readAttempted = false;
        return readSecure(true);
      },

      lock() {
        cachedValue = null;
        locked = true;
        readAttempted = true;
        onState('locked');
      },

      async flushWrites() {
        await pendingWrites;
      },

      preserveDeletes(value) {
        preserveDelete = !!value;
      },

      hasCachedSession() {
        return cachedValue !== null;
      },

      hasSecureSession,
      isLocked() { return locked; },
      isPromptInProgress() { return promptInProgress; },
      getLastError() { return lastError; },
      getStorageKey() { return storageKey; }
    };
  }

  return {
    createSecureStorage,
    registerNativePlugins,
    DEFAULT_STORAGE_KEY,
    DEFAULT_SECURE_KEY,
    MAX_SECURE_BYTES
  };
});
