const test = require('node:test');
const assert = require('node:assert/strict');
const TA = require('../src/technical-analysis.js');
function candles(values){return values.map((close,i)=>({time:1700000000+i*60,open:close-.2,high:close+1,low:close-1,close,volume:10}))}
test('SMA and EMA return aligned series and expected final values',()=>{
 const v=[1,2,3,4,5];
 assert.deepEqual(TA.smaSeries(v,3),[null,null,2,3,4]);
 assert.equal(TA.emaSeries(v,3).length,5);
 assert.equal(TA.emaSeries(v,3)[2],2);
});
test('RSI handles rising, falling and insufficient history',()=>{
 assert.equal(TA.rsi([1,2,3,4,5],14),null);
 assert.equal(TA.rsi(Array.from({length:20},(_,i)=>i+1),14),100);
 assert.equal(TA.rsi(Array.from({length:20},(_,i)=>20-i),14),0);
});
test('MACD requires sufficient history and returns finite signal values',()=>{
 assert.equal(TA.macd(Array.from({length:20},(_,i)=>i+1)),null);
 const m=TA.macd(Array.from({length:80},(_,i)=>100+i+Math.sin(i)));
 assert.ok(m&&Number.isFinite(m.line)&&Number.isFinite(m.signal)&&Number.isFinite(m.histogram));
});
test('Bollinger bands contain the moving average',()=>{
 const b=TA.bollinger(Array.from({length:30},(_,i)=>100+Math.sin(i)),20,2);
 assert.ok(b.upper[29]>b.middle[29]);
 assert.ok(b.lower[29]<b.middle[29]);
});
test('stochastic and ATR stay within valid ranges',()=>{
 const c=candles(Array.from({length:30},(_,i)=>100+i*.5));
 assert.ok(TA.stochastic(c,14)>=0&&TA.stochastic(c,14)<=100);
 assert.ok(TA.atr(c,14)>0);
});
test('analyze returns chart-aligned overlays and indicator values',()=>{
 const c=candles(Array.from({length:100},(_,i)=>100+i*.3+Math.sin(i)));
 const a=TA.analyze(c);
 assert.ok(a.rsi!==null&&a.macd&&a.ema20!==null&&a.ema50!==null&&a.sma20!==null);
 assert.equal(a.series.ema20.length,81);
 assert.equal(a.series.ema50.length,51);
 assert.equal(a.series.bbUpper.length,81);
 assert.equal(a.series.bbLower.length,81);
});
