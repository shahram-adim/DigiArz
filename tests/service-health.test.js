const fs = require('fs');
const path = require('path');
const html = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
const moduleSource = fs.readFileSync(path.join(__dirname, '..', 'src', 'service-health.js'), 'utf8');
for (const id of ['serviceHealthPanel','serviceNetworkStatus','serviceMarketStatus','serviceMarketCheckedAt','serviceMarketSource','serviceAccountStatus','serviceHealthRefresh']) {
  if (!html.includes('id="' + id + '"')) throw new Error('Missing service health UI: ' + id);
}
for (const phrase of ['digiarz:market-health','navigator.onLine','وضعیت اتصال حساب از این پنل مستقلاً آزمایش نمی‌شود','دادهٔ بازار تازه دریافت شده']) {
  if (!moduleSource.includes(phrase)) throw new Error('Missing truthful health behavior: ' + phrase);
}
if (!html.includes("new CustomEvent('digiarz:market-health'")) throw new Error('Market refresh does not publish health timestamp/source');
console.log('Service health panel tests passed');
