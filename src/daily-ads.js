(() => {
 'use strict';
 let client=null,isAdmin=()=>false,notify=()=>{};
 const $=id=>document.getElementById(id);
 const bucket='daily-ad-images';
 function show(host,ad){
  if(!host)return;host.replaceChildren();host.classList.toggle('hidden',!ad);if(!ad)return;
  const media=document.createElement('div');media.className='daily-ad-media';
  const img=document.createElement('img');img.loading='lazy';img.decoding='async';img.alt=ad.title||'تصویر تبلیغ روزانه';
  img.src=client.storage.from(bucket).getPublicUrl(ad.image_path).data?.publicUrl||'';
  img.onerror=()=>host.classList.add('hidden');media.append(img);
  const copy=document.createElement('div');copy.className='daily-ad-copy';
  const label=document.createElement('span');label.className='daily-ad-kicker';label.textContent='تبلیغ روزانه';
  const title=document.createElement('h3');title.textContent=ad.title||'';
  const body=document.createElement('p');body.textContent=ad.body||'';
  copy.append(label,title,body);host.append(media,copy);
 }
 async function load(){
  if(!client)return null;
  const now=new Date().toISOString();
  const {data,error}=await client.from('daily_ads').select('id,title,body,image_path,starts_at,ends_at,is_active').eq('is_active',true).lte('starts_at',now).order('starts_at',{ascending:false}).limit(10);
  if(error)throw error;
  const ad=(data||[]).find(x=>!x.ends_at||new Date(x.ends_at).getTime()>Date.now())||null;
  show($('loginDailyAd'),ad);show($('dashboardDailyAd'),ad);return ad;
 }
 async function loadAdmin(){
  if(!client||!isAdmin())return;
  const host=$('adminDailyAdList');if(!host)return;
  host.textContent='در حال دریافت تبلیغ‌ها…';
  try{
   const {data,error}=await client.from('daily_ads').select('id,title,is_active,starts_at,ends_at').order('created_at',{ascending:false}).limit(30);
   if(error)throw error;host.replaceChildren();
   if(!data?.length){const empty=document.createElement('div');empty.className='muted small';empty.textContent='هنوز تبلیغی ثبت نشده است.';host.append(empty);return}
   for(const ad of data){
    const row=document.createElement('article');row.className='daily-ad-admin-item';
    const copy=document.createElement('div');copy.className='daily-ad-admin-copy';
    const title=document.createElement('strong');title.textContent=ad.title||'بدون عنوان';
    const meta=document.createElement('small');const expired=ad.ends_at&&new Date(ad.ends_at).getTime()<=Date.now();meta.textContent=(ad.is_active&&!expired?'فعال':'غیرفعال/منقضی')+' · پایان: '+(ad.ends_at?new Date(ad.ends_at).toLocaleString('fa-IR'):'—');copy.append(title,meta);
    const actions=document.createElement('div');actions.className='daily-ad-admin-actions';
    const toggle=document.createElement('button');toggle.type='button';toggle.className='secondary';toggle.dataset.dailyAdToggle=ad.id;toggle.dataset.nextActive=String(!ad.is_active);toggle.textContent=ad.is_active?'غیرفعال‌کردن':'فعال‌سازی';
    const del=document.createElement('button');del.type='button';del.className='danger';del.dataset.dailyAdDelete=ad.id;del.textContent='حذف';actions.append(toggle,del);row.append(copy,actions);host.append(row);
   }
  }catch(error){host.replaceChildren();notify('بارگذاری تبلیغ‌ها ناموفق بود: '+(error.message||String(error)),'err')}
 }
 async function save(){
  if(!isAdmin())return;const button=$('adminSaveDailyAdBtn');if(!button||button.disabled)return;
  const title=$('adminDailyAdTitle')?.value.trim(),body=$('adminDailyAdBody')?.value.trim(),file=$('adminDailyAdImage')?.files?.[0];
  if(!title||!body||!file){notify('عنوان، متن و تصویر را کامل کنید.','err');return}
  if(!['image/jpeg','image/png','image/webp'].includes(file.type)||file.size>3*1024*1024){notify('فقط تصویر JPG، PNG یا WebP تا ۳ مگابایت مجاز است.','err');return}
  button.disabled=true;let path=null;
  try{
   const ext=file.type==='image/png'?'png':file.type==='image/webp'?'webp':'jpg';
   const token=globalThis.crypto?.randomUUID?.()||Date.now()+'-'+Math.random().toString(36).slice(2);
   path='daily-ads/'+token+'.'+ext;
   const uploaded=await client.storage.from(bucket).upload(path,file,{contentType:file.type,upsert:false,cacheControl:'3600'});if(uploaded.error)throw uploaded.error;
   const starts=new Date(),ends=new Date(starts.getTime()+86400000);
   const inserted=await client.from('daily_ads').insert({title,body,image_path:path,is_active:true,starts_at:starts.toISOString(),ends_at:ends.toISOString()});if(inserted.error)throw inserted.error;
   $('adminDailyAdTitle').value='';$('adminDailyAdBody').value='';$('adminDailyAdImage').value='';
   notify('تبلیغ برای ۲۴ ساعت ثبت شد.','ok');await Promise.all([load(),loadAdmin()]);
  }catch(error){
   if(path){try{await client.storage.from(bucket).remove([path])}catch(cleanupError){console.warn('Daily ad image cleanup failed:',cleanupError)}}
   notify('ثبت تبلیغ ناموفق بود: '+(error.message||String(error)),'err');
  }finally{button.disabled=false}
 }
 async function toggle(button){
  if(!isAdmin()||!button)return;button.disabled=true;
  try{const {error}=await client.from('daily_ads').update({is_active:button.dataset.nextActive==='true',updated_at:new Date().toISOString()}).eq('id',button.dataset.dailyAdToggle);if(error)throw error;await Promise.all([load(),loadAdmin()])}
  catch(error){notify('تغییر وضعیت تبلیغ انجام نشد: '+(error.message||String(error)),'err');button.disabled=false}
 }
 async function remove(button){
  if(!isAdmin()||!button||!globalThis.confirm('این تبلیغ و تصویر آن حذف شود؟'))return;button.disabled=true;
  try{
   const {data,error:readError}=await client.from('daily_ads').select('image_path').eq('id',button.dataset.dailyAdDelete).maybeSingle();if(readError)throw readError;
   const {error}=await client.from('daily_ads').delete().eq('id',button.dataset.dailyAdDelete);if(error)throw error;
   if(data?.image_path){const result=await client.storage.from(bucket).remove([data.image_path]);if(result.error)console.warn('Daily ad image cleanup failed:',result.error)}
   await Promise.all([load(),loadAdmin()]);
  }catch(error){notify('حذف تبلیغ انجام نشد: '+(error.message||String(error)),'err');button.disabled=false}
 }
 function bind(){
  $('adminSaveDailyAdBtn')?.addEventListener('click',save);
  $('adminDailyAdRefreshBtn')?.addEventListener('click',loadAdmin);
  $('adminDailyAdList')?.addEventListener('click',event=>{const t=event.target.closest('[data-daily-ad-toggle]'),d=event.target.closest('[data-daily-ad-delete]');if(t)toggle(t);else if(d)remove(d)});
 }
 function init(options){
  client=options?.client||null;isAdmin=options?.isAdmin||(()=>false);notify=options?.notify||(()=>{});
  bind();load().catch(error=>{show($('loginDailyAd'),null);show($('dashboardDailyAd'),null);console.warn('DigiArz daily ad unavailable:',error)});
 }
 window.DigiDailyAds={init,load,loadAdmin};
})();
