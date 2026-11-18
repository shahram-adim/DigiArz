'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const M=require('../src/derivatives-math.js');

const basePosition={
  productType:'futures',marginMode:'cross',status:'open',symbol:'BTCUSDT',
  side:'long',quantity:'1',entryPrice:'100',markPrice:'110',priceStatus:'fresh',
  leverage:10,maintenanceRate:'0.01',closeFeeRate:'0.001'
};

test('calculates account equity and Available Margin with position and open limit reserves',()=>{
  const r=M.futuresAvailableMarginSnapshot({
    cashBalanceUsdt:'1000',
    positions:[basePosition],
    openOrders:[{
      productType:'futures',orderType:'limit',status:'pending',symbol:'ETHUSDT',
      positionSide:'long',remainingQuantity:'2',limitPrice:'100',leverage:5,
      reduceOnly:false,feeRate:'0.001'
    }]
  });
  assert.equal(r.unrealizedPnlUsdt,'10');
  assert.equal(r.closeFeeReserveUsdt,'0.11');
  assert.equal(r.equityUsdt,'1009.89');
  assert.equal(r.maintenanceMarginUsdt,'1.1');
  assert.equal(r.positionInitialMarginUsdt,'11');
  assert.equal(r.openOrderInitialMarginUsdt,'40');
  assert.equal(r.openOrderFeeReserveUsdt,'0.2');
  assert.equal(r.totalOpenOrderReservationUsdt,'40.2');
  assert.equal(r.availableMarginUsdt,'958.68');
  assert.equal(r.atRisk,false);
  assert.equal(r.liquidationPrice,null);
});

test('reserves only the remaining quantity of a partially filled limit order',()=>{
  const r=M.futuresAvailableMarginSnapshot({
    cashBalanceUsdt:'100',
    positions:[],
    openOrders:[{
      productType:'futures',orderType:'limit',status:'partially_filled',
      symbol:'BTCUSDT',positionSide:'short',remainingQuantity:'1.5',
      limitPrice:'100',leverage:5,reduceOnly:false,feeRate:'0.001'
    }]
  });
  assert.equal(r.openOrderInitialMarginUsdt,'30');
  assert.equal(r.openOrderFeeReserveUsdt,'0.15');
  assert.equal(r.availableMarginUsdt,'69.85');
});

test('reduce-only orders reserve position quantity but no opening margin or extra fee',()=>{
  const r=M.futuresAvailableMarginSnapshot({
    cashBalanceUsdt:'100',
    positions:[basePosition],
    openOrders:[{
      productType:'futures',orderType:'limit',status:'pending',symbol:'BTCUSDT',
      positionSide:'long',remainingQuantity:'0.6',limitPrice:'105',leverage:10,
      reduceOnly:true,feeRate:'0.01'
    },{
      productType:'futures',orderType:'limit',status:'partially_filled',symbol:'BTCUSDT',
      positionSide:'long',remainingQuantity:'0.4',limitPrice:'104',leverage:10,
      reduceOnly:true,feeRate:'0.01'
    }]
  });
  assert.equal(r.reduceOnlyReservedQuantity,'1');
  assert.equal(r.openOrderInitialMarginUsdt,'0');
  assert.equal(r.openOrderFeeReserveUsdt,'0');
  assert.equal(r.availableMarginUsdt,'98.89');
});

test('rejects aggregate reduce-only reservations larger than the open position',()=>{
  assert.throws(()=>M.futuresAvailableMarginSnapshot({
    cashBalanceUsdt:'100',
    positions:[basePosition],
    openOrders:[{
      productType:'futures',orderType:'limit',status:'pending',symbol:'BTCUSDT',
      positionSide:'long',remainingQuantity:'0.7',limitPrice:'105',leverage:10,
      reduceOnly:true,feeRate:'0.001'
    },{
      productType:'futures',orderType:'limit',status:'pending',symbol:'BTCUSDT',
      positionSide:'long',remainingQuantity:'0.4',limitPrice:'105',leverage:10,
      reduceOnly:true,feeRate:'0.001'
    }]
  }),/reduce-only orders exceed/);
});

test('fails closed when any open position has a stale mark price',()=>{
  const r=M.futuresAvailableMarginSnapshot({
    cashBalanceUsdt:'100',
    positions:[{...basePosition,priceStatus:'stale'}],
    openOrders:[]
  });
  assert.equal(r.riskStatus,'stale_price');
  assert.equal(r.equityUsdt,null);
  assert.equal(r.availableMarginUsdt,null);
  assert.equal(r.atRisk,null);
});

test('rejects active market orders because they must be atomic or rejected',()=>{
  assert.throws(()=>M.futuresAvailableMarginSnapshot({
    cashBalanceUsdt:'100',positions:[],
    openOrders:[{
      productType:'futures',orderType:'market',status:'pending',symbol:'BTCUSDT',
      positionSide:'long',remainingQuantity:'1',limitPrice:'100',leverage:5,
      reduceOnly:false,feeRate:'0.001'
    }]
  }),/market orders are forbidden/);
});

test('subtracts only explicitly unposted liabilities from equity',()=>{
  const r=M.futuresAvailableMarginSnapshot({
    cashBalanceUsdt:'100',unpostedLiabilitiesUsdt:'2',
    positions:[],openOrders:[]
  });
  assert.equal(r.unpostedLiabilitiesUsdt,'2');
  assert.equal(r.equityUsdt,'98');
  assert.equal(r.availableMarginUsdt,'98');
});

test('rounds collateral and fee reserves upward to avoid understating commitments',()=>{
  const r=M.futuresAvailableMarginSnapshot({
    cashBalanceUsdt:'1',
    positions:[],
    openOrders:[{
      productType:'futures',orderType:'limit',status:'pending',symbol:'BTCUSDT',
      positionSide:'long',remainingQuantity:'0.000000000000000001',
      limitPrice:'1.000000000000000001',leverage:3,
      reduceOnly:false,feeRate:'0.1'
    }]
  });
  assert.equal(r.openOrderInitialMarginUsdt,'0.000000000000000001');
  assert.equal(r.openOrderFeeReserveUsdt,'0.000000000000000001');
  assert.equal(r.availableMarginUsdt,'0.999999999999999998');
});

test('rejects isolated/non-Futures positions, invalid leverage and negative liabilities',()=>{
  assert.throws(()=>M.futuresAvailableMarginSnapshot({
    cashBalanceUsdt:'100',
    positions:[{...basePosition,marginMode:'isolated'}],openOrders:[]
  }),/cross Futures/);
  assert.throws(()=>M.futuresAvailableMarginSnapshot({
    cashBalanceUsdt:'100',
    positions:[{...basePosition,productType:'margin'}],openOrders:[]
  }),/cross Futures/);
  assert.throws(()=>M.futuresAvailableMarginSnapshot({
    cashBalanceUsdt:'100',
    positions:[{...basePosition,leverage:126}],openOrders:[]
  }),/Leverage/);
  assert.throws(()=>M.futuresAvailableMarginSnapshot({
    cashBalanceUsdt:'100',positions:[],openOrders:[],unpostedLiabilitiesUsdt:'-1'
  }),/must not be negative/);
});
