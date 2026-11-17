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
    const qEntry=mul(q,entry);
    const qMargin=div(margin,q);
    if(side==='long'){
      const numerator=sub(entry,qMargin);
      if(D.compareDecimal(numerator,'0')<=0)return null;
      return div(numerator,sub(sub('1',mmr),fee));
    }
    return div(add(entry,qMargin),add(add('1',mmr),fee));
  }
  function riskSnapshot({side,quantity,entryPrice,markPrice,isolatedMargin,maintenanceRate,closeFeeRate='0',marginMode='isolated'}){
    const pnl=unrealizedPnl(side,quantity,entryPrice,markPrice);
    const equity=positionEquity(side,quantity,entryPrice,markPrice,isolatedMargin,closeFeeRate);
    const maintenance=maintenanceMargin(quantity,markPrice,maintenanceRate);
    const liquidationPrice=marginMode==='isolated'
      ? isolatedLiquidationPrice(side,quantity,entryPrice,isolatedMargin,maintenanceRate,closeFeeRate)
      : null;
    return Object.freeze({
      notional:notional(quantity,markPrice),
      unrealizedPnl:pnl,
      equity,
      maintenanceMargin:maintenance,
      marginRatio:D.compareDecimal(maintenance,'0')===0?null:div(equity,maintenance),
      liquidationPrice,
      liquidationPriceMethod:marginMode==='isolated'?'isolated-position-estimate':'account-level-cross-risk-engine',
      atRisk:D.compareDecimal(equity,maintenance)<=0
    });
  }
  return Object.freeze({notional,initialMargin,maintenanceMargin,unrealizedPnl,positionEquity,isolatedLiquidationPrice,riskSnapshot,validateLeverage});
});
