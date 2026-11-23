'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const source=fs.readFileSync('src/notifications.js','utf8');
test('order lifecycle notifications are scoped to the authenticated user and server events',()=>{
 assert.match(source,/table:'orders',filter:'user_id=eq\.'\+userId/);
 assert.match(source,/payload\.eventType==='INSERT'/);
 for(const status of ['filled','partially_filled','cancelled','rejected','triggered'])assert.ok(source.includes("next==='"+status+"'"));
 assert.match(source,/row\.user_id!==userId/);
});
test('auth security events are limited to confirmed Supabase auth callbacks',()=>{
 for(const event of ['SIGNED_IN','SIGNED_OUT','PASSWORD_RECOVERY','USER_UPDATED'])assert.ok(source.includes(event));
});
test('order event handler emits only status transitions and incremental partial fills',()=>{
 const storage=new Map();
 const context={window:{},document:{getElementById:()=>null},localStorage:{getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,v)},Math,Date,JSON,Number,String,Array,Object,Set,Map,console};
 vm.runInNewContext(source,context);
 const api=context.window.DigiArzNotifications;
 const calls=[];
 const fakeClient={channel(name){const channel={on(type,filter,cb){calls.push({type,filter,cb});return channel},subscribe(){return channel}};return channel},removeChannel:async()=>{}};
 assert.equal(api.connectOrderEvents(fakeClient,'user-123'),true);
 assert.equal(calls[0].filter.filter,'user_id=eq.user-123');
 calls[0].cb({eventType:'INSERT',new:{id:'o1',user_id:'user-123',symbol:'BTCUSDT',side:'buy',order_type:'limit',status:'pending'}});
 calls[0].cb({eventType:'UPDATE',old:{id:'o1',user_id:'user-123',status:'pending',filled_amount:0},new:{id:'o1',user_id:'user-123',symbol:'BTCUSDT',side:'buy',order_type:'limit',status:'partially_filled',filled_amount:1}});
 calls[0].cb({eventType:'UPDATE',old:{id:'o1',user_id:'user-123',status:'partially_filled',filled_amount:1},new:{id:'o1',user_id:'user-123',symbol:'BTCUSDT',side:'buy',order_type:'limit',status:'filled',filled_amount:2}});
 calls[0].cb({eventType:'UPDATE',old:{id:'o2',user_id:'other',status:'pending'},new:{id:'o2',user_id:'other',symbol:'ETHUSDT',status:'filled'}});
 const items=JSON.parse(storage.get('digiArzNotificationHistoryV1'));
 assert.equal(items.length,3);
 assert.deepEqual(items.map(x=>x.type).sort(),['order_created','order_filled','order_partially_filled'].sort());
 api.publishSecurityEvent('SIGNED_IN');
 assert.equal(JSON.parse(storage.get('digiArzNotificationHistoryV1')).length,4);
});
