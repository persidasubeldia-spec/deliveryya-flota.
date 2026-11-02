// Tienda nueva sin aprobación: cuenta sin tienda → se activa sola → abre "Mi tienda" para completar datos.
const {chromium}=require('playwright');
const fake=`(function(){window.__rpc=[];let tienda=null,sess=null;
const user={id:'u9',email:'nueva@ejemplo.com',user_metadata:window.__META||{}};
function q(t){let filtros={};const c={};const rows=()=>t==='tiendas'?(tienda?[tienda]:[]):t==='tienda_miembros'?(tienda?[{tienda_id:'t9',rol:'propietario'}]:[]):[];
 c.then=(r,j)=>Promise.resolve({data:rows(),error:null}).then(r,j);for(const m of ['select','eq','order','limit','gte','lte','in','neq','is','not','range'])c[m]=()=>c;c.single=()=>Promise.resolve({data:rows()[0]||null,error:null});c.maybeSingle=c.single;return c}
const client={auth:{getSession:async()=>({data:{session:sess}}),getUser:async()=>({data:{user:sess?user:null}}),signInWithPassword:async()=>{sess={user};return {data:{session:sess},error:null}},signUp:async()=>{sess={user};return {data:{session:sess,user},error:null}},onAuthStateChange:(cb)=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>({error:null}),resend:async()=>({error:null}),resetPasswordForEmail:async()=>({error:null})},from:q,
 rpc:async(n,a)=>{window.__rpc.push([n,a]);if(n==='flota_solicitar_alta_tienda_simple'){if(window.__ALTA_ERR)return {data:null,error:{message:window.__ALTA_ERR}};tienda={id:'t9',empresa_id:'e1',codigo:'T9',nombre_comercial:'Tienda T9',responsable:'nueva',telefono:'Pendiente de completar',direccion:'Pendiente de completar',lat:null,lng:null};return {data:'T9',error:null}}
  if(n==='tienda_actualizar_configuracion_gps'){Object.assign(tienda,{nombre_comercial:a.p_nombre,telefono:a.p_telefono,direccion:a.p_direccion});return {data:null,error:null}}
  if(n==='listar_empleadas_tienda')return {data:[],error:null};return {data:[],error:null}},
 channel:()=>{const ch={on:()=>ch,subscribe:()=>ch};return ch},removeChannel:()=>{}};
window.supabase={createClient:()=>client}})();`;
async function caso(b,nombre,{meta,altaErr,registro}={}){const ctx=await b.newContext({viewport:{width:390,height:844}});const p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push(e.message));p.on('dialog',d=>d.dismiss());
 await p.route(/maps\.googleapis/,r=>r.abort());
 await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:(meta?'window.__META='+JSON.stringify(meta)+';':'')+(altaErr?'window.__ALTA_ERR='+JSON.stringify(altaErr)+';':'')+fake}));
 await p.goto('http://localhost:8765/index.html');await p.waitForTimeout(1200);
 if(registro){await p.click('#registerOpenBtn');await p.fill('#registerStore','Boutique Sol');await p.fill('#registerPhone','0981555444');await p.fill('#registerAddress','Capiatá centro');}
 await p.fill('#loginEmail','nueva@ejemplo.com');await p.fill('#loginPassword','clave1234');
 await p.click(registro?'#registerSubmitBtn':'#loginForm button[type=submit]');await p.waitForTimeout(2500);
 const r={rpc:await p.evaluate(()=>window.__rpc.map(x=>x[0])),onb:await p.locator('#dyOnb').count()?await p.locator('#dyOnb').innerText():null,configVisible:await p.locator('#config').isVisible().catch(()=>false),nombre:await p.inputValue('#storeName').catch(()=>''),msg:await p.locator('#authMessage').innerText().catch(()=>''),errs};
 await p.screenshot({path:__dirname+'/../shots/tienda-autoalta-'+nombre+'.png'});await ctx.close();return r}
(async()=>{const b=await chromium.launch();let ok=0,tot=0;const chk=(n,c,d)=>{tot++;if(c)ok++;console.log((c?'OK   ':'FALLA'),n,d?JSON.stringify(d).slice(0,220):'')};
 let r=await caso(b,'login');
 chk('T1 cuenta sin tienda se activa sola',r.rpc.includes('flota_solicitar_alta_tienda_simple'),r.rpc);
 chk('T2 abre Mi tienda con panel de bienvenida',r.configVisible&&/ya está activa/.test(r.onb||''),r.onb);
 chk('T3 pide nombre, WhatsApp, dirección y GPS',/nombre comercial.*WhatsApp.*dirección.*GPS/.test(r.onb||''));
 chk('T4 campos de relleno vacíos',r.nombre==='',r.nombre);
 chk('T5 sin errores JS',!r.errs.length,r.errs);
 r=await caso(b,'registro',{registro:true,meta:{store_name:'Boutique Sol',store_phone:'0981555444',store_address:'Capiatá centro'}});
 chk('T6 registro con datos: se guardan solos',r.rpc.includes('tienda_actualizar_configuracion_gps')&&r.nombre==='Boutique Sol',[r.rpc,r.nombre]);
 chk('T7 solo falta GPS',/ubicación GPS/.test(r.onb||'')&&!/nombre comercial/.test(r.onb||''),r.onb);
 r=await caso(b,'otro-rol',{altaErr:'Esta cuenta pertenece a otro rol. Ingresá por el acceso correspondiente'});
 chk('T8 correo de Central/Moto: mensaje claro',/otro correo/.test(r.msg),r.msg);
 console.log(ok+'/'+tot);await b.close()})();
