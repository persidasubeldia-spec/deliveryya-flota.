// Central: botón Editar en Motoristas corrige nombre, WhatsApp y correo.
const {chromium}=require('playwright');
const fake=`(function(){window.__rpc=[];const D=[{id:'m1',empresa_id:'e1',nombre:'Angel VILLALBA',telefono:'0982462467',email:'av495804@gmail.com',activo:true,usuario_id:null,porcentaje_empresa_pct:25},{id:'m2',empresa_id:'e1',nombre:'Freddy',telefono:'0972798907',email:'freddy@x.com',activo:true,usuario_id:'u9',porcentaje_empresa_pct:25}];
window.supabase={createClient:(u,k,o)=>{const key=o.auth.storageKey;const user={id:'u1',email:'jefe@x.com'};
 const rows=t=>t==='flota_usuarios'?[{rol:'propietario',empresa_id:'e1',usuario_id:'u1',activo:true,puede_motoristas:true}]:t==='motoristas'?D:[];
 const q=t=>{const c={then:(a,b)=>Promise.resolve({data:rows(t),error:null}).then(a,b)};['select','eq','limit','order','in','gte','lte','neq','is','not','range','ilike','or'].forEach(m=>c[m]=()=>c);c.single=()=>Promise.resolve({data:rows(t)[0]||null,error:null});c.maybeSingle=c.single;return c};
 return {from:q,auth:{getSession:async()=>({data:{session:{user,access_token:'a'}}}),getUser:async()=>({data:{user}}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>({})},
  rpc:async(n,a)=>{window.__rpc.push([n,a]);if(n==='flota_editar_motorista'){if(!/@/.test(a.p_correo))return {data:null,error:{message:'Revisá el correo electrónico'}};const d=D.find(x=>x.id===a.p_motorista);Object.assign(d,{nombre:a.p_nombre,telefono:a.p_telefono,email:a.p_correo});return {data:null,error:null}}return {data:[],error:null}},
  channel:()=>{const ch={on:()=>ch,subscribe:()=>ch};return ch},removeChannel:()=>{}}}}})();`;
(async()=>{const b=await chromium.launch();let ok=0,n=0;const chk=(t,c,d)=>{n++;if(c)ok++;console.log(c?'OK   ':'FALLA',t,d?JSON.stringify(d).slice(0,200):'')};
 for(const vp of [{width:1280,height:900},{width:390,height:844}]){
 const ctx=await b.newContext({viewport:vp,serviceWorkers:'block'});const p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push(e.message));p.on('dialog',d=>d.dismiss());
 await p.route(/maps\.googleapis|unpkg|leaflet/,r=>r.abort());await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fake}));
 await p.addInitScript(()=>localStorage.setItem('dyf-auth',JSON.stringify({access_token:'a',refresh_token:'r'})));
 await p.goto('http://localhost:8765/central.html');await p.waitForTimeout(1500);
 await p.evaluate(()=>page('Motoristas'));await p.waitForTimeout(400);const w=vp.width;
 chk(w+' M1 se ve el correo bajo el nombre',await p.locator('text=av495804@gmail.com').count()>0);
 chk(w+' M2 hay botón Editar en cada motorista',await p.locator('[data-driveredit]').count()===2);
 await p.click('[data-driveredit="m2"]');chk(w+' M3 vinculado: correo bloqueado',await p.locator('#dyME').isDisabled());await p.click('#dyMCancel');
 await p.click('[data-driveredit="m1"]');await p.fill('#dyME','sin-arroba');await p.click('#dyMSave');await p.waitForTimeout(300);
 chk(w+' M4 error claro y la ventana sigue abierta',/Revisá el correo/.test(await p.locator('#dyMMsg').innerText()));
 await p.fill('#dyMN','Angel Villalba');await p.fill('#dyME','Angel.Villalba@Gmail.com ');await p.click('#dyMSave');await p.waitForTimeout(600);
 const r=await p.evaluate(()=>({modal:!!document.getElementById('dyMotoModal'),rpc:window.__rpc.filter(x=>x[0]==='flota_editar_motorista').pop()?.[1]}));
 chk(w+' M5 guarda y cierra',!r.modal&&r.rpc.p_correo==='angel.villalba@gmail.com'&&r.rpc.p_nombre==='Angel Villalba',r.rpc);
 chk(w+' M6 la tabla muestra el dato nuevo',await p.locator('text=angel.villalba@gmail.com').count()>0&&await p.locator('text=Angel Villalba').count()>0);
 if(w<500){const bx=await p.locator('[data-driveredit="m1"]').boundingBox();chk(w+' M7 botón visible en celular',bx&&bx.x>=0&&bx.x+bx.width<=w,bx);await p.screenshot({path:'/tmp/claude-0/-home-claude/17f6e967-50a2-5a83-8608-c130999d8c94/scratchpad/moto-movil.png',fullPage:false})}
 chk(w+' M8 sin errores JS',!errs.length,errs);await ctx.close()}
 console.log(ok+'/'+n);await b.close()})();
