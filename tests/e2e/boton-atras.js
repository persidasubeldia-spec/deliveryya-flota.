// Botón ◁ Atrás del teléfono en Central, Tienda y Motorista.
const {chromium}=require('playwright');
const fake=`(function(){window.__rpc=[];
const pts=[[-25.33,-57.52],[-25.33,-57.52],[-25.32,-57.51],[-25.26,-57.60],[-25.25,-57.62],[-25.27,-57.61],[-25.40,-57.55],[-25.41,-57.57],[-25.39,-57.56]];
const DB={flota_usuarios:[{rol:'propietario',empresa_id:'e1',usuario_id:'u1',activo:true,puede_motoristas:true}],
 motoristas:[{id:'m1',empresa_id:'e1',nombre:'Edgar Daniel',telefono:'0986260417',activo:true,usuario_id:'x1',color_identificador:'#1765ba'},{id:'m2',empresa_id:'e1',nombre:'Freddy',telefono:'0972798907',activo:true,usuario_id:'x2',color_identificador:'#e8590c'},{id:'m3',empresa_id:'e1',nombre:'Repartidor Principal',telefono:'0982123456',activo:true,usuario_id:null}],
 tiendas:[{id:'t1',empresa_id:'e1',codigo:'T3',nombre_comercial:'Persa'}],rutas_generales:[],
 pedidos:pts.map((p,i)=>({id:'p'+i,empresa_id:'e1',tienda_id:'t1',nombre_cliente:'Cliente '+(i+1),telefono_cliente:'0981',direccion_cliente:'Dir '+i,lat:p[0],lng:p[1],estado:'pendiente',turno:'manana',motorista_id:null,ruta_general_id:null,numero_general:null,precio_mercaderia:100000,precio_delivery:25000,modalidad_pago:'pendiente',created_at:'2026-11-02T10:0'+i+':00Z',version_edicion:1})).concat([{id:'pt',empresa_id:'e1',tienda_id:'t1',nombre_cliente:'Cqroli',lat:-25.31,lng:-57.53,estado:'pendiente',turno:'tarde',motorista_id:null,ruta_general_id:null,numero_general:null,version_edicion:1,precio_mercaderia:0,precio_delivery:0,modalidad_pago:'pendiente',created_at:'2026-11-02T10:00:00Z'},{id:'px',empresa_id:'e1',tienda_id:'t1',nombre_cliente:'Sin GPS',lat:null,lng:null,estado:'pendiente',turno:'manana',motorista_id:null,ruta_general_id:null,numero_general:null,precio_mercaderia:0,precio_delivery:0,modalidad_pago:'pendiente',created_at:'2026-11-02T10:00:00Z'}])};
window.__DB=DB;
window.supabase={createClient:()=>{const user={id:'u1',email:'jefe@x.com'};
 const q=t=>{const c={then:(a,b)=>Promise.resolve({data:(DB[t]||[]).map(x=>({...x})),error:null,count:(DB[t]||[]).length}).then(a,b)};['select','eq','limit','order','in','gte','lte','neq','is','not','range','ilike','or','filter','match','gt','lt','contains'].forEach(m=>c[m]=()=>c);c.single=()=>Promise.resolve({data:(DB[t]||[])[0]||null,error:null});c.maybeSingle=c.single;c.insert=()=>c;c.update=()=>c;return c};
 return {from:q,auth:{getSession:async()=>({data:{session:{user,access_token:'a',refresh_token:'r'}}}),getUser:async()=>({data:{user}}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>({})},
  rpc:async(n,a)=>{window.__rpc.push([n,a]);
   if(n==='flota_crear_ruta_turno'){let r=DB.rutas_generales.find(r=>r.turno===a.p_turno);if(!r){r={id:'r1',empresa_id:'e1',fecha:a.p_fecha,turno:a.p_turno,estado:'abierta'};DB.rutas_generales.push(r)}return {data:r.id,error:null}}
   if(n==='admin_confirmar_ruta_optimizada'){a.p_orden_ids.forEach((id,i)=>{const o=DB.pedidos.find(x=>x.id===id);o.numero_general=i+1;o.ruta_general_id=a.p_ruta_general_id});DB.rutas_generales[0].estado='optimizada';return {data:null,error:null}}
   if(n==='flota_asignar_lote'){a.p_pedidos.forEach(id=>{DB.pedidos.find(x=>x.id===id).motorista_id=a.p_motorista});return {data:a.p_pedidos.length,error:null}}
   if(n==='flota_cambiar_turno_pedido'){const o=DB.pedidos.find(x=>x.id===a.p_pedido);o.turno=a.p_turno;return {data:null,error:null}}
   if(n==='editar_pedido_seguro'){const o=DB.pedidos.find(x=>x.id===a.p_pedido_id);if(o.version_edicion!=null&&a.p_version!==o.version_edicion)return {data:null,error:{message:'El pedido cambió'}};Object.assign(o,a.p_cambios);o.version_edicion=(o.version_edicion||1)+1;return {data:{...o},error:null}}
   if(n==='flota_leer_comision_general')return {data:25,error:null};
   return {data:[],error:null}},
  channel:()=>{const ch={on:()=>ch,subscribe:()=>ch};return ch},removeChannel:()=>{}}}}})();`;
