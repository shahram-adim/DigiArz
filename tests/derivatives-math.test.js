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
  assert.equal(M.isolatedLiquidationPrice('long','1','100','10','0.005','0.0004'),'90.488638648702996179');
  assert.equal(M.isolatedLiquidationPrice('short','1','100','10','0.005','0.0004'),'109.409190371991247265');
  assert.equal(M.isolatedLiquidationPrice('long','1','100','120','0.005','0.0004'),null);
});
test('cross margin defers equity and liquidation risk to the account-level engine',()=>{
  const r=M.riskSnapshot({side:'long',quantity:'1',entryPrice:'100',markPrice:'105',maintenanceRate:'0.005',marginMode:'cross'});
  assert.equal(r.equity,null);
  assert.equal(r.marginRatio,null);
  assert.equal(r.liquidationPrice,null);
  assert.equal(r.atRisk,null);
  assert.equal(r.riskScope,'account');
  assert.equal(r.liquidationPriceMethod,'account-level-cross-risk-engine');
});
test('risk snapshot rejects unknown margin modes',()=>{
  assert.throws(()=>M.riskSnapshot({side:'long',quantity:'1',entryPrice:'100',markPrice:'105',isolatedMargin:'20',maintenanceRate:'0.005',marginMode:'shared'}),/marginMode/);
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

test('aggregates cross futures risk across multiple positions and account liabilities',()=>{
  const r=M.crossMarginRiskSnapshot({
    cashBalanceUsdt:'1000',otherLiabilitiesUsdt:'20',accruedInterestUsdt:'2',fundingPayableUsdt:'3',unsettledFeesUsdt:'1',
    positions:[
      {productType:'futures',marginMode:'cross',side:'long',quantity:'1',entryPrice:'100',markPrice:'110',maintenanceRate:'0.01',closeFeeRate:'0.001',priceStatus:'fresh'},
      {productType:'futures',marginMode:'cross',side:'short',quantity:'2',entryPrice:'50',markPrice:'45',maintenanceRate:'0.02',closeFeeRate:'0.001',priceStatus:'fresh'}
    ]
  });
  assert.equal(r.unrealizedPnl,'20');
  assert.equal(r.maintenanceMargin,'2.9');
  assert.equal(r.closeFeeReserve,'0.2');
  assert.equal(r.totalLiabilities,'26');
  assert.equal(r.equity,'993.8');
  assert.equal(r.maintenanceBuffer,'990.9');
  assert.equal(r.atRisk,false);
  assert.equal(r.liquidationPrice,null);
  assert.equal(r.riskScope,'account');
});
test('cross futures risk flags account-level maintenance breach without a single liquidation price',()=>{
  const r=M.crossMarginRiskSnapshot({
    cashBalanceUsdt:'5',
    positions:[{productType:'futures',marginMode:'cross',side:'short',quantity:'1',entryPrice:'100',markPrice:'200',maintenanceRate:'0.1',closeFeeRate:'0.01',priceStatus:'fresh'}]
  });
  assert.equal(r.equity,'-97');
  assert.equal(r.maintenanceMargin,'20');
  assert.equal(r.riskStatus,'maintenance_breach');
  assert.equal(r.atRisk,true);
  assert.equal(r.liquidationPrice,null);
});
test('cross futures risk fails closed when any mark price is stale',()=>{
  const r=M.crossMarginRiskSnapshot({
    cashBalanceUsdt:'1000',
    positions:[{productType:'futures',marginMode:'cross',side:'long',quantity:'1',entryPrice:'100',markPrice:'101',maintenanceRate:'0.01',closeFeeRate:'0.001',priceStatus:'stale'}]
  });
  assert.equal(r.riskStatus,'stale_price');
  assert.equal(r.equity,null);
  assert.equal(r.atRisk,null);
});
test('cross futures risk rejects isolated or non-futures positions and negative liabilities',()=>{
  const p={productType:'futures',marginMode:'cross',side:'long',quantity:'1',entryPrice:'100',markPrice:'101',maintenanceRate:'0.01',closeFeeRate:'0.001',priceStatus:'fresh'};
  assert.throws(()=>M.crossMarginRiskSnapshot({cashBalanceUsdt:'100',positions:[{...p,marginMode:'isolated'}]}),/cross futures/);
  assert.throws(()=>M.crossMarginRiskSnapshot({cashBalanceUsdt:'100',positions:[{...p,productType:'margin'}]}),/cross futures/);
  assert.throws(()=>M.crossMarginRiskSnapshot({cashBalanceUsdt:'100',otherLiabilitiesUsdt:'-1',positions:[]}),/must not be negative/);
});

const maintenanceTiers=[
  {maxNotional:'10000',maintenanceRate:'0.01',maintenanceAmount:'0',maxLeverage:100},
  {maxNotional:'50000',maintenanceRate:'0.02',maintenanceAmount:'100',maxLeverage:50},
  {maxNotional:null,maintenanceRate:'0.05',maintenanceAmount:'1600',maxLeverage:25}
];
test('selects exact-decimal maintenance tiers with continuous boundaries and leverage caps',()=>{
  const first=M.maintenanceTierForNotional('10000',maintenanceTiers);
  assert.equal(first.tierIndex,0);
  assert.equal(first.maintenanceMargin,'100');
  assert.equal(first.maxLeverage,100);
  const second=M.maintenanceTierForNotional('10000.000000000000001',maintenanceTiers);
  assert.equal(second.tierIndex,1);
  assert.equal(second.maintenanceMargin,'100.00000000000000002');
  assert.equal(second.maxLeverage,50);
  const third=M.maintenanceTierForNotional('100000',maintenanceTiers);
  assert.equal(third.tierIndex,2);
  assert.equal(third.maintenanceMargin,'3400');
  assert.equal(third.maxLeverage,25);
  assert.equal(M.maintenanceMarginFromTiers('0.5','20000',maintenanceTiers),'100');
});
test('rejects malformed or unsafe maintenance tier schedules',()=>{
  assert.throws(()=>M.validateMaintenanceTiers([]),/non-empty/);
  assert.throws(()=>M.validateMaintenanceTiers([
    maintenanceTiers[0],{...maintenanceTiers[1],maintenanceAmount:'99'},maintenanceTiers[2]
  ]),/continuous/);
  assert.throws(()=>M.validateMaintenanceTiers([
    maintenanceTiers[0],{...maintenanceTiers[1],maintenanceRate:'0.009',maintenanceAmount:'-10'},maintenanceTiers[2]
  ]),/must not be negative|non-decreasing/);
  assert.throws(()=>M.validateMaintenanceTiers([
    maintenanceTiers[0],{...maintenanceTiers[1],maxLeverage:125},maintenanceTiers[2]
  ]),/must not increase/);
  assert.throws(()=>M.validateMaintenanceTiers([
    {...maintenanceTiers[0],maxNotional:null},maintenanceTiers[1],maintenanceTiers[2]
  ]),/only the final/);
  assert.throws(()=>M.validateMaintenanceTiers([
    maintenanceTiers[0],maintenanceTiers[1],{...maintenanceTiers[2],maxNotional:'100000'}
  ]),/final maintenance tier/);
});

test('solves tiered isolated liquidation using the tier at the candidate price',()=>{
  assert.equal(M.isolatedTieredLiquidationPrice('long','1','11000','5000',maintenanceTiers,'0.001'),'6066.734074823053589485');
  assert.equal(M.isolatedTieredLiquidationPrice('short','1','9000','5000',maintenanceTiers,'0.001'),'13809.990205680705190989');
  const r=M.riskSnapshot({
    side:'long',quantity:'1',entryPrice:'11000',markPrice:'10000',isolatedMargin:'5000',
    maintenanceTiers,closeFeeRate:'0.001'
  });
  assert.equal(r.maintenanceMargin,'100');
  assert.equal(r.maintenanceTierIndex,0);
  assert.equal(r.liquidationPrice,'6066.734074823053589485');
  assert.equal(r.liquidationPriceMethod,'isolated-tiered-estimate');
});
