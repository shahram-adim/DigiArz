(() => {
'use strict';
const KEYS = Object.freeze({
  theme: { key: 'digiArzTheme', values: ['light','dark','luxury'] },
  currency: { key: 'digiArzCurrencyMode', values: ['usd','toman','both'] },
  favorites: { key: 'digiArzFavorites', type: 'symbols' }
});
const $ = id => document.getElementById(id);
function readPreferences() {
  const result = {};
  for (const [name, spec] of Object.entries(KEYS)) {
    try {
      const raw = localStorage.getItem(spec.key);
      if (raw === null) continue;
      const value = JSON.parse(raw);
      if (spec.values && spec.values.includes(value)) result[name] = value;
      if (spec.type === 'symbols' && Array.isArray(value) && value.every(x => typeof x === 'string' && /^[A-Z0-9]{2,20}$/.test(x))) result[name] = [...new Set(value)];
    } catch (_) {}
  }
  return result;
}
function show(message, type) {
  const el = $('settingsBackupMsg');
  if (!el) return;
  el.textContent = message;
  el.className = 'notice ' + (type || 'ok');
  el.classList.remove('hidden');
}
function exportBackup() {
  const payload = { format: 'DigiArz-settings', version: 1, createdAt: new Date().toISOString(), preferences: readPreferences() };
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = 'digiarz-settings-backup.json';
  document.body.appendChild(a); a.click(); a.remove(); URL.revokeObjectURL(url);
  show('نسخه پشتیبان تنظیمات این دستگاه ساخته شد. اطلاعات ورود، رمز عبور و کیف پول در فایل قرار نمی‌گیرند.', 'ok');
}
function validate(payload) {
  if (!payload || payload.format !== 'DigiArz-settings' || payload.version !== 1 || !payload.preferences || typeof payload.preferences !== 'object' || Array.isArray(payload.preferences)) throw new Error('ساختار فایل پشتیبان معتبر نیست.');
  const p = payload.preferences, clean = {};
  if (Object.hasOwn(p, 'theme')) { if (!KEYS.theme.values.includes(p.theme)) throw new Error('مقدار پوسته در فایل معتبر نیست.'); clean.theme = p.theme; }
  if (Object.hasOwn(p, 'currency')) { if (!KEYS.currency.values.includes(p.currency)) throw new Error('واحد نمایش در فایل معتبر نیست.'); clean.currency = p.currency; }
  if (Object.hasOwn(p, 'favorites')) {
    if (!Array.isArray(p.favorites) || p.favorites.length > 500 || !p.favorites.every(x => typeof x === 'string' && /^[A-Z0-9]{2,20}$/.test(x))) throw new Error('فهرست علاقه‌مندی‌ها در فایل معتبر نیست.');
    clean.favorites = [...new Set(p.favorites)];
  }
  if (!Object.keys(clean).length) throw new Error('فایل پشتیبان تنظیم قابل بازیابی ندارد.');
  return clean;
}
async function importBackup(file) {
  if (!file || file.size > 256 * 1024) throw new Error('فایل انتخابی خالی یا بزرگ‌تر از حد مجاز است.');
  const payload = JSON.parse(await file.text());
  const prefs = validate(payload);
  if (!window.confirm('تنظیمات موجود روی این دستگاه با موارد موجود در فایل جایگزین شوند؟')) return;
  if (prefs.theme) localStorage.setItem(KEYS.theme.key, JSON.stringify(prefs.theme));
  if (prefs.currency) localStorage.setItem(KEYS.currency.key, JSON.stringify(prefs.currency));
  if (prefs.favorites) localStorage.setItem(KEYS.favorites.key, JSON.stringify(prefs.favorites));
  show('تنظیمات بازیابی شد. صفحه برای اعمال کامل تغییرات تازه‌سازی می‌شود.', 'ok');
  setTimeout(() => location.reload(), 700);
}
document.addEventListener('DOMContentLoaded', () => {
  $('settingsBackupExport')?.addEventListener('click', exportBackup);
  $('settingsBackupImport')?.addEventListener('click', () => $('settingsBackupFile')?.click());
  $('settingsBackupFile')?.addEventListener('change', async event => {
    try { await importBackup(event.target.files?.[0]); }
    catch (error) { show(error.message || 'بازیابی فایل انجام نشد.', 'err'); }
    finally { event.target.value = ''; }
  });
});
if (typeof module !== 'undefined' && module.exports) module.exports = { readPreferences, validate };
})();