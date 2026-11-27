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

async function renderOfflineLogoFallbacks(page) {
  await page.evaluate(() => {
    const images = [...document.querySelectorAll('img[data-symbol], #detailLogo')];
    const colors = {BTC:'#f7931a',ETH:'#627eea',SOL:'#14b8a6',BNB:'#f3ba2f',XRP:'#23292f',DOGE:'#c2a633',ADA:'#0033ad',AAVE:'#b6509e',TRX:'#eb0029',LINK:'#2a5ada',LTC:'#345d9d',DOT:'#e6007a',TON:'#0098ea',AVAX:'#e84142',SHIB:'#f00500',USDC:'#2775ca'};
    for (const image of images) {
      const rawSymbol = image.dataset.symbol || document.getElementById('chartSymbol')?.textContent || image.alt || '';
      const symbol = String(rawSymbol).replace(/USDT$/i,'').replace(/[^a-z0-9]/gi,'').toUpperCase();
      if (!symbol) continue;
      const label = symbol.length > 4 ? symbol.slice(0,3) : symbol;
      const ns = 'http://www.w3.org/2000/svg';
      const svg = document.createElementNS(ns,'svg');
      svg.setAttribute('viewBox','0 0 48 48');
      svg.setAttribute('width','100%');
      svg.setAttribute('height','100%');
      svg.setAttribute('aria-hidden','true');
      const circle = document.createElementNS(ns,'circle');
      circle.setAttribute('cx','24');circle.setAttribute('cy','24');circle.setAttribute('r','22');
      circle.setAttribute('fill',colors[symbol]||'#526ee8');
      const text = document.createElementNS(ns,'text');
      text.setAttribute('x','24');text.setAttribute('y','25');text.setAttribute('text-anchor','middle');
      text.setAttribute('dominant-baseline','middle');text.setAttribute('fill','#fff');
      text.setAttribute('font-family','Arial,sans-serif');text.setAttribute('font-size',label.length>3?'11':'15');
      text.setAttribute('font-weight','800');text.textContent=label;
      svg.append(circle,text);
      if (image.id === 'detailLogo') {
        const fallback=document.createElement('span');
        fallback.className='asset-logo coin-logo-fallback';
        fallback.setAttribute('role','img');
        fallback.setAttribute('aria-label','نماد تصویری جایگزین '+symbol);
        fallback.append(svg);
        image.replaceWith(fallback);
      } else {
        image.replaceWith(svg);
      }
    }
  });
}

async function resetPageScroll(page) {
  await page.evaluate(() => {
    window.scrollTo(0, 0);
    document.documentElement.scrollTop = 0;
    document.body.scrollTop = 0;
    for (const element of document.querySelectorAll('*')) {
      if (element.scrollTop) element.scrollTop = 0;
    }
  });
}

