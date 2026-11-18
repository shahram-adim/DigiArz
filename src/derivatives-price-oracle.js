(function(root,factory){
  const api=factory(typeof module==='object'&&module.exports?require('./decimal.js'):root.DigiDecimal);
  if(typeof module==='object'&&module.exports)module.exports=api;
  if(root)root.DigiDerivativesPriceOracle=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(D){
  'use strict';
  if(!D)throw new Error('DigiDecimal must load before DigiDerivativesPriceOracle');
  const PROVIDERS=Object.freeze(['binance_usdm','bybit_linear','okx_swap']);
  const SYMBOL_RE=/^[A-Z0-9]{2,15}USDT$/;
  function positiveDecimal(value,name){
    if(typeof value!=='string')throw new TypeError(name+' must be a decimal string');
    const parsed=D.parseDecimal(value,{allowNegative:false,maxFractionDigits:18,maxIntegerDigits:24});
    if(D.compareDecimal(parsed,'0')<=0)throw new RangeError(name+' must be positive');
    return D.toString(parsed);
  }
  function nonNegativeBps(value,name){
    if(typeof value!=='string')throw new TypeError(name+' must be a decimal string');
    return D.toString(D.parseDecimal(value,{allowNegative:false,maxFractionDigits:8,maxIntegerDigits:6}));
  }
  function safeTimestamp(value,name){
    if(!Number.isSafeInteger(value)||value<0)throw new TypeError(name+' must be a non-negative safe integer');
    return value;
  }
  function validatePolicy(policy){
    if(!policy||typeof policy!=='object')throw new TypeError('policy is required');
    if(!Number.isSafeInteger(policy.minSources)||policy.minSources<2||policy.minSources>PROVIDERS.length)throw new RangeError('minSources must be between 2 and 3');
    for(const key of ['maxAgeMs','maxFutureSkewMs']){
      if(!Number.isSafeInteger(policy[key])||policy[key]<0)throw new RangeError(key+' must be a non-negative safe integer');
    }
    return {
      minSources:policy.minSources,maxAgeMs:policy.maxAgeMs,maxFutureSkewMs:policy.maxFutureSkewMs,
      maxMarkDeviationBps:nonNegativeBps(policy.maxMarkDeviationBps,'maxMarkDeviationBps'),
      maxIndexDeviationBps:nonNegativeBps(policy.maxIndexDeviationBps,'maxIndexDeviationBps'),
      maxMarkIndexDeviationBps:nonNegativeBps(policy.maxMarkIndexDeviationBps,'maxMarkIndexDeviationBps')
    };
  }
  function absoluteDifference(a,b){
    return D.compareDecimal(a,b)>=0?D.subtractDecimal(a,b,18):D.subtractDecimal(b,a,18);
  }
  function deviationBps(value,reference){
    return D.multiplyDecimal(D.divideDecimal(absoluteDifference(value,reference),reference,18,'down'),'10000',18);
  }
  function median(values){
    const sorted=values.slice().sort((a,b)=>D.compareDecimal(a,b));
    const middle=Math.floor(sorted.length/2);
    if(sorted.length%2===1)return sorted[middle];
    return D.divideDecimal(D.addDecimal(sorted[middle-1],sorted[middle],18),'2',18,'down');
  }
  function within(value,reference,limit){return D.compareDecimal(deviationBps(value,reference),limit)<=0}
  function empty(status,rejected){
    return Object.freeze({status,markPrice:null,indexPrice:null,sourceCount:0,sources:Object.freeze([]),
      asOfMs:null,expiresAtMs:null,rejected:Object.freeze(rejected.slice())});
  }
  // Pure consensus builder. A trusted collector supplies normalized provider data and receipt timestamps.
  function buildConsensusSnapshot({symbol,observations,nowMs,policy}){
    const p=validatePolicy(policy);
    safeTimestamp(nowMs,'nowMs');
    if(typeof symbol!=='string'||!SYMBOL_RE.test(symbol))throw new TypeError('symbol must be an uppercase USDT pair');
    if(!Array.isArray(observations))throw new TypeError('observations must be an array');
    const rejected=[],byProvider=new Map();
    for(const raw of observations){
      if(!raw||typeof raw!=='object'){rejected.push({provider:null,reason:'invalid_observation'});continue}
      const provider=raw.provider;
      if(!PROVIDERS.includes(provider)){rejected.push({provider:typeof provider==='string'?provider:null,reason:'unsupported_provider'});continue}
      if(raw.symbol!==symbol){rejected.push({provider,reason:'symbol_mismatch'});continue}
      let markPrice,indexPrice,sourceTimestampMs,receivedAtMs;
      try{
        markPrice=positiveDecimal(raw.markPrice,'markPrice');
        indexPrice=positiveDecimal(raw.indexPrice,'indexPrice');
        sourceTimestampMs=safeTimestamp(raw.sourceTimestampMs,'sourceTimestampMs');
        receivedAtMs=safeTimestamp(raw.receivedAtMs,'receivedAtMs');
      }catch(_){rejected.push({provider,reason:'invalid_fields'});continue}
      const candidate={provider,symbol,markPrice,indexPrice,sourceTimestampMs,receivedAtMs};
      const previous=byProvider.get(provider);
      if(!previous||candidate.sourceTimestampMs>previous.sourceTimestampMs||
        (candidate.sourceTimestampMs===previous.sourceTimestampMs&&candidate.receivedAtMs>previous.receivedAtMs)){
        if(previous)rejected.push({provider,reason:'duplicate_provider_superseded'});
        byProvider.set(provider,candidate);
      }else rejected.push({provider,reason:'duplicate_provider_ignored'});
    }
    const fresh=[];let staleCount=0;
    for(const observation of byProvider.values()){
      if(observation.sourceTimestampMs>nowMs+p.maxFutureSkewMs||
        observation.receivedAtMs>nowMs+p.maxFutureSkewMs||
        observation.sourceTimestampMs>observation.receivedAtMs+p.maxFutureSkewMs){
        rejected.push({provider:observation.provider,reason:'future_timestamp'});continue;
      }
      if(nowMs-observation.sourceTimestampMs>p.maxAgeMs||nowMs-observation.receivedAtMs>p.maxAgeMs){
        staleCount++;rejected.push({provider:observation.provider,reason:'stale'});continue;
      }
      if(!within(observation.markPrice,observation.indexPrice,p.maxMarkIndexDeviationBps)){
        rejected.push({provider:observation.provider,reason:'mark_index_basis_outlier'});continue;
      }
      fresh.push(observation);
    }
    if(fresh.length<p.minSources)return empty(staleCount>0&&fresh.length===0?'stale':'insufficient_quorum',rejected);
    const markMedian=median(fresh.map(o=>o.markPrice)),indexMedian=median(fresh.map(o=>o.indexPrice));
    const consensus=fresh.filter(o=>within(o.markPrice,markMedian,p.maxMarkDeviationBps)&&
      within(o.indexPrice,indexMedian,p.maxIndexDeviationBps));
    for(const observation of fresh)if(!consensus.includes(observation))
      rejected.push({provider:observation.provider,reason:'cross_source_deviation'});
    if(consensus.length<p.minSources)return empty('deviation',rejected);
    const markPrice=median(consensus.map(o=>o.markPrice)),indexPrice=median(consensus.map(o=>o.indexPrice));
    if(!within(markPrice,indexPrice,p.maxMarkIndexDeviationBps))
      return empty('deviation',rejected.concat([{provider:null,reason:'aggregate_mark_index_basis_outlier'}]));
    const asOfMs=Math.min(...consensus.map(o=>o.sourceTimestampMs));
    return Object.freeze({status:'healthy',markPrice,indexPrice,sourceCount:consensus.length,
      sources:Object.freeze(consensus.map(o=>o.provider).sort()),asOfMs,expiresAtMs:asOfMs+p.maxAgeMs,
      rejected:Object.freeze(rejected.slice())});
  }
  return Object.freeze({PROVIDERS,buildConsensusSnapshot});
});
