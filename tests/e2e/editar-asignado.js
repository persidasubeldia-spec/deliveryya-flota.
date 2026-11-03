// Central edita un pedido YA ASIGNADO (precio, cobro, nota) y el motorista ve el aviso.
const {chromium}=require('playwright');const SHOT='/tmp/claude-0/-home-claude/17f6e967-50a2-5a83-8608-c130999d8c94/scratchpad/';
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
(async()=>{const b=await chromium.launch();let ok=0,n=0;const chk=(t,c,d)=>{n++;if(c)ok++;console.log(c?'OK   ':'FALLA',t,d!==undefined?JSON.stringify(d).slice(0,260):'')};const errs=[];
 // --- Central ---
 let ctx=await b.newContext({viewport:{width:390,height:844},deviceScaleFactor:2,serviceWorkers:'block',geolocation:{latitude:-25.335,longitude:-57.54},permissions:['geolocation']});let p=await ctx.newPage();p.on('pageerror',e=>errs.push(e.message));p.on('dialog',d=>d.accept());
 await p.route(/maps\.googleapis|maps\.gstatic/,r=>r.abort());await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fake}));
 await p.addInitScript(()=>{localStorage.setItem('dyf-auth',JSON.stringify({access_token:'a',refresh_token:'r'}));window.__abiertos=[];window.open=u=>{window.__abiertos.push(String(u));return {closed:false,location:{set href(v){}},close(){}}}});
 await p.goto('http://localhost:8765/central.html');await p.waitForTimeout(1600);await p.evaluate(()=>page('Rutas'));await p.waitForTimeout(700);
 await p.click('#dyDGo');await p.waitForTimeout(1200);await p.click('#dyDTodos');await p.click('#dyBarra [data-moto="m2"]');await p.click('#dyDAsig');await p.waitForTimeout(900);
 const id=await p.evaluate(()=>window.__DB.pedidos.find(o=>o.numero_general===1).id);
 await p.click('#dyDList [data-dyedit="'+id+'"]');await p.waitForTimeout(300);
 chk('E1 abre el editor de un pedido YA asignado',await p.locator('#dyEdit .asig:has-text("Freddy")').isVisible());
 await p.fill('#eM','150000');await p.click('#eC [data-m="producto_pagado"]');
 chk('E2 el total se recalcula (solo envío)',/25\.000/.test(await p.locator('#eTot').innerText()));
 await p.click('#eC [data-m="pendiente"]');chk('E3 todo: mercadería + envío',/175\.000/.test(await p.locator('#eTot').innerText()));
 await p.fill('#eO','Hasta las 19:00');await p.fill('#eP','Blusa roja');
 await p.screenshot({path:SHOT+'edit1.png'});
 await p.click('#eS');await p.waitForTimeout(600);
 const rpc=await p.evaluate(()=>window.__rpc.filter(x=>x[0]==='editar_pedido_seguro').pop()?.[1]);
 chk('E4 manda solo lo que cambió',rpc&&rpc.p_cambios.precio_mercaderia===150000&&rpc.p_cambios.observaciones==='Hasta las 19:00'&&rpc.p_cambios.producto==='Blusa roja'&&!('modalidad_pago' in rpc.p_cambios)&&!('nombre_cliente' in rpc.p_cambios),rpc&&rpc.p_cambios);
 const db=await p.evaluate(id=>window.__DB.pedidos.find(o=>o.id===id),id);chk('E5 guardado y sigue asignado a Freddy',db.precio_mercaderia===150000&&db.motorista_id==='m2',db.motorista_id);
 const wa=await p.locator('#eWa a').getAttribute('href');chk('E6 botón para avisar a Freddy con el nuevo total',decodeURIComponent(wa).includes('595972798907')&&decodeURIComponent(wa).includes('175.000'),decodeURIComponent(wa).slice(0,160));
 await p.screenshot({path:SHOT+'edit2.png'});
 await p.click('#eX');await p.waitForTimeout(200);chk('E7 la lista muestra la nota nueva',await p.locator('#dyDList .dy-obs:has-text("Hasta las 19:00")').count()===1);
 await p.evaluate(()=>page('Pedidos'));await p.waitForTimeout(300);await p.click('#orderResults [data-order]');await p.waitForTimeout(200);
 chk('E8 en Pedidos › Ver también hay "Editar pedido"',await p.locator('#orderDetail [data-dyedit]').count()===1);
 await ctx.close();
 // --- Motorista ---
 ctx=await b.newContext({viewport:{width:390,height:844},deviceScaleFactor:2,serviceWorkers:'block'});p=await ctx.newPage();p.on('pageerror',e=>errs.push('M:'+e.message));
 await p.route(/maps\.googleapis|maps\.gstatic/,r=>r.abort());await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fakeMoto}));
 await p.addInitScript(()=>localStorage.setItem('dyf-auth',JSON.stringify({access_token:'a',refresh_token:'r'})));
 await p.goto('http://localhost:8765/motorista.html');await p.waitForTimeout(2000);
 chk('M1 primera vez: sin aviso',await p.locator('#dyAvisoEd').count()===0);
 await p.evaluate(()=>{window.__P[0].version_edicion=2;window.__P[0].precio_mercaderia=150000;window.__P[0].observaciones='Hasta las 19:00'});await p.evaluate(()=>load());await p.waitForTimeout(600);
 chk('M2 la Central editó: aparece "✏️ La Central modificó" con N.º 3 · Odilda',/La Central modificó/.test(await p.locator('#dyAvisoEd').innerText().catch(()=>''))&&/N\.º 3 · Odilda/.test(await p.locator('#dyAvisoEd').innerText()));
 chk('M3 la tarjeta queda marcada como modificada',await p.locator('.dy-ped.dy-edit').count()===1);
 await p.screenshot({path:SHOT+'edit_moto.png'});
 await p.click('#dyAvisoOk');await p.waitForTimeout(200);await p.evaluate(()=>load());await p.waitForTimeout(500);
 chk('M4 "Entendido" lo quita y no vuelve',await p.locator('#dyAvisoEd').count()===0&&await p.locator('.dy-ped.dy-edit').count()===0);
 chk('M5 sin errores JS',!errs.length,errs);console.log(ok+'/'+n);await b.close()})();