(async () => {
  await new Promise(resolve => server.listen(4173, '127.0.0.1', resolve));
  const browser = await chromium.launch({ headless: true });
  const viewports = [
    { name:'mobile', width:390, height:844, deviceScaleFactor:1 },
    { name:'desktop', width:1440, height:1000, deviceScaleFactor:1 }
  ];
  const themes = ['dark','light','luxury'];
  const backgroundDiagnostics = [];

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
        if (theme === 'light') {
          backgroundDiagnostics.push(await page.evaluate(() => {
            const selectors = ['html','body','#appView','#tab-dashboard','.dashboard-panel','.wrap','.mobile-bottom-nav'];
            const describe = selector => {
              const el = document.querySelector(selector);
              if (!el) return {selector, missing:true};
              const style = getComputedStyle(el);
              return {selector, tag:el.tagName, className:el.className?.toString?.()||'', backgroundColor:style.backgroundColor, backgroundImage:style.backgroundImage, color:style.color};
            };
            const inspect = el => {
              const style=getComputedStyle(el);
              const before=getComputedStyle(el,'::before'), after=getComputedStyle(el,'::after');
              const rect=el.getBoundingClientRect();
              return {
                tag:el.tagName,id:el.id,className:el.className?.toString?.()||'',
                rect:{x:Math.round(rect.x),y:Math.round(rect.y),width:Math.round(rect.width),height:Math.round(rect.height)},
                backgroundColor:style.backgroundColor,backgroundImage:style.backgroundImage,
                boxShadow:style.boxShadow,filter:style.filter,opacity:style.opacity,
                before:{content:before.content,backgroundColor:before.backgroundColor,backgroundImage:before.backgroundImage,boxShadow:before.boxShadow},
                after:{content:after.content,backgroundColor:after.backgroundColor,backgroundImage:after.backgroundImage,boxShadow:after.boxShadow}
              };
            };
            const edge = document.elementsFromPoint(2, Math.min(200, innerHeight-1)).slice(0,8).map(inspect);
            const cards=[...document.querySelectorAll('#tab-dashboard > *, #tab-dashboard .card, #tab-dashboard .stat, #tab-dashboard .trade-box, #tab-dashboard .da-v2-hero, #tab-dashboard .da-v2-account-card')].filter(el=>{
              const r=el.getBoundingClientRect(); return r.width>0&&r.height>0;
            }).slice(0,30).map(inspect);
            return {viewport:{width:innerWidth,height:innerHeight}, bodyClass:document.body.className, selectors:selectors.map(describe), edgeAtX2Y200:edge, dashboardCardEffects:cards};
          }));
        }
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
          // Supabase is intentionally blocked in this harness; render the app's local branded SVG fallback instead of capturing a pending remote logo request.
          await renderOfflineLogoFallbacks(page);
          await resetPageScroll(page);
          await page.waitForTimeout(60);
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
            const lastMarketRow=marketRows.locator(':scope > .coin').last();
            await lastMarketRow.evaluate(el=>el.scrollIntoView({block:'end',behavior:'instant'}));
            await page.evaluate(()=>window.scrollTo(0,Math.max(document.documentElement.scrollHeight,document.body.scrollHeight)));
            const endVisibility=await page.evaluate(()=>{
              const last=document.querySelector('#marketList > .coin:last-child');
              const nav=document.querySelector('.mobile-bottom-nav');
              if(!last||!nav)return {ok:false,reason:'market last row or fixed navigation is missing'};
              const rowRect=last.getBoundingClientRect(),navRect=nav.getBoundingClientRect();
              return {ok:rowRect.bottom<=navRect.top-4,rowBottom:rowRect.bottom,navTop:navRect.top};
            });
            if(!endVisibility.ok)throw new Error('Last market asset row is obscured by bottom navigation: '+JSON.stringify(endVisibility));
            const firstMarketRow=marketRows.locator(':scope > .coin').first();
            await firstMarketRow.evaluate(el=>el.scrollIntoView({block:'start',behavior:'instant'}));
            await page.evaluate(()=>{
              const header=document.querySelector('.top');
              const offset=(header?.getBoundingClientRect().height||80)+8;
              window.scrollBy(0,-offset);
            });
            const startVisibility=await page.evaluate(()=>{
              const first=document.querySelector('#marketList > .coin:first-child');
              const header=document.querySelector('.top');
              if(!first||!header)return {ok:false,reason:'market first row or sticky header is missing'};
              return {ok:first.getBoundingClientRect().top>=header.getBoundingClientRect().bottom+4};
            });
            if(!startVisibility.ok)throw new Error('First market asset row is obscured by sticky header');
            await page.waitForTimeout(100);
            await page.screenshot({path:path.join(output,['mobile',theme,'markets-assetrows'].join('-')+'.png'),fullPage:false,animations:'disabled'});
          }
        }
        // Capture the authentication screen independently for every theme and viewport.
        await page.evaluate(() => {
          const auth=document.getElementById('authView');
          const app=document.getElementById('appView');
          document.body.classList.remove('dashboard-page-active');
          document.body.classList.add('auth-page-active');
          if (app) { app.classList.remove('app-view-active'); app.classList.add('hidden'); app.style.display='none'; }
          if (auth) { auth.classList.remove('hidden'); auth.style.display='grid'; }
        });
        await resetPageScroll(page);
        await page.waitForTimeout(80);
        await page.screenshot({path:path.join(output,[viewport.name,theme,'login'].join('-')+'.png'),fullPage:viewport.name==='desktop',animations:'disabled'});
        await page.evaluate(() => {
          const auth=document.getElementById('authView');
          const app=document.getElementById('appView');
          document.body.classList.remove('auth-page-active');
          document.body.classList.add('dashboard-page-active');
          if (auth) { auth.classList.add('hidden'); auth.style.display='none'; }
          if (app) { app.classList.remove('hidden'); app.classList.add('app-view-active'); app.style.display='block'; }
        });
      }
      await context.close();
    }
    const files=fs.readdirSync(output).filter(name=>name.endsWith('.png'));
    if (files.length!==72) throw new Error('Expected 72 screenshots, got '+files.length);
    fs.writeFileSync(path.join(output,'README.txt'),'DigiArz UI visual review screenshots\n72 captures: 2 viewports x 3 themes x 10 app sections, 6 authentication screens, plus mobile dashboard/market row close-ups.\nSupabase API and logo-proxy requests were blocked; local branded SVG logo fallbacks are used in the visual harness. No production data was changed.\nMarket, dashboard, asset and top-volume rows are synthetic DOM-only fixtures. Authentication captures use the local UI shell only; no credentials are submitted. Mobile row close-ups scroll to the actual rendered asset lists.\n');
    console.log('Created '+files.length+' screenshots in '+output);
    fs.writeFileSync(path.join(output, 'theme-background-diagnostics.json'), JSON.stringify(backgroundDiagnostics, null, 2));
  } finally {
    await browser.close();
    await new Promise(resolve=>server.close(resolve));
  }
})().catch(error=>{console.error(error);process.exitCode=1});
