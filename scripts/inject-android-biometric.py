from pathlib import Path

path = Path("www/index.html")
html = path.read_text()

def once(old, new, label):
    global html
    count = html.count(old)
    if count != 1:
        raise SystemExit(f"Expected exactly one {label}, found {count}; refusing rewrite.")
    html = html.replace(old, new, 1)

once(
    '<script src="./src/decimal.js"></script>',
    '<script src="capacitor.js"></script>\n'
    '<script>window.__DIGIARZ_ANDROID_BUILD__=true;</script>\n'
    '<script src="./src/android-biometric-lock.js"></script>\n'
    '<script src="./src/decimal.js"></script>',
    "app script anchor"
)

login = '  <button id="forgotBtn" class="secondary" style="width:100%;margin-top:9px">بازیابی رمز عبور</button>'
once(login, login + '\n  <button id="unlockSessionBtn" type="button" class="secondary" style="width:100%;margin-top:9px" hidden>بازگشایی با اثر انگشت</button>', "login recovery button")

old_client = "function initClient(){if(!window.supabase?.createClient)throw new Error('کتابخانه اتصال بارگذاری نشد؛ اینترنت را بررسی کنید.');supabaseClient=window.supabase.createClient(SUPABASE_URL,SUPABASE_ANON_KEY,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}})}"
new_client = """let androidBiometricStorage=null,androidBiometricApp=null;
function initClient(){
 if(!window.supabase?.createClient)throw new Error('کتابخانه اتصال بارگذاری نشد؛ اینترنت را بررسی کنید.');
 if(window.__DIGIARZ_ANDROID_BUILD__===true){
  if(!window.Capacitor?.isNativePlatform?.()||!window.DigiArzAndroidBiometric)throw new Error('پل امن برنامه اندروید بارگذاری نشد؛ برای جلوگیری از ذخیره ناامن نشست، ورود متوقف شد.');
  if(!androidBiometricStorage){
   const nativePlugins=window.DigiArzAndroidBiometric.registerNativePlugins(window.Capacitor);
   androidBiometricApp=nativePlugins.app;
   androidBiometricStorage=window.DigiArzAndroidBiometric.createSecureStorage({
    plugin:nativePlugins.biometric,
    storageKey:'digiarz.auth.session.v1',
    secureKey:'digiarz.auth.session.v1',
    localStorage:window.localStorage,
    onState:(state,error)=>{
     const unlockButton=$('unlockSessionBtn');
     if(state==='saved'&&unlockButton)unlockButton.hidden=true;
     if(state==='memory-only'&&error)console.warn('DigiArz session is memory-only; no plaintext fallback was used:',error);
    }
   });
  }
  supabaseClient=window.supabase.createClient(SUPABASE_URL,SUPABASE_ANON_KEY,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true,skipAutoInitialize:true,storage:androidBiometricStorage,storageKey:'digiarz.auth.session.v1'}});
  const unlockButton=$('unlockSessionBtn');
  if(unlockButton&&!unlockButton.dataset.bound){
   unlockButton.addEventListener('click',()=>unlockSavedSession(false));
   unlockButton.dataset.bound='1';
  }
  androidBiometricStorage.hasSecureSession().then(saved=>{if(unlockButton)unlockButton.hidden=!saved;}).catch(()=>{if(unlockButton)unlockButton.hidden=true;});
  return;
 }
 supabaseClient=window.supabase.createClient(SUPABASE_URL,SUPABASE_ANON_KEY,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
}"""
once(old_client, new_client, "original initClient implementation")

listener_start = " // Register the auth listener before reading the session so recovery events are not missed.\n supabaseClient.auth.onAuthStateChange("
listener_end = "\n });\n let sessionData;"
if html.count(listener_start) != 1:
    raise SystemExit("Expected exactly one app Auth listener block.")
