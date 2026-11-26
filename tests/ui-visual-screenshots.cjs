const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

const root = path.resolve(process.cwd());
const output = path.join(root, 'artifacts', 'ui-visual');
fs.mkdirSync(output, { recursive: true });
const mime = { '.html':'text/html; charset=utf-8', '.css':'text/css; charset=utf-8', '.js':'text/javascript; charset=utf-8', '.svg':'image/svg+xml', '.webmanifest':'application/manifest+json', '.png':'image/png', '.woff2':'font/woff2' };

const server = http.createServer((req, res) => {
  const pathname = decodeURIComponent(new URL(req.url, 'http://127.0.0.1').pathname);
  const target = path.resolve(root, '.' + pathname);
  if (!target.startsWith(root + path.sep) && target !== path.join(root, 'index.html')) {
    res.writeHead(403).end('Forbidden'); return;
  }
  let file = target;
  if (pathname === '/') file = path.join(root, 'index.html');
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404).end('Not found'); return; }
    res.writeHead(200, { 'content-type': mime[path.extname(file)] || 'application/octet-stream' });
    res.end(data);
  });
});

(async () => {
  await new Promise(resolve => server.listen(4173, '127.0.0.1', resolve));
  const browser = await chromium.launch({ headless: true });
  const viewports = [
    { name: 'mobile', width: 390, height: 844, deviceScaleFactor: 1 },
    { name: 'desktop', width: 1440, height: 1000, deviceScaleFactor: 1 }
  ];
  const themes = ['dark', 'light', 'luxury'];
  const tabs = ['dashboard', 'markets', 'toman', 'chart', 'trade', 'assets', 'orders', 'history', 'admin', 'settings'];
  try {
    for (const viewport of viewports) {
      const context = await browser.newContext({ viewport, deviceScaleFactor: 1, serviceWorkers: 'block', reducedMotion: 'reduce' });
      const page = await context.newPage();
      page.setDefaultTimeout(15000);
      page.on('pageerror', error => console.warn('Page error:', error.message));
      await page.route('**/*', route => {
        const url = route.request().url();
        if (/^https?:\/\/(?:[^/]+\.)?supabase\.co\//i.test(url)) return route.abort();
        return route.continue();
      });
      await page.goto('http://127.0.0.1:4173/index.html', { waitUntil: 'domcontentloaded' });
      await page.waitForTimeout(1200);
      // Deterministic visual-only market/account fixtures. Supabase remains blocked;
      // these rows are synthetic and are never written to the application or backend.
      await page.evaluate(() => {
        const now = new Date().toISOString();
        const samples = [
          ['BTCUSDT','Bitcoin','بیت‌کوین',67420.5,2.42,1825000000],
          ['ETHUSDT','Ethereum','اتریوم',3521.8,1.78,925000000],
          ['SOLUSDT','Solana','سولانا',172.65,2.75,412000000],
          ['BNBUSDT','BNB','بایننس کوین',612.4,-0.64,185000000],
          ['XRPUSDT','XRP','ریپل',0.624,0.91,142000000],
          ['DOGEUSDT','Dogecoin','دوج‌کوین',0.1642,-1.12,98000000],
          ['ADAUSDT','Cardano','کاردانو',0.482,0.35,76000000],
          ['AAVEUSDT','Aave','آوه',96.8,2.17,54000000]
        ];
        marketRows = samples.map(([symbol,name,name_fa,price,change,quoteVolume]) => ({
          symbol,name,name_en:name,name_fa,price:String(price),change,
          updated_at:now,change_updated_at:now,source:'visual-fixture'
        }));
        featuredMarketRows = marketRows.slice(0,4);
        marketTickerLastFetchedAt = Date.now();
        marketTickerMap = new Map(samples.map(([symbol,, ,price,change,quoteVolume]) => [
          symbol,{symbol,last:String(price),change,quoteVolume,closeTime:Date.now()}
        ]));
        currentFxRate = 584200;
        currentFxIsValid = true;
        currentWalletUsdt = 200;
        assetRows = [
          {asset:'BTC',balance:'0.025'},
          {asset:'ETH',balance:'0.8'},
          {asset:'SOL',balance:'3.5'},
          {asset:'USDT',balance:'50'}
        ];
        try { renderMarkets(); } catch (error) { console.warn('Visual market fixture:',error.message); }
        try { renderDashboardSummary(); } catch (error) { console.warn('Visual dashboard fixture:',error.message); }
        try { renderTopAssets(); } catch (error) { console.warn('Visual top-assets fixture:',error.message); }
        try { renderAssets(); } catch (error) { console.warn('Visual portfolio fixture:',error.message); }
      });
      for (const theme of themes) {
        await page.evaluate(selected => {
          document.body.classList.toggle('light-theme', selected === 'light');
          document.body.classList.toggle('luxury-theme', selected === 'luxury');
          document.body.classList.toggle('dark-theme', selected === 'dark');
          document.documentElement.style.colorScheme = selected === 'light' ? 'light' : 'dark';
          document.body.classList.remove('auth-page-active');
          document.body.classList.add('dashboard-page-active');
          const auth = document.getElementById('authView');
          const app = document.getElementById('appView');
          if (auth) { auth.classList.add('hidden'); auth.style.display = 'none'; }
          if (app) { app.classList.remove('hidden'); app.classList.add('app-view-active'); app.style.display = 'block'; }
          try { isSuperAdmin = true; } catch (_) {}
        }, theme);
        for (const tab of tabs) {
          const visible = await page.evaluate(name => {
            const sections = [...document.querySelectorAll('[id^="tab-"]')];
            sections.forEach(section => { section.classList.add('hidden'); section.style.display = 'none'; });
            const target = document.getElementById('tab-' + name);
            if (!target) return false;
            target.classList.remove('hidden');
            target.style.display = 'block';
            return true;
          }, tab);
          if (!visible) throw new Error('Missing UI section: tab-' + tab);
          const rendered = await page.evaluate(name => {
            const app = document.getElementById('appView');
            const section = document.getElementById('tab-' + name);
            const appStyle = app && getComputedStyle(app);
            const sectionStyle = section && getComputedStyle(section);
            const rect = section && section.getBoundingClientRect();
            return !!app && appStyle.display !== 'none' && app.classList.contains('app-view-active')
              && !!section && sectionStyle.display !== 'none' && !!rect && rect.height >= 250;
          }, tab);
          if (!rendered) throw new Error('Section did not render visibly: tab-' + tab);
          await page.waitForTimeout(180);
          // Reapply deterministic fixtures after app startup and tab transitions:
          // late rejected Supabase loads must never erase the visual-only dataset.
          const fixtureCounts = await page.evaluate(() => {
            const now = new Date().toISOString();
            const samples = [
              ['BTCUSDT','Bitcoin','بیت‌کوین',67420.5,2.42,1825000000],
              ['ETHUSDT','Ethereum','اتریوم',3521.8,1.78,925000000],
              ['SOLUSDT','Solana','سولانا',172.65,2.75,412000000],
              ['BNBUSDT','BNB','بایننس کوین',612.4,-0.64,185000000],
              ['XRPUSDT','XRP','ریپل',0.624,0.91,142000000],
              ['DOGEUSDT','Dogecoin','دوج‌کوین',0.1642,-1.12,98000000],
              ['ADAUSDT','Cardano','کاردانو',0.482,0.35,76000000],
              ['AAVEUSDT','Aave','آوه',96.8,2.17,54000000]
            ];
            marketRows = samples.map(([symbol,name,name_fa,price,change,quoteVolume]) => ({
              symbol,name,name_en:name,name_fa,price:String(price),change,quoteVolume,
              updated_at:now,change_updated_at:now,source:'visual-fixture'
            }));
            featuredMarketRows = marketRows.slice(0,4);
            marketTickerLastFetchedAt = Date.now();
            marketTickerMap = new Map(samples.map(([symbol,, ,price,change,quoteVolume]) => [
              symbol,{symbol,last:String(price),change,quoteVolume,closeTime:Date.now()}
            ]));
            currentFxRate = 584200;
            currentFxIsValid = true;
            currentWalletUsdt = 200;
            assetRows = [
              {asset:'BTC',balance:'0.025'},
              {asset:'ETH',balance:'0.8'},
              {asset:'SOL',balance:'3.5'},
              {asset:'USDT',balance:'50'}
            ];
            activeMarketCategory = 'all';
            dashboardMarketFilter = 'all';
            dashboardMarketLimit = 8;
            marketDisplayLimit = 80;
            renderMarkets();
            renderDashboardSummary();
            renderTopAssets();
            renderAssets();
            return {
              marketRows:marketRows.length,
              marketCards:document.querySelectorAll('#marketList>.coin').length,
              dashboardCards:document.querySelectorAll('#dashboardMarketPreview .da-market-coin-card').length
            };
          });
          if (fixtureCounts.marketRows !== 8 || fixtureCounts.marketCards !== 8 || fixtureCounts.dashboardCards !== 8) {
            throw new Error('Visual fixture render incomplete: '+JSON.stringify(fixtureCounts));
          }
          const filename = [viewport.name, theme, tab].join('-') + '.png';
          await page.screenshot({ path: path.join(output, filename), fullPage: true, animations: 'disabled' });
        }
      }
      await context.close();
    }
    const files = fs.readdirSync(output).filter(name => name.endsWith('.png'));
    if (files.length !== 60) throw new Error('Expected 60 screenshots, got ' + files.length);
    fs.writeFileSync(path.join(output, 'README.txt'), 'DigiArz UI visual review screenshots\n60 captures: 2 viewports x 3 themes x 10 app sections.\nSupabase API requests were blocked; no production data was changed.\nTabs are shown in an isolated visual harness without user authentication.\n');
    console.log('Created ' + files.length + ' screenshots in ' + output);
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
