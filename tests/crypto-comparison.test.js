const fs = require('fs');
const path = require('path');
const html = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
for (const id of ['cryptoComparePanel','compareSymbolA','compareSymbolB','compareRefreshBtn','cryptoCompareResult']) {
  if (!html.includes('id="' + id + '"')) throw new Error('Missing crypto comparison UI: ' + id);
}
for (const phrase of ['function renderCryptoComparison()','getTrustedMarketPrice(item)','getMarketChange24h(item)','ناموجود','دو رمزارز متفاوت']) {
  if (!html.includes(phrase)) throw new Error('Missing comparison behavior: ' + phrase);
}
if (!html.includes("addEventListener('change',renderCryptoComparison)")) throw new Error('Comparison selectors are not wired');
console.log('Crypto comparison tests passed');
