(function(root,factory){
  const api=factory(typeof module==='object'&&module.exports?require('./decimal.js'):root.DigiDecimal);
  if(typeof module==='object'&&module.exports)module.exports=api;
  if(root)root.DigiDerivativesMath=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(D){
  'use strict';
  if(!D)throw new Error('DigiDecimal must load before DigiDerivativesMath');
  const SCALE=18;
  const dec=(v)=>D.toString(D.parseDecimal(String(v),{allowNegative:true,maxFractionDigits:18,maxIntegerDigits:24}));
  const mul=(a,b)=>D.multiplyDecimal(dec(a),dec(b),SCALE);
  const add=(a,b)=>D.addDecimal(dec(a),dec(b),SCALE);
  const sub=(a,b)=>D.subtractDecimal(dec(a),dec(b),SCALE);
  const div=(a,b)=>D.divideDecimal(dec(a),dec(b),SCALE);
  const positive=(v,name)=>{const x=dec(v);if(D.compareDecimal(x,'0')<=0)throw new RangeError(name+' must be positive');return x};
  function validateLeverage(leverage,maxLeverage){
    if(!Number.isSafeInteger(leverage)||leverage<1||leverage>maxLeverage)throw new RangeError('Leverage is outside the allowed range');
    return leverage;
  }
  function notional(quantity,price){return mul(positive(quantity,'quantity'),positive(price,'price'))}
  function initialMargin(quantity,price,leverage,maxLeverage){
    validateLeverage(leverage,maxLeverage);
    return div(notional(quantity,price),String(leverage));
  }
  function maintenanceMargin(quantity,markPrice,maintenanceRate){
    const rate=positive(maintenanceRate,'maintenance rate');
    if(D.compareDecimal(rate,'1')>=0)throw new RangeError('Maintenance rate must be below 1');
    return mul(notional(quantity,markPrice),rate);
  }
  function unrealizedPnl(side,quantity,entryPrice,markPrice){
    if(side!=='long'&&side!=='short')throw new TypeError('side must be long or short');
    const q=positive(quantity,'quantity'),entry=positive(entryPrice,'entry price'),mark=positive(markPrice,'mark price');
    const move=sub(mark,entry);
    const pnl=mul(q,move);
    return side==='long'?pnl:sub('0',pnl);
  }
  function validateFeeRate(value){const rate=dec(value);if(D.compareDecimal(rate,'0')<0||D.compareDecimal(rate,'1')>=0)throw new RangeError('Invalid close fee rate');return rate}
  function positionEquity(side,quantity,entryPrice,markPrice,isolatedMargin,closeFeeRate){
    const margin=positive(isolatedMargin,'isolated margin');
    const feeRate=validateFeeRate(closeFeeRate);
    const pnl=unrealizedPnl(side,quantity,entryPrice,markPrice);
    const closeFee=mul(notional(quantity,markPrice),feeRate);
    return sub(add(margin,pnl),closeFee);
  }
  function isolatedLiquidationPrice(side,quantity,entryPrice,isolatedMargin,maintenanceRate,closeFeeRate){
    if(side!=='long'&&side!=='short')throw new TypeError('side must be long or short');
    const q=positive(quantity,'quantity'),entry=positive(entryPrice,'entry price'),margin=positive(isolatedMargin,'isolated margin');
    const mmr=positive(maintenanceRate,'maintenance rate'),fee=validateFeeRate(closeFeeRate);
    if(D.compareDecimal(mmr,'1')>=0||D.compareDecimal(add(mmr,fee),'1')>=0)throw new RangeError('Invalid maintenance or fee rate');
    const qMargin=div(margin,q);
    if(side==='long'){
      const numerator=sub(entry,qMargin);
      if(D.compareDecimal(numerator,'0')<=0)return null;
      return div(numerator,sub(sub('1',mmr),fee));
    }
    return div(add(entry,qMargin),add(add('1',mmr),fee));
  }

  // USDT-settled futures cross margin. cashBalanceUsdt must be a server-side,
  // ledger-derived settled balance, never a browser-provided value.
  function crossMarginRiskSnapshot({
    cashBalanceUsdt,
    positions,
    accruedInterestUsdt='0',
    fundingPayableUsdt='0',
    unsettledFeesUsdt='0',
    otherLiabilitiesUsdt='0'
  }){
    const cash=dec(cashBalanceUsdt);
    if(D.compareDecimal(cash,'0')<0)throw new RangeError('cash balance must not be negative');
    if(!Array.isArray(positions))throw new TypeError('positions must be an array');
    const liabilityInputs=[
      ['accrued interest',accruedInterestUsdt],
      ['funding payable',fundingPayableUsdt],
      ['unsettled fees',unsettledFeesUsdt],
      ['other liabilities',otherLiabilitiesUsdt]
    ];
    let liabilities='0';
    for(const [name,value] of liabilityInputs){
      const amount=dec(value);
      if(D.compareDecimal(amount,'0')<0)throw new RangeError(name+' must not be negative');
      liabilities=add(liabilities,amount);
    }
    for(const p of positions){
      if(!p||p.productType!=='futures'||p.marginMode!=='cross')throw new TypeError('cross margin aggregation accepts only cross futures positions');
      if(p.side!=='long'&&p.side!=='short')throw new TypeError('position side must be long or short');
      positive(p.quantity,'quantity');
      positive(p.entryPrice,'entry price');
      if(p.priceStatus!=='fresh')return Object.freeze({
        riskScope:'account',riskStatus:'stale_price',positionsCount:positions.length,
        equity:null,maintenanceMargin:null,closeFeeReserve:null,totalLiabilities:null,
        marginRatio:null,maintenanceBuffer:null,liquidationPrice:null,atRisk:null
      });
      positive(p.markPrice,'mark price');
      validateFeeRate(p.closeFeeRate);
    }
    let totalPnl='0',totalMaintenance='0',closeFeeReserve='0';
    for(const p of positions){
      totalPnl=add(totalPnl,unrealizedPnl(p.side,p.quantity,p.entryPrice,p.markPrice));
      totalMaintenance=add(totalMaintenance,maintenanceMargin(p.quantity,p.markPrice,p.maintenanceRate));
      closeFeeReserve=add(closeFeeReserve,mul(notional(p.quantity,p.markPrice),validateFeeRate(p.closeFeeRate)));
    }
    const equity=sub(add(cash,totalPnl),add(liabilities,closeFeeReserve));
    const hasExposure=D.compareDecimal(totalMaintenance,'0')>0;
    const buffer=sub(equity,totalMaintenance);
    const atRisk=hasExposure&&D.compareDecimal(equity,totalMaintenance)<=0;
    return Object.freeze({
      riskScope:'account',
      riskStatus:atRisk?'maintenance_breach':'healthy',
      positionsCount:positions.length,
      cashBalance:cash,
      unrealizedPnl:totalPnl,
      equity,
      maintenanceMargin:totalMaintenance,
      closeFeeReserve,
      totalLiabilities:liabilities,
      marginRatio:hasExposure?div(equity,totalMaintenance):null,
      maintenanceBuffer:buffer,
      liquidationPrice:null,
      liquidationPriceMethod:'account-level-no-single-price',
      atRisk
    });
  }

  // Conservative positive arithmetic: round required collateral and fee reserves UP
  // to the supported 18 decimal places so a preview never understates commitments.
  function ceilPositiveProduct(a,b){
    const x=D.parseDecimal(dec(a)),y=D.parseDecimal(dec(b));
    const coefficient=x.coefficient*y.coefficient,scale=x.scale+y.scale;
    if(scale<=SCALE)return D.toString({coefficient:coefficient*10n**BigInt(SCALE-scale),scale:SCALE});
    const divisor=10n**BigInt(scale-SCALE);
    let quotient=coefficient/divisor;
    if(coefficient%divisor!==0n)quotient+=1n;
    return D.toString({coefficient:quotient,scale:SCALE});
  }
  function ceilPositiveDivision(a,b){
    const x=D.parseDecimal(positive(a,'dividend')),y=D.parseDecimal(positive(b,'divisor'));
    const exponent=SCALE+y.scale-x.scale;
    let numerator=x.coefficient,denominator=y.coefficient;
    if(exponent>=0)numerator*=10n**BigInt(exponent);
    else denominator*=10n**BigInt(-exponent);
    let quotient=numerator/denominator;
    if(numerator%denominator!==0n)quotient+=1n;
    return D.toString({coefficient:quotient,scale:SCALE});
  }
  function validDerivativesSymbol(value){
    if(typeof value!=='string'||! /^[A-Z0-9]{2,15}USDT$/.test(value))throw new TypeError('invalid Futures symbol');
    return value;
  }
  function addTo(map,key,value){
    map.set(key,add(map.get(key)||'0',value));
  }

  // Account-level USDT Futures preview. Inputs must be server-derived snapshots:
  // cash from the immutable ledger, positions and active orders from PostgreSQL,
  // and fresh mark prices from the trusted server-side price source.
  // unpostedLiabilitiesUsdt MUST exclude fees/funding/interest already posted to
  // the ledger; otherwise the account would be charged twice.
  function futuresAvailableMarginSnapshot({
    cashBalanceUsdt,
    positions,
    openOrders,
    unpostedLiabilitiesUsdt='0',
    maxLeverage=125
  }){
    const cash=dec(cashBalanceUsdt);
    if(D.compareDecimal(cash,'0')<0)throw new RangeError('cash balance must not be negative');
    if(!Array.isArray(positions))throw new TypeError('positions must be an array');
    if(!Array.isArray(openOrders))throw new TypeError('openOrders must be an array');
    const liabilities=dec(unpostedLiabilitiesUsdt);
    if(D.compareDecimal(liabilities,'0')<0)throw new RangeError('unposted liabilities must not be negative');

    let totalPnl='0',positionInitial='0',maintenance='0',closeFeeReserve='0';
    let hasStaleMark=false;
    const positionQuantities=new Map();

    for(const p of positions){
      if(!p||p.productType!=='futures'||p.marginMode!=='cross')throw new TypeError('Available Margin accepts only cross Futures positions');
      if(p.status!==undefined&&p.status!=='open')throw new TypeError('positions must be open');
      if(p.side!=='long'&&p.side!=='short')throw new TypeError('position side must be long or short');
      const quantity=positive(p.quantity,'position quantity');
      const entry=positive(p.entryPrice,'entry price');
      validateLeverage(p.leverage,maxLeverage);
      const key=validDerivativesSymbol(p.symbol)+'|'+p.side;
      addTo(positionQuantities,key,quantity);
      if(p.priceStatus!=='fresh'){
        hasStaleMark=true;
        continue;
      }
      const mark=positive(p.markPrice,'mark price');
      const feeRate=validateFeeRate(p.closeFeeRate);
      totalPnl=add(totalPnl,unrealizedPnl(p.side,quantity,entry,mark));
      const positionNotional=ceilPositiveProduct(quantity,mark);
      positionInitial=add(positionInitial,ceilPositiveDivision(positionNotional,String(p.leverage)));
      const maintenanceRate=positive(p.maintenanceRate,'maintenance rate');
      if(D.compareDecimal(maintenanceRate,'1')>=0)throw new RangeError('maintenance rate must be below 1');
      maintenance=add(maintenance,ceilPositiveProduct(positionNotional,maintenanceRate));
      closeFeeReserve=add(closeFeeReserve,ceilPositiveProduct(positionNotional,feeRate));
    }

    let openOrderInitial='0',openOrderFees='0',reduceOnlyReservations='0';
    const reservedReduceOnly=new Map();
    const activeOrders=openOrders.filter(o=>o&&(o.status==='pending'||o.status==='partially_filled'));
    for(const o of activeOrders){
      if(o.productType!=='futures')throw new TypeError('Available Margin accepts only Futures orders');
      if(o.marginMode!=='cross')throw new TypeError('Available Margin accepts only cross Futures orders');
      if(o.orderType!=='limit')throw new TypeError('active market orders are forbidden; market orders must fill atomically or be rejected');
      if(o.positionSide!=='long'&&o.positionSide!=='short')throw new TypeError('order positionSide must be long or short');
      const remaining=positive(o.remainingQuantity,'remaining order quantity');
      const limitPrice=positive(o.limitPrice,'limit price');
      validateLeverage(o.leverage,maxLeverage);
      const feeRate=validateFeeRate(o.feeRate);
      if(o.reduceOnly){
        const key=validDerivativesSymbol(o.symbol)+'|'+o.positionSide;
        const totalPosition=positionQuantities.get(key)||'0';
        const alreadyReserved=reservedReduceOnly.get(key)||'0';
        const nextReserved=add(alreadyReserved,remaining);
        if(D.compareDecimal(nextReserved,totalPosition)>0)throw new RangeError('reduce-only orders exceed the available position quantity');
        reservedReduceOnly.set(key,nextReserved);
        reduceOnlyReservations=add(reduceOnlyReservations,remaining);
      }else{
        validDerivativesSymbol(o.symbol);
        const orderNotional=ceilPositiveProduct(remaining,limitPrice);
        openOrderInitial=add(openOrderInitial,ceilPositiveDivision(orderNotional,String(o.leverage)));
        openOrderFees=add(openOrderFees,ceilPositiveProduct(orderNotional,feeRate));
      }
    }

    if(hasStaleMark)return Object.freeze({
      riskScope:'account',riskStatus:'stale_price',positionsCount:positions.length,
      activeOrdersCount:activeOrders.length,walletCashUsdt:cash,
      unrealizedPnlUsdt:null,equityUsdt:null,maintenanceMarginUsdt:null,
      closeFeeReserveUsdt:null,positionInitialMarginUsdt:null,
      openOrderInitialMarginUsdt:openOrderInitial,openOrderFeeReserveUsdt:openOrderFees,
      reduceOnlyReservedQuantity:reduceOnlyReservations,totalOpenOrderReservationUsdt:null,
      availableMarginUsdt:null,maintenanceBufferUsdt:null,atRisk:null
    });

    const equity=sub(add(cash,totalPnl),add(liabilities,closeFeeReserve));
    const totalOpenReservation=add(openOrderInitial,openOrderFees);
    const available=sub(sub(sub(equity,positionInitial),openOrderInitial),openOrderFees);
    const hasExposure=D.compareDecimal(maintenance,'0')>0;
    const atRisk=hasExposure&&D.compareDecimal(equity,maintenance)<=0;
    return Object.freeze({
      riskScope:'account',
      riskStatus:atRisk?'maintenance_breach':'healthy',
      positionsCount:positions.length,
      activeOrdersCount:activeOrders.length,
      walletCashUsdt:cash,
      unrealizedPnlUsdt:totalPnl,
      unpostedLiabilitiesUsdt:liabilities,
      closeFeeReserveUsdt:closeFeeReserve,
      equityUsdt:equity,
      maintenanceMarginUsdt:maintenance,
      positionInitialMarginUsdt:positionInitial,
      openOrderInitialMarginUsdt:openOrderInitial,
      openOrderFeeReserveUsdt:openOrderFees,
      totalOpenOrderReservationUsdt:totalOpenReservation,
      reduceOnlyReservedQuantity:reduceOnlyReservations,
      availableMarginUsdt:available,
      maintenanceBufferUsdt:sub(equity,maintenance),
      marginRatio:hasExposure?div(equity,maintenance):null,
      liquidationPrice:null,
      liquidationPriceMethod:'account-level-no-single-price',
      atRisk
    });
  }

  function riskSnapshot({side,quantity,entryPrice,markPrice,isolatedMargin,maintenanceRate,closeFeeRate='0',marginMode='isolated'}){
    if(marginMode!=='isolated'&&marginMode!=='cross')throw new TypeError('marginMode must be isolated or cross');
    const pnl=unrealizedPnl(side,quantity,entryPrice,markPrice);
    const maintenance=maintenanceMargin(quantity,markPrice,maintenanceRate);
    if(marginMode==='cross'){
      return Object.freeze({
        notional:notional(quantity,markPrice),
        unrealizedPnl:pnl,
        equity:null,
        maintenanceMargin:maintenance,
        marginRatio:null,
        liquidationPrice:null,
        liquidationPriceMethod:'account-level-cross-risk-engine',
        riskScope:'account',
        atRisk:null
      });
    }
    const equity=positionEquity(side,quantity,entryPrice,markPrice,isolatedMargin,closeFeeRate);
    return Object.freeze({
      notional:notional(quantity,markPrice),
      unrealizedPnl:pnl,
      equity,
      maintenanceMargin:maintenance,
      marginRatio:D.compareDecimal(maintenance,'0')===0?null:div(equity,maintenance),
      liquidationPrice:isolatedLiquidationPrice(side,quantity,entryPrice,isolatedMargin,maintenanceRate,closeFeeRate),
      liquidationPriceMethod:'isolated-position-estimate',
      riskScope:'position',
      atRisk:D.compareDecimal(equity,maintenance)<=0
    });
  }
  return Object.freeze({notional,initialMargin,maintenanceMargin,unrealizedPnl,positionEquity,isolatedLiquidationPrice,riskSnapshot,crossMarginRiskSnapshot,futuresAvailableMarginSnapshot,validateLeverage});
});
