(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.DigiSubscriptionPlans=factory()})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const PLANS={
 free:{id:'free',name:'رایگان',badge:'شروع بدون هزینه',alertLimit:2,intervals:['1m','5m','15m','1h','24h','1d'],features:['rsi','macd','ema20','sma20','basicReport'],summary:'ابزارهای پایه برای یادگیری و تمرین'},
 pro:{id:'pro',name:'Pro',badge:'تحلیل‌گر حرفه‌ای',alertLimit:20,intervals:'all',features:['rsi','macd','ema20','ema50','sma20','bollinger','stochastic','atr','adx','advancedReport'],summary:'اندیکاتورهای کامل و هشدارهای بیشتر'},
 vip:{id:'vip',name:'VIP',badge:'تجربه کامل',alertLimit:100,intervals:'all',features:['rsi','macd','ema20','ema50','sma20','bollinger','stochastic','atr','adx','advancedReport','priorityAlerts','allTools'],summary:'تمام ابزارهای تحلیلی و سقف بالاتر هشدار'}
};
let activePlan='free';
function getPlan(){return PLANS[activePlan]||PLANS.free}
function canUse(feature){return getPlan().features.includes(feature)}
function canUseInterval(interval){return getPlan().intervals==='all'||getPlan().intervals.includes(String(interval))}
function alertLimit(){return getPlan().alertLimit}
function render(container){if(!container)return;const current=getPlan();container.innerHTML=Object.values(PLANS).map(p=>'<article class="da-plan-card '+(p.id===current.id?'is-current':'')+'"><div class="da-plan-card-top"><strong>'+p.name+'</strong><span>'+(p.id===current.id?'طرح فعلی':p.id==='free'?'فعال':'به‌زودی')+'</span></div><small>'+p.badge+'</small><p>'+p.summary+'</p><ul>'+ (p.id==='free'?'<li>RSI و MACD</li><li>EMA20 و SMA20</li><li>۲ هشدار فعال</li><li>بازه‌های زمانی منتخب</li>':p.id==='pro'?'<li>تمام اندیکاتورهای پیشرفته</li><li>۲۰ هشدار فعال</li><li>تمام بازه‌های زمانی</li><li>گزارش تحلیل پیشرفته</li>':'<li>تمام امکانات Pro</li><li>تا ۱۰۰ هشدار فعال</li><li>دسترسی کامل به ابزارها</li><li>اولویت امکانات ویژه</li>')+'</ul><button type="button" class="secondary" disabled>'+(p.id===current.id?'طرح فعال': 'پس از اتصال پرداخت فعال می‌شود')+'</button></article>').join('')}
return {plans:PLANS,getPlan,canUse,canUseInterval,alertLimit,render};
});
