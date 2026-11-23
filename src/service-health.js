(() => {
  'use strict';
  const state = { marketAt: 0, marketSource: '', marketCoverage: null, marketError: '' };
  const $ = (id) => document.getElementById(id);
  const fmt = (value) => {
    if (!value) return 'هنوز ثبت نشده';
    try { return new Date(value).toLocaleString('fa-IR'); } catch (_) { return 'نامشخص'; }
  };
  function render() {
    const online = typeof navigator === 'undefined' ? null : navigator.onLine;
    const network = $('serviceNetworkStatus');
    const market = $('serviceMarketStatus');
    const marketTime = $('serviceMarketCheckedAt');
    const source = $('serviceMarketSource');
    const account = $('serviceAccountStatus');
    if (network) {
      network.textContent = online === null ? 'نامشخص' : online ? 'دستگاه آنلاین است' : 'دستگاه آفلاین است';
      network.className = online === false ? 'neg' : online === true ? 'pos' : 'muted';
    }
    const age = state.marketAt ? Date.now() - state.marketAt : Infinity;
    const fresh = age >= -60000 && age <= 120000;
    if (market) {
      market.textContent = !state.marketAt ? 'هنوز داده‌ای دریافت نشده' : fresh ? 'دادهٔ بازار تازه دریافت شده' : 'آخرین داده قدیمی است';
      market.className = !state.marketAt || !fresh ? 'muted' : 'pos';
    }
    if (marketTime) marketTime.textContent = fmt(state.marketAt);
    if (source) source.textContent = state.marketSource || state.marketError || 'منبع هنوز گزارش نشده';
    if (account) account.textContent = 'وضعیت اتصال حساب از این پنل مستقلاً آزمایش نمی‌شود';
  }
  function acceptMarketEvent(event) {
    const detail = event && event.detail || {};
    if (Number.isFinite(Number(detail.at)) && Number(detail.at) > 0) state.marketAt = Number(detail.at);
    if (typeof detail.source === 'string') state.marketSource = detail.source;
    if (typeof detail.error === 'string') state.marketError = detail.error;
    render();
  }
  function init() {
    render();
    window.addEventListener('online', render);
    window.addEventListener('offline', render);
    window.addEventListener('digiarz:market-health', acceptMarketEvent);
    const button = $('serviceHealthRefresh');
    if (button) button.addEventListener('click', render);
    document.addEventListener('visibilitychange', () => { if (!document.hidden) render(); });
  }
  window.DigiArzServiceHealth = { render, acceptMarketEvent };
  if (typeof document !== 'undefined') {
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
    else init();
  }
})();