const fakeMoto=`(function(){window.__P=[{id:'p1',nombre_cliente:'Odilda',telefono_cliente:'0981',direccion_cliente:'Casa',lat:-25.38,lng:-57.38,numero_general:3,turno:'manana',precio_mercaderia:120000,precio_delivery:25000,modalidad_pago:'pendiente',estado:'pendiente',version_edicion:1,updated_at:new Date().toISOString(),producto:'Blusa',observaciones:''}];
window.supabase={createClient:()=>{const user={id:'x2',email:'freddy@x.com'};
 const rows=t=>t==='motoristas'?[{id:'m2',empresa_id:'e1',usuario_id:'x2',nombre:'Freddy',telefono:'0972',activo:true}]:t==='pedidos'?window.__P.map(x=>({...x})):[];
 const q=t=>{const c={then:(a,b)=>Promise.resolve({data:rows(t),error:null}).then(a,b)};['select','eq','limit','order','in','gte','lte','neq','is','not','range','or','filter','match'].forEach(m=>c[m]=()=>c);c.single=()=>Promise.resolve({data:rows(t)[0]||null,error:null});c.maybeSingle=c.single;return c};
 return {from:q,auth:{getSession:async()=>({data:{session:{user,access_token:'a',refresh_token:'r'}}}),getUser:async()=>({data:{user}}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>({})},rpc:async()=>({data:[],error:null}),channel:()=>{const ch={on:()=>ch,subscribe:()=>ch};return ch},removeChannel:()=>{}}}}})();`;
const fakeT=`(function(){window.__ins=[];
window.supabase={createClient:(u,k,o)=>{const user={id:'u1',email:'t@x.com'};
 const rows=t=>t==='tienda_miembros'?[{tienda_id:'t1',rol:'propietario'}]:t==='tiendas'?[{id:'t1',empresa_id:'e1',codigo:'T3',nombre_comercial:'Persa Boutique',telefono:'0981',direccion:'x',lat:-25,lng:-57}]:[];
 const q=t=>{let ins=null;const c={then:(a,b)=>Promise.resolve({data:rows(t),error:null}).then(a,b)};['select','eq','limit','order','in','gte','lte','neq','is','not','range','ilike','or'].forEach(m=>c[m]=()=>c);
  c.insert=p=>{ins=p;window.__ins.push([t,p]);return c};c.single=()=>Promise.resolve(ins?{data:{id:'p'+window.__ins.length,created_at:new Date().toISOString()},error:null}:{data:rows(t)[0]||null,error:null});c.maybeSingle=c.single;return c};
 return {from:q,auth:{getSession:async()=>({data:{session:{user,access_token:'a',refresh_token:'r'}}}),getUser:async()=>({data:{user}}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>({})},
  rpc:async()=>({data:[],error:null}),channel:()=>{const ch={on:()=>ch,subscribe:()=>ch};return ch},removeChannel:()=>{}}}}})();`;
