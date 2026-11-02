// Ingreso único: el rol lo define el correo.
const {chromium}=require('playwright');
const fake=`(function(){const R=window.__ROLES||[];window.__calls=[];
window.supabase={createClient:(u,k,o)=>{const key=o.auth.storageKey;const user={id:'u1',email:'x@y.com'};
 const q=t=>{const rows=t==='flota_usuarios'?(R.includes('central')?[{rol:'socio'}]:[]):t==='motoristas'?(R.includes('motorista')?[{id:'m'}]:[]):t==='tienda_miembros'?(R.includes('tienda')?[{tienda_id:'t'}]:[]):[];const c={then:(a,b)=>Promise.resolve({data:rows,error:null}).then(a,b)};['select','eq','limit'].forEach(m=>c[m]=()=>c);return c};
 return {from:q,auth:{signInWithPassword:async c=>{window.__calls.push('login');if(c.password==='mala1234')return {data:{},error:{message:'Invalid login credentials'}};localStorage.setItem(key,JSON.stringify({access_token:'a',refresh_token:'r',user}));return {data:{user,session:{}},error:null}},
  signUp:async c=>{window.__calls.push('signup');localStorage.setItem(key,JSON.stringify({access_token:'a',refresh_token:'r',user}));return {data:{user,session:{}},error:null}},signOut:async()=>{localStorage.removeItem(key);return {}},resetPasswordForEmail:async()=>({error:null})}}}}})();`;
async function caso(b,roles,{pass='clave1234',registro=false,pre=null}={}){const ctx=await b.newContext({viewport:{width:390,height:844}});const p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push(e.message));
 await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:'window.__ROLES='+JSON.stringify(roles)+';'+fake}));
 await p.route(/localhost:8765\/(central|motorista)?$/,r=>r.fulfill({contentType:'text/html',body:'<title>destino</title>'}));
 if(pre){await p.goto('http://localhost:8765/privacidad.html');await p.evaluate(([k,v])=>localStorage.setItem(k,v),pre)}
 await p.goto('http://localhost:8765/app.html');await p.waitForTimeout(800);
 if(!pre){if(registro)await p.click('#switchMode');await p.fill('#email','x@y.com');await p.fill('#password',pass);await p.click('#submit');await p.waitForTimeout(1200)}
 const url=new URL(p.url()).pathname;const enApp=url==='/app.html';const r={url,msg:enApp?await p.locator('#msg').innerText({timeout:800}).catch(()=>''):'',roles:enApp?await p.locator('.role b').allInnerTexts().catch(()=>[]):[],keys:await p.evaluate(()=>Object.keys(localStorage).filter(k=>k.startsWith('dyf-auth'))).catch(()=>[]),errs};
 if(r.roles.length){await p.locator('.role').nth(1).click();await p.waitForTimeout(800);r.tras=new URL(p.url()).pathname}
 await ctx.close();return r}
(async()=>{const b=await chromium.launch();let ok=0,n=0;const chk=(t,c,d)=>{n++;if(c)ok++;console.log(c?'OK   ':'FALLA',t,d?JSON.stringify(d).slice(0,200):'')};
 let r=await caso(b,['central']);chk('I1 correo de la Central abre /central',r.url==='/central'&&r.keys.includes('dyf-auth-central'),r);
 r=await caso(b,['motorista']);chk('I2 correo de motorista abre /motorista',r.url==='/motorista'&&r.keys.includes('dyf-auth-motorista'),r);
 r=await caso(b,['tienda']);chk('I3 correo de tienda abre la app Tienda',r.url==='/'&&r.keys.includes('dyf-auth-tienda'),r);
 r=await caso(b,[]);chk('I4 cuenta sin rol va a Tienda (se activa sola)',r.url==='/',r);
 r=await caso(b,[],{registro:true});chk('I5 «Crear cuenta» crea tienda con correo y contraseña',r.url==='/'&&r.keys.includes('dyf-auth-tienda'),r);
 r=await caso(b,['tienda','motorista']);chk('I6 dos roles: muestra elegir panel',r.roles.length===2&&r.tras==='/',r);
 r=await caso(b,['central'],{pass:'mala1234'});chk('I7 contraseña mala: mensaje claro, no sale',r.url==='/app.html'&&/incorrectos/.test(r.msg),r.msg);
 r=await caso(b,[],{pre:['dyf-auth-motorista',JSON.stringify({access_token:'a',refresh_token:'r'})]});chk('I8 con sesión abierta entra directo',r.url==='/motorista',r.url);
 chk('I9 sin errores JS',true);console.log(ok+'/'+n);await b.close()})();
