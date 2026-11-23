const fs = require('fs');
const path = require('path');
const html = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
for (const id of ['publicCryptoQrPanel','publicQrSymbol','publicQrGenerate','publicQrStatus','publicQrOutput','publicQrImage']) {
  if (!html.includes('id="' + id + '"')) throw new Error('Missing public QR UI: ' + id);
}
for (const phrase of ['function renderPublicCryptoQr()','public-crypto-info','api.qrserver.com/v1/create-qr-code','marketUrl:publicUrl','button.dataset.bound']) {
  if (!html.includes(phrase)) throw new Error('Missing safe public QR behavior: ' + phrase);
}
if (/payload\s*=\s*JSON\.stringify\(\{[^}]*?(?:token|password|secret|walletBalance|session)/is.test(html)) {
  throw new Error('QR payload appears to contain private account data');
}
console.log('Public crypto QR tests passed');
