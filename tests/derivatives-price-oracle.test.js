'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const Oracle=require('../src/derivatives-price-oracle.js');
const now=1_800_000_000_000;
const policy={minSources:2,maxAgeMs:5000,maxFutureSkewMs:500,maxMarkDeviationBps:'50',maxIndexDeviationBps:'50',maxMarkIndexDeviationBps:'200'};
const obs=(provider,mark,index,offset=0,receivedOffset=0)=>({provider,symbol:'BTCUSDT',markPrice:mark,indexPrice:index,sourceTimestampMs:now+offset,receivedAtMs:now+receivedOffset});

test('builds exact median mark/index consensus from independent venues',()=>{
 const r=Oracle.buildConsensusSnapshot({symbol:'BTCUSDT',nowMs:now,policy,observations:[
  obs('binance_usdm','100.000000000000000001','99.500000000000000001'),
  obs('bybit_linear','100.200000000000000001','99.600000000000000001'),
  obs('okx_swap','100.100000000000000001','99.550000000000000001')]});
 assert.equal(r.status,'healthy');assert.equal(r.markPrice,'100.100000000000000001');
 assert.equal(r.indexPrice,'99.550000000000000001');assert.equal(r.sourceCount,3);
 assert.deepEqual(r.sources,['binance_usdm','bybit_linear','okx_swap']);assert.equal(r.asOfMs,now);assert.equal(r.expiresAtMs,now+5000);
});
test('rejects one extreme source and keeps the agreeing two-source quorum',()=>{
 const r=Oracle.buildConsensusSnapshot({symbol:'BTCUSDT',nowMs:now,policy,observations:[
  obs('binance_usdm','100','99.5'),obs('bybit_linear','100.1','99.6'),obs('okx_swap','120','119')]});
 assert.equal(r.status,'healthy');assert.equal(r.sourceCount,2);assert.deepEqual(r.sources,['binance_usdm','bybit_linear']);
 assert.ok(r.rejected.some(x=>x.provider==='okx_swap'&&x.reason==='cross_source_deviation'));
});
test('fails closed when two available venues disagree beyond configured deviation',()=>{
 const r=Oracle.buildConsensusSnapshot({symbol:'BTCUSDT',nowMs:now,policy,observations:[obs('binance_usdm','100','99.5'),obs('bybit_linear','105','104.5')]});
 assert.equal(r.status,'deviation');assert.equal(r.markPrice,null);assert.equal(r.sourceCount,0);
});
test('fails closed when source quorum is stale',()=>{
 const r=Oracle.buildConsensusSnapshot({symbol:'BTCUSDT',nowMs:now,policy,observations:[obs('binance_usdm','100','99.5',-6000),obs('bybit_linear','100','99.5',-7000)]});
 assert.equal(r.status,'stale');assert.equal(r.markPrice,null);assert.ok(r.rejected.every(x=>x.reason==='stale'));
});
test('rejects future-dated provider observations',()=>{
 const r=Oracle.buildConsensusSnapshot({symbol:'BTCUSDT',nowMs:now,policy,observations:[obs('binance_usdm','100','99.5',1000),obs('bybit_linear','100','99.5')]});
 assert.equal(r.status,'insufficient_quorum');assert.ok(r.rejected.some(x=>x.reason==='future_timestamp'));
});
test('duplicate rows from one provider cannot inflate quorum',()=>{
 const r=Oracle.buildConsensusSnapshot({symbol:'BTCUSDT',nowMs:now,policy,observations:[
  obs('binance_usdm','100','99.5'),obs('binance_usdm','100.01','99.51',1,1),obs('bybit_linear','100.02','99.52')]});
 assert.equal(r.status,'healthy');assert.equal(r.sourceCount,2);assert.ok(r.rejected.some(x=>x.reason==='duplicate_provider_superseded'));
});
test('rejects provider with its own mark/index basis outside configured bound',()=>{
 const r=Oracle.buildConsensusSnapshot({symbol:'BTCUSDT',nowMs:now,policy,observations:[
  obs('binance_usdm','100','99.9'),obs('bybit_linear','100','99.9'),obs('okx_swap','100','95')]});
 assert.equal(r.status,'healthy');assert.equal(r.sourceCount,2);
 assert.ok(r.rejected.some(x=>x.provider==='okx_swap'&&x.reason==='mark_index_basis_outlier'));
});
test('rejects unsupported providers, symbol mismatch and malformed decimals',()=>{
 const r=Oracle.buildConsensusSnapshot({symbol:'BTCUSDT',nowMs:now,policy,observations:[
  obs('unknown_exchange','100','99.5'),{...obs('binance_usdm','100','99.5'),symbol:'ETHUSDT'},
  {...obs('bybit_linear','100','99.5'),markPrice:100},obs('okx_swap','100','99.5')]});
 assert.equal(r.status,'insufficient_quorum');assert.deepEqual(r.sources,[]);
 assert.ok(r.rejected.some(x=>x.reason==='unsupported_provider'));assert.ok(r.rejected.some(x=>x.reason==='symbol_mismatch'));
 assert.ok(r.rejected.some(x=>x.reason==='invalid_fields'));
});
test('validates policy, symbol and collection contract',()=>{
 assert.throws(()=>Oracle.buildConsensusSnapshot({symbol:'BTCUSDT',observations:[],nowMs:now,policy:{...policy,minSources:1}}),/minSources/);
 assert.throws(()=>Oracle.buildConsensusSnapshot({symbol:'BTC/USD',observations:[],nowMs:now,policy}),/symbol/);
 assert.throws(()=>Oracle.buildConsensusSnapshot({symbol:'BTCUSDT',observations:{},nowMs:now,policy}),/array/);
});