const atras=async p=>{await p.evaluate(()=>history.back());await p.waitForTimeout(350)};
(async()=>{const b=await chromium.launch();let ok=0,n=0;const chk=(t,c,d)=>{n++;if(c)ok++;console.log(c?'OK   ':'FALLA',t,d!==undefined?JSON.stringify(d).slice(0,200):'')};const errs=[];
 const abrir=async(url,fk)=>{const ctx=await b.newContext({viewport:{width:390,height:844},serviceWorkers:'block'});const p=await ctx.newPage();p.on('pageerror',e=>errs.push(e.message));p.on('dialog',d=>d.accept());
  await p.route(/maps\.googleapis|maps\.gstatic/,r=>r.abort());await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fk}));
  await p.addInitScript(()=>localStorage.setItem('dyf-auth',JSON.stringify({access_token:'a',refresh_token:'r'})));await p.goto(url);await p.waitForTimeout(1800);return [ctx,p]};
 // ---- Central ----
 let [ctx,p]=await abrir('http://localhost:8765/central.html',fake);
 const h2=()=>p.evaluate(()=>document.querySelector('#content h2')?.textContent||'');
 await p.evaluate(()=>page('Rutas'));await p.waitForTimeout(300);await p.evaluate(()=>page('Pedidos'));await p.waitForTimeout(300);
 await atras(p);chk('C1 Pedidos → ◁ → Rutas',/Rutas/.test(await h2()),await h2());
 await atras(p);chk('C2 Rutas → ◁ → Inicio',/Inicio|operaciones/i.test(await h2()),await h2());
 await p.evaluate(()=>page('Pedidos'));await p.waitForTimeout(300);await p.click('#orderResults [data-order]');await p.waitForTimeout(200);
 await atras(p);chk('C3 con el detalle abierto, ◁ lo cierra y sigue en Pedidos',(await p.locator('#orderDetail').isHidden())&&/Pedidos/.test(await h2()));
 await p.click('#orderResults [data-order]');await p.click('#orderDetail [data-dyedit]');await p.waitForTimeout(200);
 await atras(p);chk('C4 ◁ cierra "Editar pedido"',await p.locator('#dyEdit').count()===0&&/Pedidos/.test(await h2()));
 await atras(p);await atras(p);chk('C5 llegando a Inicio',/Inicio|operaciones/i.test(await h2()),await h2());
 await atras(p);chk('C6 en Inicio, ◁ avisa "otra vez para salir" y no se cierra',/otra vez para salir/.test(await p.locator('#dyAtrasAviso').innerText().catch(()=>''))&&/Inicio|operaciones/i.test(await h2()));
 await p.waitForTimeout(2800);chk('C7 después del aviso vuelve a proteger la salida',await p.evaluate(()=>!!(history.state&&history.state.g)));
 await p.evaluate(()=>page('Rutas'));await p.waitForTimeout(300);await p.reload();await p.waitForTimeout(2200);
 chk('C8 al volver a abrir, recuerda la última pantalla (Rutas)',/Rutas/.test(await h2()),await h2());
 await ctx.close();
 // ---- Tienda ----
 [ctx,p]=await abrir('http://localhost:8765/index.html',fakeT);
 const vis=()=>p.evaluate(()=>[...document.querySelectorAll('section.screen')].find(x=>!x.classList.contains('hide'))?.id);
 await p.evaluate(()=>dyGo('nuevo'));await p.waitForTimeout(200);await p.evaluate(()=>dyGo('pedidos'));await p.waitForTimeout(200);
 await atras(p);chk('T1 Mis pedidos → ◁ → Nuevo pedido',await vis()==='nuevo',await vis());
 await atras(p);chk('T2 Nuevo pedido → ◁ → Inicio',await vis()==='inicio',await vis());
 await atras(p);chk('T3 en Inicio, ◁ avisa para salir',/otra vez para salir/.test(await p.locator('#dyAtrasAviso').innerText().catch(()=>''))&&await vis()==='inicio');
 await ctx.close();
 // ---- Motorista ----
 [ctx,p]=await abrir('http://localhost:8765/motorista.html',fakeMoto);
 const tab=()=>p.evaluate(()=>[...document.querySelectorAll('[data-tab]')].find(e=>e.tagName!=='BUTTON')?.dataset.tab);
 await p.click('.dy-nav [data-tab="caja"]');await p.waitForTimeout(200);await p.click('.dy-nav [data-tab="ajustes"]');await p.waitForTimeout(200);
 await atras(p);chk('M1 Ajustes → ◁ → Caja',await tab()==='caja',await tab());
 await atras(p);chk('M2 Caja → ◁ → Entregas',await tab()==='entregas',await tab());
 await p.locator('[data-complete]').first().click();await p.waitForTimeout(300);chk('M3 se abrió la hoja "Entregado"',await p.locator('.dy-ov').count()===1);
 await atras(p);chk('M4 ◁ cierra la hoja y sigue en Entregas',await p.locator('.dy-ov').count()===0&&await tab()==='entregas');
 await atras(p);chk('M5 en Entregas, ◁ avisa para salir',/otra vez para salir/.test(await p.locator('#dyAtrasAviso').innerText().catch(()=>'')));
 chk('X sin errores JS',!errs.length,errs);console.log(ok+'/'+n);await b.close()})();
