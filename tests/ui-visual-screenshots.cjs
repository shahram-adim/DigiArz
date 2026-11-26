const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

const root = path.resolve(process.cwd());
const output = path.join(root, 'artifacts', 'ui-visual');
fs.mkdirSync(output, { recursive: true });
const mime = { '.html':'text/html; charset=utf-8', '.css':'text/css; charset=utf-8', '.js':'text/javascript; charset=utf-8', '.svg':'image/svg+xml', '.webmanifest':'application/manifest+json', '.png':'image/png', '.woff2':'font/woff2' };

const visualFixtures = [
  {symbol:'BTCUSDT',base:'BTC',fa:'بیت‌کوین',en:'Bitcoin',price:67420.5,change:2.42,volume:1825000000,icon:'₿',qty:'0.025'},
  {symbol:'ETHUSDT',base:'ETH',fa:'اتریوم',en:'Ethereum',price:3521.8,change:1.78,volume:925000000,icon:'◆',qty:'0.8'},
  {symbol:'SOLUSDT',base:'SOL',fa:'سولانا',en:'Solana',price:172.65,change:2.75,volume:412000000,icon:'◎',qty:'3.5'},
  {symbol:'BNBUSDT',base:'BNB',fa:'بایننس کوین',en:'BNB',price:612.4,change:-0.64,volume:185000000,icon:'◆',qty:'0'},
  {symbol:'XRPUSDT',base:'XRP',fa:'ریپل',en:'XRP',price:0.624,change:0.91,volume:142000000,icon:'✕',qty:'0'},
  {symbol:'DOGEUSDT',base:'DOGE',fa:'دوج‌کوین',en:'Dogecoin',price:0.1642,change:-1.12,volume:98000000,icon:'Ð',qty:'0'},
  {symbol:'ADAUSDT',base:'ADA',fa:'کاردانو',en:'Cardano',price:0.482,change:0.35,volume:76000000,icon:'◉',qty:'0'},
  {symbol:'AAVEUSDT',base:'AAVE',fa:'آوه',en:'Aave',price:96.8,change:2.17,volume:54000000,icon:'◉',qty:'0'}
];

