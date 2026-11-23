(() => {
'use strict';
const ALERTS_KEY='digiArzPriceAlertsV1', HISTORY_KEY='digiArzNotificationHistoryV1';
let latestRows=[];
const $=id=>document.getElementById(id);
function read(key,fallback){try{const value=JSON.parse(localStorage.getItem(key)||'null');return value??fallback}catch(_){return fallback}}
function write(key,value){try{localStorage.setItem(key,JSON.stringify(value));return true}catch(_){return false}}
function alerts(){const value=read(ALERTS_KEY,[]);return Array.isArray(value)?value:[]}
function history(){const value=read(HISTORY_KEY,[]);return Array.isArray(value)?value:[]}
function render(){
 const list=$('notificationHistoryList'),count=$('notificationCount'),select=$('priceAlertSymbol');
 const items=history();
 if(count)count.textContent=String(items.length);
 if(list){list.replaceChildren();if(!items.length){const empty=document.createElement('p');empty.className='muted small';empty.textContent='هنوز اعلانی ثبت نشده است.';list.append(empty)}else items.slice(0,30).forEach(item=>{const row=document.createElement('div');row.className='setting-row';row.style.marginTop='8px';const content=document.createElement('div');const title=document.createElement('strong');title.textContent=String(item.title||'اعلان');const body=document.createElement('small');body.textContent=String(item.body||'');const time=document.createElement('small');time.textContent=new Date(item.at||Date.now()).toLocaleString('fa-IR');content.append(title,body,time);row.append(content);list.append(row)})}
 if(select){const previous=select.value;select.replaceChildren();const placeholder=document.createElement('option');placeholder.value='';placeholder.textContent='انتخاب رمزارز';select.append(placeholder);latestRows.forEach(item=>{const option=document.createElement('option');option.value=item.symbol;option.textContent=item.symbol.replace(/USDT$/i,'')+' · '+(item.name||item.symbol);select.append(option)});if([...select.options].some(x=>x.value===previous))select.value=previous}
}
function publish(type,title,body){
 const entry={id:(Date.now().toString(36)+Math.random().toString(36).slice(2,7)),type:String(type||'general'),title:String(title||'اعلان DigiArz').slice(0,120),body:String(body||'').slice(0,300),at:Date.now()};
 const next=[entry,...history()].slice(0,100);write(HISTORY_KEY,next);render();
 try{if('Notification'in window&&Notification.permission==='granted')new Notification(entry.title,{body:entry.body,tag:entry.id})}catch(_){}
 return entry;
}
function evaluate(event){
 const detail=event&&event.detail||{};if(!Array.isArray(detail.rows))return;
 latestRows=detail.rows.filter(x=>x&&typeof x.symbol==='string'&&Number.isFinite(Number(x.price))&&Number(x.price)>0);
 const pending=alerts(),remaining=[];let changed=false;
 for(const alert of pending){
  const row=latestRows.find(x=>x.symbol===alert.symbol);if(!row){remaining.push(alert);continue}
  const value=alert.metric==='percent'?Number(row.change24h):Number(row.price);
  if(!Number.isFinite(value)){remaining.push(alert);continue}
  const hit=alert.direction==='below'?value<=alert.target:value>=alert.target;
  if(hit){publish('price', 'هشدار قیمت '+alert.symbol, (alert.metric==='percent'?'تغییر ۲۴ ساعته ':'قیمت ')+value+' به شرط '+(alert.direction==='below'?'≤ ':'≥ ')+alert.target+' رسید.');changed=true}else remaining.push(alert);
 }
 if(changed)write(ALERTS_KEY,remaining);
 render();
}
function addAlert(){
 const symbol=$('priceAlertSymbol')?.value,metric=$('priceAlertMetric')?.value||'price',direction=$('priceAlertDirection')?.value||'above',raw=$('priceAlertTarget')?.value,target=Number(raw),status=$('priceAlertStatus');
 if(!symbol||!Number.isFinite(target)||target<=0){if(status){status.textContent='رمزارز و مقدار معتبر و بزرگ‌تر از صفر انتخاب کنید.';status.className='notice warn'}return}
 const current=alerts();if(current.length>=50){if(status){status.textContent='حداکثر ۵۰ هشدار فعال می‌توانید داشته باشید.';status.className='notice warn'}return}
 if(current.some(x=>x.symbol===symbol&&x.metric===metric&&x.direction===direction&&x.target===target)){if(status){status.textContent='این هشدار از قبل ثبت شده است.';status.className='notice warn'}return}
 current.push({id:Date.now().toString(36),symbol,metric,direction,target,createdAt:Date.now()});
 if(!write(ALERTS_KEY,current)){if(status){status.textContent='ذخیره‌سازی در این دستگاه در دسترس نیست.';status.className='notice warn'}return}
 if(status){status.textContent='هشدار قیمت در همین دستگاه ذخیره شد.';status.className='notice ok'}
 const input=$('priceAlertTarget');if(input)input.value='';renderAlerts();
}
function renderAlerts(){
 const root=$('activePriceAlerts');if(!root)return;root.replaceChildren();
 const items=alerts();if(!items.length){const empty=document.createElement('p');empty.className='muted small';empty.textContent='هشدار فعالی ندارید.';root.append(empty);return}
 items.forEach(item=>{const row=document.createElement('div');row.className='setting-row';row.style.marginTop='7px';const label=document.createElement('span');label.textContent=item.symbol+' · '+(item.metric==='percent'?'تغییر ۲۴ساعته':'قیمت')+' '+(item.direction==='below'?'≤ ':'≥ ')+item.target;const remove=document.createElement('button');remove.type='button';remove.className='secondary';remove.textContent='حذف';remove.addEventListener('click',()=>{write(ALERTS_KEY,alerts().filter(x=>x.id!==item.id));renderAlerts()});row.append(label,remove);root.append(row)})
}
function init(){
 $('priceAlertAdd')?.addEventListener('click',addAlert);
 $('notificationPermission')?.addEventListener('click',async()=>{const status=$('notificationPermissionStatus');if(!('Notification'in window)){if(status)status.textContent='اعلان سیستمی در این مرورگر پشتیبانی نمی‌شود.';return}try{const result=await Notification.requestPermission();if(status)status.textContent=result==='granted'?'اعلان سیستمی فعال شد.':result==='denied'?'اجازه اعلان داده نشد؛ اعلان‌های داخل برنامه همچنان ثبت می‌شوند.':'درخواست اعلان تعیین تکلیف نشد.'}catch(_){if(status)status.textContent='فعال‌سازی اعلان سیستمی ممکن نشد.'}});
 $('notificationClearHistory')?.addEventListener('click',()=>{if(!window.confirm('تاریخچه اعلان‌ها از این دستگاه پاک شود؟'))return;write(HISTORY_KEY,[]);render()});
 window.addEventListener('digiarz:market-snapshot',evaluate);renderAlerts();render();
}
window.DigiArzNotifications={publish,render,renderAlerts};
if(typeof document!=='undefined'){if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init()}
})();