(() => {
'use strict';
const KEY = 'digiArzLowPowerMode';
let ticks = 0;
function enabled() { try { return localStorage.getItem(KEY) === 'true'; } catch (_) { return false; } }
function set(value) { try { localStorage.setItem(KEY, value ? 'true' : 'false'); } catch (_) {} ticks = 0; }
window.DigiArzLowPower = {
  enabled,
  set,
  shouldRefresh() {
    if (!enabled()) { ticks = 0; return true; }
    ticks = (ticks + 1) % 5;
    return ticks === 0;
  }
};
document.addEventListener('DOMContentLoaded', () => {
  const control = document.getElementById('lowPowerModeToggle');
  if (!control) return;
  control.checked = enabled();
  control.addEventListener('change', () => {
    set(control.checked);
    const message = document.getElementById('lowPowerModeMsg');
    if (message) {
      message.textContent = control.checked
        ? 'حالت کم‌مصرف فعال شد؛ به‌روزرسانی خودکار بازار با فاصلهٔ حدود ۵ دقیقه انجام می‌شود. به‌روزرسانی دستی همچنان در دسترس است.'
        : 'حالت کم‌مصرف غیرفعال شد؛ به‌روزرسانی خودکار بازار به حالت عادی بازگشت.';
      message.className = 'notice ok'; message.classList.remove('hidden');
    }
  });
});
})();