async function seedVisualFixtures(page) {
  const counts = await page.evaluate(rows => {
    const number = value => new Intl.NumberFormat('en-US',{maximumFractionDigits:2}).format(value);
    const toman = value => new Intl.NumberFormat('fa-IR',{maximumFractionDigits:0}).format(Math.round(value*584200))+' تومان';
    const market = document.getElementById('marketList');
    const dashboard = document.getElementById('dashboardMarketPreview');
    const assets = document.getElementById('assetList');
    const top = document.getElementById('topAssetsList');
    const tetherRow = '<div class="coin tether-pinned" data-symbol="USDT" role="group" aria-label="تتر USDT · ارز پایدار و دارایی مبنا">'+
      '<button class="favorite-btn" type="button" aria-label="افزودن تتر به علاقه‌مندی‌ها">☆</button>'+
      '<div class="coin-identity tether-identity"><span class="coin-icon tether-logo" role="img" aria-label="لوگوی تتر USDT"><svg viewBox="0 0 48 48" width="100%" height="100%" aria-hidden="true"><circle cx="24" cy="24" r="23" fill="#26A17B"/><path d="M11 11h26v5H26.5v5.2c6.3.4 10.8 1.5 10.8 2.9s-5.9 3-13.3 3-13.3-1.6-13.3-3 4.5-2.5 10.8-2.9V16H11v-5zm13 9.5c-6.8 0-12.3 1.1-12.3 2.6s5.5 2.6 12.3 2.6 12.3-1.1 12.3-2.6-5.5-2.6-12.3-2.6zM21.5 25h5v12h-5z" fill="#fff"/></svg></span><span class="coin-name-stack"><b class="coin-name-fa">تتر</b><small class="coin-symbol-en" dir="ltr">USDT</small><small class="coin-english-name" dir="ltr">Tether</small></span><span class="tether-pin-label">ارز مبنا</span></div>'+
      '<span class="coin-sparkline tether-peg-indicator" aria-label="ارزش هدف یک دلار آمریکا">≈ $1</span>'+
      '<div class="coin-change-wrap tether-meta"><small class="coin-change-label">استیبل‌کوین دلاری</small><span class="coin-change pos">ثبات قیمت</span><small class="coin-volume">دارایی مبنا برای بازارهای USDT</small></div>'+
      '<div class="price-stack"><div class="price-usd"><strong>$ 1.00</strong></div><div class="price-toman"><strong>۵۸۴٬۲۰۰ تومان</strong></div></div></div>';
  if (market) market.innerHTML = tetherRow + rows.map(row => {
      const changeClass = row.change >= 0 ? 'pos' : 'neg';
      const arrow = row.change >= 0 ? '▲ +' : '▼ ';
      return '<div class="coin" data-symbol="'+row.symbol+'">'+
        '<button class="favorite-btn" type="button" aria-label="افزودن به علاقه‌مندی‌ها">☆</button>'+
        '<button class="coin-identity market-coin-open" type="button"><span class="coin-icon" aria-label="'+row.en+' logo"><span>'+row.icon+'</span></span>'+
        '<span class="coin-name-stack"><b class="coin-name-fa">'+row.fa+'</b><small class="coin-symbol-en" dir="ltr">'+row.base+'</small><small class="coin-english-name" dir="ltr">'+row.en+'</small></span></button>'+
        '<span class="coin-sparkline" aria-label="نمودار قیمت">⌁⌁⌁</span>'+
        '<div class="coin-change-wrap"><small class="coin-change-label">تغییر ۲۴س</small><span class="coin-change '+changeClass+'">'+arrow+number(Math.abs(row.change))+'٪</span><small class="coin-volume">حجم ۲۴س: '+number(row.volume)+' USDT</small></div>'+
        '<div class="price-stack"><div class="price-usd"><strong>$ '+number(row.price)+'</strong></div><div class="price-toman"><strong>'+toman(row.price)+'</strong></div></div></div>';
    }).join('');
    if (dashboard) dashboard.innerHTML = rows.map(row => {
      const changeClass = row.change >= 0 ? 'pos' : 'neg';
      const arrow = row.change >= 0 ? '▲ +' : '▼ ';
      return '<article class="dashboard-market-coin da-market-coin-card"><div class="da-market-card-top">'+
        '<button class="da-market-favorite" type="button" aria-label="افزودن به علاقه‌مندی‌ها">☆</button>'+
        '<button class="da-market-identity" type="button"><span class="da-market-logo"><span class="da-market-logo-inner">'+row.icon+'</span></span>'+
        '<span class="da-market-name-wrap"><b>'+row.fa+'</b><small class="da-market-name-en" dir="ltr">'+row.en+'</small><small dir="ltr">'+row.base+'/USDT</small></span></button></div>'+
        '<span class="coin-sparkline da-market-sparkline">⌁⌁⌁</span><strong class="da-market-price">$'+number(row.price)+'</strong>'+
        '<small class="da-market-toman">'+toman(row.price)+'</small><div class="da-market-card-foot"><span class="da-market-change '+changeClass+'">'+arrow+number(Math.abs(row.change))+'٪</span></div></article>';
    }).join('');
    if (assets) assets.innerHTML = rows.filter(row => Number(row.qty)>0).map(row =>
      '<div class="asset-row"><div class="asset-symbol asset-row-main"><span class="asset-logo">'+row.icon+'</span>'+
      '<span><b>'+row.fa+'</b><small class="asset-name-en" dir="ltr">'+row.en+'</small><small>'+row.base+'</small></span></div>'+
      '<div class="price-stack"><div class="price-usd">موجودی: '+row.qty+'</div><div class="price-usd">قیمت واحد: '+number(row.price)+' USDT</div>'+
      '<div class="price-toman">ارزش: '+number(Number(row.qty)*row.price)+' USDT</div><div class="price-toman">'+toman(Number(row.qty)*row.price)+'</div></div>'+
      '<button class="secondary" type="button">مشاهده بازار</button></div>'
    ).join('');
    if (top) top.innerHTML = rows.slice(0,4).map(row =>
      '<button class="top-asset-card" type="button"><span class="coin-icon">'+row.icon+'</span>'+
      '<b class="top-asset-name-fa">'+row.fa+'</b><small class="top-asset-name-en" dir="ltr">'+row.en+'</small>'+
      '<small class="top-asset-symbol" dir="ltr">'+row.base+'</small><span class="top-usd">$'+number(row.price)+'</span>'+
      '<span class="top-toman">'+toman(row.price)+'</span><strong class="top-change '+(row.change>=0?'pos':'neg')+'">'+(row.change>0?'+':'')+number(row.change)+'٪</strong></button>'
    ).join('');
    const set = (id,value) => {const el=document.getElementById(id);if(el)el.textContent=value};
    set('dashboardMarketCount','۸');
    set('dashboardFxRate','۵۸۴٬۲۰۰ تومان');
    set('dashboardPriceCount','۸');
    set('dashboardMarketResultCount','۸ ارز با قیمت معتبر · نمایش ۸');
    set('assetCount','۳');
    set('assetResultCount','نمایش ۳ از ۳ دارایی دارای موجودی');
    set('dashboardTotalUsdValue','۲٬۷۶۳٫۹۹ USDT');
    set('totalTomanValue','۱٬۶۱۴٬۰۵۰٬۰۰۰ تومان');
    return {
      marketCards:market?.querySelectorAll(':scope > .coin').length||0,
      dashboardCards:dashboard?.querySelectorAll(':scope > .da-market-coin-card').length||0,
      assetCards:assets?.querySelectorAll(':scope > .asset-row').length||0,
      topCards:top?.querySelectorAll(':scope > .top-asset-card').length||0
    };
  }, visualFixtures);
  if (counts.marketCards!==9 || counts.dashboardCards!==8 || counts.assetCards!==3 || counts.topCards!==4) {
    throw new Error('Visual DOM fixture incomplete: '+JSON.stringify(counts));
  }
  return counts;
}

