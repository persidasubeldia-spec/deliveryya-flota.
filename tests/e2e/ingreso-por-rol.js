// Cualquier puerta lleva la cuenta a su panel según su rol.
const {chromium}=require('playwright');
const fake=`(function(){const R=window.__ROLES||[];window.__rpc=[];
window.supabase={createClient:(u,k,o)=>{const key=o.auth.storageKey;const user={id:'u1',email:'x@y.com',user_metadata:{}};const sess=()=>{try{const s=localStorage.getItem(key);return s?JSON.parse(s):null}catch(e){return null}};
 const rows=t=>t==='flota_usuarios'?(R.includes('central')?[{rol:'socio',empresa_id:'e1',usuario_id:'u1',activo:true}]:[]):t==='motoristas'?(R.includes('motorista')?[{id:'m1',usuario_id:'u1',nombre:'Moto',activo:true}]:[]):t==='tienda_miembros'?(R.includes('tienda')?[{tienda_id:'t1',rol:'propietario'}]:[]):t==='tiendas'?(R.includes('tienda')?[{id:'t1',empresa_id:'e1',codigo:'T1',nombre_comercial:'Tienda Uno',telefono:'0981',direccion:'x',lat:-25,lng:-57}]:[]):[];
 const q=t=>{const c={then:(a,b)=>Promise.resolve({data:rows(t),error:null}).then(a,b)};['select','eq','limit','order','in','gte','lte','neq','is','not','range','ilike','or'].forEach(m=>c[m]=()=>c);c.single=()=>Promise.resolve({data:rows(t)[0]||null,error:null});c.maybeSingle=c.single;return c};
 return {from:q,auth:{getSession:async()=>({data:{session:sess()}}),getUser:async()=>({data:{user:sess()?user:null}}),signInWithPassword:async()=>{localStorage.setItem(key,JSON.stringify({access_token:'a',refresh_token:'r',user}));return {data:{user,session:{user}},error:null}},signUp:async()=>({data:{},error:null}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>{localStorage.removeItem(key);return {}},resetPasswordForEmail:async()=>({error:null}),resend:async()=>({error:null})},
  rpc:async(n)=>{window.__rpc.push(n);if(n==='flota_reclamar_propiedad')return {data:null,error:{message:'Correo no autorizado como propietario'}};if(n==='flota_solicitar_alta_tienda_simple')return {data:'T9',error:null};return {data:[],error:null}},
  channel:()=>{const ch={on:()=>ch,subscribe:()=>ch};return ch},removeChannel:()=>{}}}}})();`;
async function caso(b,pagina,roles,login){const ctx=await b.newContext({viewport:{width:390,height:844}});const p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push(e.message));p.on('dialog',d=>d.dismiss());
 await p.route(/maps\.googleapis/,r=>r.abort());
 await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:'window.__ROLES='+JSON.stringify(roles)+';'+fake}));
 for(const d of ['central','motorista'])await p.route(new RegExp('localhost:8765/'+d+'$'),r=>r.fulfill({contentType:'text/html',body:'<title>'+d+'</title>'}));
 await p.goto('http://localhost:8765/'+pagina);await p.waitForTimeout(1200);
 await p.fill(login.email,'x@y.com');await p.fill(login.pass,'clave1234');await p.click(login.btn);await p.waitForTimeout(2500);
 const r={url:new URL(p.url()).pathname,title:await p.title().catch(()=>''),keys:await p.evaluate(()=>Object.keys(localStorage).filter(k=>k.startsWith('dyf-auth'))).catch(()=>[]),rpc:await p.evaluate(()=>window.__rpc||[]).catch(()=>[]),errs};await ctx.close();return r}
(async()=>{const b=await chromium.launch();let ok=0,n=0;const chk=(t,c,d)=>{n++;if(c)ok++;console.log(c?'OK   ':'FALLA',t,d?JSON.stringify(d).slice(0,220):'')};
 const C={email:'#email',pass:'#password',btn:'#enter'},M={email:'#email',pass:'#password',btn:'#login'},T={email:'#loginEmail',pass:'#loginPassword',btn:'#loginForm button[type=submit]'};
 let r=await caso(b,'central.html',['motorista'],C);chk('R1 motorista entra por la Central → va a /motorista',r.url==='/motorista'&&r.keys.includes('dyf-auth')&&!r.keys.includes('dyf-auth-central'),r);
 r=await caso(b,'central.html',['tienda'],C);chk('R2 tienda entra por la Central → va a su tienda',r.url==='/'&&r.keys.includes('dyf-auth'),r);
 r=await caso(b,'central.html',[],C);chk('R3 cuenta nueva por la Central → va a Tienda (alta sola)',r.url==='/'&&r.keys.includes('dyf-auth'),r);
 r=await caso(b,'central.html',['central'],C);chk('R4 socio entra a la Central y se queda',r.url==='/central.html'&&r.keys.includes('dyf-auth'),r);
 r=await caso(b,'motorista.html',['tienda'],M);chk('R5 tienda entra por Motorista → va a su tienda',r.url==='/'&&r.keys.includes('dyf-auth'),r);
 r=await caso(b,'motorista.html',['central'],M);chk('R6 socio entra por Motorista → va a la Central',r.url==='/central',r);
 r=await caso(b,'index.html',['motorista'],T);chk('R7 motorista entra por Tienda → va a /motorista sin crear tienda',r.url==='/motorista'&&!r.rpc.includes('flota_solicitar_alta_tienda_simple'),r);
 r=await caso(b,'index.html',['central'],T);chk('R8 socio entra por Tienda → va a la Central',r.url==='/central',r);
 r=await caso(b,'index.html',[],T);chk('R9 cuenta nueva por Tienda → se activa sola y se queda',r.url==='/index.html'&&r.rpc.includes('flota_solicitar_alta_tienda_simple'),r);
 console.log(ok+'/'+n);await b.close()})();