a = html.index(listener_start)
b = html.index(listener_end, a) + len("\n });")
block = html[a:b]
callback = block[len(" // Register the auth listener before reading the session so recovery events are not missed.\n supabaseClient.auth.onAuthStateChange("):-len("\n });")]
bind = "function bindAuthStateListener(){\n if(!supabaseClient)return;\n supabaseClient.auth.onAuthStateChange(" + callback + "\n );\n}\n"
html = html[:a] + " bindAuthStateListener();" + html[b:]

start = "async function start(){"
if html.count(start) != 1:
    raise SystemExit("Expected exactly one start() function.")
lifecycle = """async function unlockSavedSession(autoTriggered){
 const button=$('unlockSessionBtn');
 if(button)button.disabled=true;
 try{
  if(!androidBiometricStorage)throw new Error('ذخیره‌ساز امن اندروید آماده نیست.');
  await androidBiometricStorage.unlock();
  if(!supabaseClient){initClient();bindAuthStateListener();}
  await supabaseClient.auth.initialize();
  const result=await supabaseClient.auth.getSession();
  if(result.error)throw result.error;
  if(result.data?.session){
   await supabaseClient.auth.startAutoRefresh();
   if(button)button.hidden=true;
   await showApp(result.data.session);
  }else{
   if(button)button.hidden=!(await androidBiometricStorage.hasSecureSession());
   if(!autoTriggered)showMessage(authMsg,'نشست ذخیره‌شده باز نشد؛ می‌توانید با ایمیل و رمز عبور وارد شوید.','warn');
  }
 }catch(error){
  console.warn('DigiArz biometric unlock failed:',error);
  if(button)button.hidden=!(await androidBiometricStorage.hasSecureSession());
  showMessage(authMsg,'بازگشایی با اثر انگشت انجام نشد. می‌توانید با ایمیل و رمز عبور وارد شوید.','warn');
 }finally{if(button)button.disabled=false}
}
async function setupAndroidBiometricLifecycle(){
 if(!androidBiometricApp?.addListener)throw new Error('افزونه چرخه‌عمر اندروید در دسترس نیست.');
 await androidBiometricApp.addListener('appStateChange',async(state)=>{
  if(!state?.isActive){
   if(androidBiometricStorage?.isPromptInProgress())return;
   const client=supabaseClient;
   if(!client)return;
   try{
    await client.auth.stopAutoRefresh();
    try{await client.auth.getSession();}catch(refreshError){console.warn('Session check during app lock:',refreshError)}
    await androidBiometricStorage.flushWrites();
    await client.auth.dispose();
    if(supabaseClient===client)supabaseClient=null;
    androidBiometricStorage.lock();
    document.body.classList.add('auth-page-active');document.body.classList.remove('dashboard-page-active');
    appView.classList.add('hidden');appView.classList.remove('app-view-active');
    authView.classList.remove('hidden');
    const button=$('unlockSessionBtn');
    const saved=await androidBiometricStorage.hasSecureSession();
    if(button)button.hidden=!saved;
    if(saved)showMessage(authMsg,'برنامه قفل شد. برای ادامه، اثر انگشت را تأیید کنید.','warn');
   }catch(lockError){console.error('DigiArz app lock failed:',lockError);showMessage(authMsg,'قفل خودکار کامل نشد؛ برنامه را ببندید و دوباره باز کنید.','err')}
  }else if(!supabaseClient&&androidBiometricStorage?.isLocked()){
   await unlockSavedSession(true);
  }
 });
}
"""
html = html.replace(start, bind + lifecycle + start, 1)

boot_old = " initClient();\n window.DigiDailyAds?.init"
boot_new = " initClient();\n bindAuthStateListener();\n if(androidBiometricStorage){await supabaseClient.auth.initialize();await setupAndroidBiometricLifecycle()}\n window.DigiDailyAds?.init"
once(boot_old, boot_new, "app boot sequence")

path.write_text(html)
print("Injected native-only biometric storage, unlock button, and app lifecycle hooks into generated APK HTML.")
