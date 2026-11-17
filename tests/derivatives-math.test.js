'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const M=require('../src/derivatives-math.js');

test('computes notional and initial margin exactly',()=>{
  assert.equal(M.notional('0.125','64000'),'8000');
  assert.equal(M.initialMargin('0.125','64000',10,50),'800');
});
test('rejects invalid leverage, quantity, price and rates',()=>{
  assert.throws(()=>M.initialMargin('1','100',0,50),/Leverage/);
  assert.throws(()=>M.initialMargin('1','100',51,50),/Leverage/);
  assert.throws(()=>M.notional('0','100'),/positive/);
  assert.throws(()=>M.notional('1','-100'),/positive/);
  assert.throws(()=>M.maintenanceMargin('1','100','1'));
});
test('computes long and short unrealized PnL without floating point',()=>{
  assert.equal(M.unrealizedPnl('long','0.25','40000','42000'),'500');
  assert.equal(M.unrealizedPnl('short','0.25','40000','42000'),'-500');
  assert.equal(M.unrealizedPnl('short','0.25','40000','38000'),'500');
});
test('computes maintenance margin and position equity including close fee reserve',()=>{
  assert.equal(M.maintenanceMargin('0.5','40000','0.005'),'100');
  assert.equal(M.positionEquity('long','0.5','40000','41000','1000','0.0004'),'1491.8');
});
test('calculates isolated long and short liquidation estimates',()=>{
  assert.equal(M.isolatedLiquidationPrice('long','1','100','10','0.005','0.0004'),'90.488638648702995');
  assert.equal(M.isolatedLiquidationPrice('short','1','100','10','0.005','0.0004'),'109.40919037199124');
  assert.equal(M.isolatedLiquidationPrice('long','1','100','120','0.005','0.0004'),null);
});
test('cross margin does not present a misleading per-position liquidation price',()=>{
  const r=M.riskSnapshot({side:'long',quantity:'1',entryPrice:'100',markPrice:'105',isolatedMargin:'20',maintenanceRate:'0.005',closeFeeRate:'0.0004',marginMode:'cross'});
  assert.equal(r.liquidationPrice,null);
  assert.equal(r.liquidationPriceMethod,'account-level-cross-risk-engine');
});
test('risk snapshot identifies maintenance breach and calculates margin ratio',()=>{
  const r=M.riskSnapshot({side:'long',quantity:'1',entryPrice:'100',markPrice:'80',isolatedMargin:'10',maintenanceRate:'0.01',closeFeeRate:'0.001'});
  assert.equal(r.unrealizedPnl,'-20');
  assert.equal(r.equity,'-10.08');
  assert.equal(r.maintenanceMargin,'0.8');
  assert.equal(r.atRisk,true);
});
test('validates side and rate ranges',()=>{
  assert.throws(()=>M.unrealizedPnl('buy','1','100','110'),/side/);
  assert.throws(()=>M.isolatedLiquidationPrice('long','1','100','10','-0.1','0'),/positive/);
  assert.throws(()=>M.isolatedLiquidationPrice('long','1','100','10','0.005','-0.001'),/fee rate/);
  assert.throws(()=>M.positionEquity('long','1','100','100','10','-0.001'),/fee rate/);
});
