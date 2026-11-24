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