const server = http.createServer((req, res) => {
  const pathname = decodeURIComponent(new URL(req.url, 'http://127.0.0.1').pathname);
  const target = path.resolve(root, '.' + pathname);
  if (!target.startsWith(root + path.sep) && target !== path.join(root, 'index.html')) {
    res.writeHead(403).end('Forbidden'); return;
  }
  const file = pathname === '/' ? path.join(root, 'index.html') : target;
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
    { name:'mobile', width:390, height:844, deviceScaleFactor:1 },
    { name:'desktop', width:1440, height:1000, deviceScaleFactor:1 }
  ];
  const themes = ['dark','light','luxury'];
  const tabs = ['dashboard','markets','toman','chart','trade','assets','orders','history','admin','settings'];
  try {
    for (const viewport of viewports) {
      const context = await browser.newContext({ viewport, deviceScaleFactor:1, serviceWorkers:'block', reducedMotion:'reduce' });
      const page = await context.newPage();
      page.setDefaultTimeout(15000);
      page.on('pageerror', error => console.warn('Page error:', error.message));
      await page.route('**/*', route => {
        const url = route.request().url();
        if (/^https?:\/\/(?:[^/]+\.)?supabase\.co\//i.test(url)) return route.abort();
        return route.continue();
      });
      await page.goto('http://127.0.0.1:4173/index.html', { waitUntil:'domcontentloaded' });
      await page.waitForTimeout(1200);
      await seedVisualFixtures(page);
      for (const theme of themes) {
        await page.evaluate(selected => {
          document.body.classList.toggle('light-theme', selected==='light');
          document.body.classList.toggle('luxury-theme', selected==='luxury');
          document.body.classList.toggle('dark-theme', selected==='dark');
          document.documentElement.style.colorScheme = selected==='dark'?'dark':'light';
          document.body.classList.remove('auth-page-active');
          document.body.classList.add('dashboard-page-active');
          const auth=document.getElementById('authView'), app=document.getElementById('appView');
          if (auth) { auth.classList.add('hidden'); auth.style.display='none'; }
          if (app) { app.classList.remove('hidden'); app.classList.add('app-view-active'); app.style.display='block'; }
        }, theme);
        for (const tab of tabs) {
          const visible = await page.evaluate(name => {
            const sections=[...document.querySelectorAll('[id^="tab-"]')];
            sections.forEach(section=>{section.classList.add('hidden');section.style.display='none'});
            const target=document.getElementById('tab-'+name);
            if (!target) return false;
            target.classList.remove('hidden');target.style.display='block';
            return true;
          }, tab);
          if (!visible) throw new Error('Missing UI section: tab-'+tab);
          const rendered = await page.evaluate(name => {
            const app=document.getElementById('appView'), section=document.getElementById('tab-'+name);
            const rect=section&&section.getBoundingClientRect();
            return !!app&&getComputedStyle(app).display!=='none'&&app.classList.contains('app-view-active')
              &&!!section&&getComputedStyle(section).display!=='none'&&!!rect&&rect.height>=250;
          }, tab);
          if (!rendered) throw new Error('Section did not render visibly: tab-'+tab);
          await seedVisualFixtures(page);
          const filename=[viewport.name,theme,tab].join('-')+'.png';
          await page.screenshot({path:path.join(output,filename),fullPage:viewport.name==='desktop',animations:'disabled'});
          if (viewport.name==='mobile' && tab==='dashboard') {
            const marketPreview=page.locator('#dashboardMarketPreview');
            await marketPreview.scrollIntoViewIfNeeded();
            await page.waitForTimeout(100);
            await page.screenshot({path:path.join(output,['mobile',theme,'dashboard-marketrows'].join('-')+'.png'),fullPage:false,animations:'disabled'});
          }
          if (viewport.name==='mobile' && tab==='markets') {
            const marketRows=page.locator('#marketList');
            await marketRows.scrollIntoViewIfNeeded();
            await page.waitForTimeout(100);
            await page.screenshot({path:path.join(output,['mobile',theme,'markets-assetrows'].join('-')+'.png'),fullPage:false,animations:'disabled'});
          }
        }
      }
      await context.close();
    }
    const files=fs.readdirSync(output).filter(name=>name.endsWith('.png'));
    if (files.length!==66) throw new Error('Expected 66 screenshots, got '+files.length);
    fs.writeFileSync(path.join(output,'README.txt'),'DigiArz UI visual review screenshots\n66 captures: 2 viewports x 3 themes x 10 app sections, plus mobile dashboard/market row close-ups.\nSupabase API requests were blocked; no production data was changed.\nMarket, dashboard, asset and top-volume rows are synthetic DOM-only fixtures. Mobile row close-ups scroll to the actual rendered asset lists.\n');
    console.log('Created '+files.length+' screenshots in '+output);
  } finally {
    await browser.close();
    await new Promise(resolve=>server.close(resolve));
  }
})().catch(error=>{console.error(error);process.exitCode=1});
