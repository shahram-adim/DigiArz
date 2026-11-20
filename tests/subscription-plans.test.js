const test = require('node:test');
const assert = require('node:assert/strict');
const Plans = require('../src/subscription-plans.js');

test('new accounts start on Free with a two-alert cap',()=>{
 assert.equal(Plans.getPlan().id,'free');
 assert.equal(Plans.alertLimit(),2);
 assert.ok(Plans.canUse('rsi'));
 assert.ok(Plans.canUse('macd'));
 assert.ok(Plans.canUse('ema20'));
 assert.ok(Plans.canUse('sma20'));
});

test('Free plan restricts premium indicators and longer timeframes',()=>{
 for(const feature of ['ema50','bollinger','stochastic','atr','adx','advancedReport']) assert.equal(Plans.canUse(feature),false);
 assert.equal(Plans.canUseInterval('1m'),true);
 assert.equal(Plans.canUseInterval('1d'),true);
 assert.equal(Plans.canUseInterval('1w'),false);
});

test('Pro and VIP definitions expose distinct higher service limits',()=>{
 assert.equal(Plans.plans.pro.alertLimit,20);
 assert.equal(Plans.plans.vip.alertLimit,100);
 assert.ok(Plans.plans.pro.features.includes('adx'));
 assert.ok(Plans.plans.vip.features.includes('priorityAlerts'));
 assert.equal(Plans.plans.pro.intervals,'all');
 assert.equal(Plans.plans.vip.intervals,'all');
});
