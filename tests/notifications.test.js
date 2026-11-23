const fs = require('fs');
const path = require('path');
const html = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
const source = fs.readFileSync(path.join(__dirname, '..', 'src', 'notifications.js'), 'utf8');
for (const id of ['notificationsPanel','priceAlertSymbol','priceAlertMetric','priceAlertDirection','priceAlertTarget','priceAlertAdd','activePriceAlerts','notificationHistoryList','notificationPermission','notificationClearHistory']) {
  if (!html.includes('id="' + id + '"')) throw new Error('Missing notification UI: ' + id);
}
for (const phrase of ['digiarz:market-snapshot','Notification.requestPermission','digiArzPriceAlertsV1','digiArzNotificationHistoryV1','حداکثر ۵۰ هشدار فعال','row.change24h===null']) {
  if (!source.includes(phrase)) throw new Error('Missing notification behavior: ' + phrase);
}
if (!html.includes('new CustomEvent(\'digiarz:market-snapshot\'')) throw new Error('Market view does not publish snapshots for price alerts');
if (!html.includes('./src/notifications.js')) throw new Error('Notification module is not loaded');
console.log('DigiArz notification and price alert tests passed');
