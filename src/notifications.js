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
  if(alert.metric==='percent'&&(row.change24h===null||row.change24h===undefined||!Number.isFinite(Number(row.change24h)))){remaining.push(alert);continue}
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

let orderChannel=null,orderChannelUserId=null;
const orderSnapshots=new Map();
function disconnectOrderEvents(){
 const channel=orderChannel;orderChannel=null;orderChannelUserId=null;
 if(channel&&window.__digiArzSupabaseClient?.removeChannel){
  try{window.__digiArzSupabaseClient.removeChannel(channel).catch(()=>{})}catch(_){}
 }
}
function orderLabel(row){
 const symbol=String(row?.symbol||'سفارش');
 const side=row?.side==='buy'?'خرید':'فروش';
 const kind=row?.order_type==='limit'?'Limit':row?.order_type==='conditional'?'سفارش شرطی':'Market';
 return symbol+' · '+side+' '+kind;
}
function handleOrderChange(payload,userId){
 const row=payload?.new,old=payload?.old||{};
 if(!row||row.user_id!==userId||!row.id)return;
 const label=orderLabel(row);
 if(payload.eventType==='INSERT'){
  orderSnapshots.set(row.id,{status:String(row.status||''),filled_amount:Number(row.filled_amount||0)});
  publish('order_created','سفارش آزمایشی ثبت شد',label+' با موفقیت در سرور ثبت شد.');
  return;
 }
 if(payload.eventType!=='UPDATE')return;
 const previousState=orderSnapshots.get(row.id)||old;
 const previous=String(previousState.status||''),next=String(row.status||'');
 const filledNow=Number(row.filled_amount||0),filledBefore=Number(previousState.filled_amount||0);
 orderSnapshots.set(row.id,{status:next,filled_amount:filledNow});
 if(next==='filled'&&previous!=='filled')publish('order_filled','سفارش آزمایشی تکمیل شد',label+' به‌طور کامل اجرا شد.');
 else if(next==='partially_filled'&&(previous!=='partially_filled'||filledNow>filledBefore))publish('order_partially_filled','بخشی از سفارش اجرا شد',label+' به‌صورت جزئی اجرا شد؛ مانده سفارش همچنان طبق وضعیت سرور پیگیری می‌شود.');
 else if(next==='cancelled'&&previous!=='cancelled')publish('order_cancelled','سفارش آزمایشی لغو شد',label+'؛ لغو از وضعیت ثبت‌شده در سرور دریافت شد.');
 else if(next==='rejected'&&previous!=='rejected')publish('order_rejected','سفارش آزمایشی رد شد',label+'؛ نتیجه از سرور دریافت شد.');
 else if(next==='triggered'&&previous!=='triggered')publish('order_triggered','شرط سفارش فعال شد',label+'؛ سفارش وارد مرحله بعدی اجرای سرور شد.');
}
function connectOrderEvents(client,userId){
 if(!client||!userId||typeof client.channel!=='function')return false;
 if(orderChannel&&orderChannelUserId===userId)return true;
 disconnectOrderEvents();
 window.__digiArzSupabaseClient=client;
 try{
  orderChannel=client.channel('digiarz-order-notifications-'+userId)
   .on('postgres_changes',{event:'*',schema:'public',table:'orders',filter:'user_id=eq.'+userId},payload=>handleOrderChange(payload,userId))
   .subscribe();
  orderChannelUserId=userId;
  return true;
 }catch(_){orderChannel=null;orderChannelUserId=null;return false}
}
function publishSecurityEvent(event){
 const events={
  SIGNED_IN:['security','ورود به حساب DigiArz','ورود جدید به حساب شما با موفقیت انجام شد.'],
  SIGNED_OUT:['security','خروج از حساب DigiArz','نشست این دستگاه از حساب خارج شد.'],
  PASSWORD_RECOVERY:['security','بازیابی رمز عبور','فرایند بازیابی رمز عبور برای این حساب آغاز شد.'],
  USER_UPDATED:['security','به‌روزرسانی امنیت حساب','اطلاعات امنیتی حساب از طریق سرویس احراز هویت به‌روزرسانی شد.']
 };
 const item=events[event];if(item)publish(item[0],item[1],item[2]);
}

window.DigiArzNotifications={publish,render,renderAlerts,connectOrderEvents,disconnectOrderEvents,publishSecurityEvent};
if(typeof document!=='undefined'){if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init()}
})();