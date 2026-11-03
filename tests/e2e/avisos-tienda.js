// Avisos para la tienda: botón del motorista, panel y novedades de la tienda, cuadro por tienda en la Central.
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
const fakeMoto=`(function(){window.__P=[{id:'p1',nombre_cliente:'Odilda',telefono_cliente:'0981',direccion_cliente:'Casa',lat:-25.38,lng:-57.38,numero_general:3,turno:'manana',precio_mercaderia:120000,precio_delivery:25000,modalidad_pago:'pendiente',estado:'pendiente',version_edicion:1,updated_at:new Date().toISOString(),producto:'Blusa',observaciones:'',tienda_id:'t1'}];
window.supabase={createClient:()=>{const user={id:'x2',email:'freddy@x.com'};
 const rows=t=>t==='motoristas'?[{id:'m2',empresa_id:'e1',usuario_id:'x2',nombre:'Freddy',telefono:'0972',activo:true}]:t==='pedidos'?window.__P.map(x=>({...x})):[];
 const q=t=>{const c={then:(a,b)=>Promise.resolve({data:rows(t),error:null}).then(a,b)};['select','eq','limit','order','in','gte','lte','neq','is','not','range','or','filter','match'].forEach(m=>c[m]=()=>c);c.single=()=>Promise.resolve({data:rows(t)[0]||null,error:null});c.maybeSingle=c.single;return c};
 return {from:q,auth:{getSession:async()=>({data:{session:{user,access_token:'a',refresh_token:'r'}}}),getUser:async()=>({data:{user}}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>({})},rpc:async(n)=>n==='motorista_mis_tiendas'?{data:[{id:'t1',codigo:'T9',nombre_comercial:'Tu boutique',telefono:'0981555444'}],error:null}:{data:[],error:null},channel:()=>{const ch={on:()=>ch,subscribe:()=>ch};return ch},removeChannel:()=>{}}}}})();`;
const fakeT=`(function(){window.__ins=[];const base={empresa_id:'e1',tienda_id:'t1',telefono_cliente:'0981',direccion_cliente:'x',lat:-25.3,lng:-57.5,precio_mercaderia:100000,precio_delivery:25000,modalidad_pago:'pendiente',turno:'manana',creado_por:'u1',version_edicion:1};window.__TP=[{...base,id:'a1',nombre_cliente:'Odilda',estado:'pendiente',motorista_id:null,created_at:new Date().toISOString()},{...base,id:'a2',nombre_cliente:'Vale',estado:'pendiente',motorista_id:'m2',ruta_general_id:'r1',created_at:new Date().toISOString()},{...base,id:'a3',nombre_cliente:'Nota',estado:'pendiente',motorista_id:'m2',ruta_general_id:'r1',created_at:new Date().toISOString()}];
window.supabase={createClient:(u,k,o)=>{const user={id:'u1',email:'t@x.com'};
 const rows=t=>t==='pedidos'?(window.__TP||[]).map(x=>({...x})):t==='tienda_miembros'?[{tienda_id:'t1',rol:'propietario'}]:t==='tiendas'?[{id:'t1',empresa_id:'e1',codigo:'T3',nombre_comercial:'Persa Boutique',telefono:'0981',direccion:'x',lat:-25,lng:-57}]:[];
 const q=t=>{let ins=null;const c={then:(a,b)=>Promise.resolve({data:rows(t),error:null}).then(a,b)};['select','eq','limit','order','in','gte','lte','neq','is','not','range','ilike','or'].forEach(m=>c[m]=()=>c);
  c.insert=p=>{ins=p;window.__ins.push([t,p]);return c};c.single=()=>Promise.resolve(ins?{data:{id:'p'+window.__ins.length,created_at:new Date().toISOString()},error:null}:{data:rows(t)[0]||null,error:null});c.maybeSingle=c.single;return c};
 return {from:q,auth:{getSession:async()=>({data:{session:{user,access_token:'a',refresh_token:'r'}}}),getUser:async()=>({data:{user}}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>({})},
  rpc:async()=>({data:[],error:null}),channel:()=>{const ch={on:()=>ch,subscribe:()=>ch};return ch},removeChannel:()=>{}}}}})();`;
(async()=>{const b=await chromium.launch();let ok=0,n=0;const chk=(t,c,d)=>{n++;if(c)ok++;console.log(c?'OK   ':'FALLA',t,d!==undefined?JSON.stringify(d).slice(0,240):'')};const errs=[];
 const abrir=async(url,fk)=>{const ctx=await b.newContext({viewport:{width:390,height:844},deviceScaleFactor:2,serviceWorkers:'block'});const p=await ctx.newPage();p.on('pageerror',e=>errs.push(url.split('/').pop()+': '+e.message));p.on('dialog',d=>d.accept());
  await p.route(/maps\.googleapis|maps\.gstatic/,r=>r.abort());await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fk}));
  await p.addInitScript(()=>{localStorage.setItem('dyf-auth',JSON.stringify({access_token:'a',refresh_token:'r'}));window.__abiertos=[];window.open=u=>{window.__abiertos.push(String(u));return null}});await p.goto(url);await p.waitForTimeout(2000);return [ctx,p]};
 // ---- Motorista: avisar a la tienda ----
 let [ctx,p]=await abrir('http://localhost:8765/motorista.html',fakeMoto);
 chk('M1 cada pedido tiene "📢 Avisar a la tienda"',await p.locator('[data-avisar]').count()===1);
 await p.click('[data-avisar]');await p.waitForTimeout(200);
 chk('M2 se abren las 4 opciones + Otro',await p.locator('#dyAvisarOv [data-op]').count()===5);
 await p.screenshot({path:SHOT+'av_moto.png'});
 await p.click('#dyAvisarOv [data-op="nat"]');await p.waitForTimeout(200);
 let u=decodeURIComponent(await p.evaluate(()=>window.__abiertos.pop()||''));
 chk('M3 WhatsApp a la tienda (0981555444) con "no atiende", clienta y su teléfono',u.includes('phone=595981555444')&&/no atiende/.test(u)&&u.includes('Odilda')&&u.includes('0981')&&u.includes('N.º 3'),u.slice(0,200));
 await p.click('[data-avisar]');await p.click('#dyAvisarOv [data-op="pag"]');u=decodeURIComponent(await p.evaluate(()=>window.__abiertos.pop()||''));
 chk('M4 problema de pago incluye el monto a cobrar',/cobro/.test(u)&&/₲ 145\.000/.test(u),u.slice(0,220));
 await p.click('[data-avisar]');await p.click('#dyAvisarOv [data-op="otro"]');await p.fill('#dyAvTxt','Pide que vuelva a las 18');await p.click('#dyAvEnv');u=decodeURIComponent(await p.evaluate(()=>window.__abiertos.pop()||''));
 chk('M5 "Otro" manda el texto escrito',u.includes('Pide que vuelva a las 18'));
 await ctx.close();
 // ---- Tienda: panel y novedades ----
 [ctx,p]=await abrir('http://localhost:8765/index.html',fakeT);
 const kp=()=>p.evaluate(()=>[...document.querySelectorAll('#dyKpis .dy-kpi')].map(k=>k.querySelector('span').textContent+'='+k.querySelector('b').textContent));
 let k=await kp();chk('T1 panel: 3 enviados, 1 por asignar, 2 en camino',k.includes('📤 Enviados=3')&&k.includes('⏳ Por asignar=1')&&k.includes('🏍️ En camino=2'),k);
 chk('T2 la primera vez no hay avisos',await p.locator('#dyAvisosBox .dy-av').count()===0);
 await p.evaluate(()=>{const P=window.__TP;P[0].motorista_id='m1';P[1].estado='entregado';P[2].estado='no_responde';P[2].motivo_incidencia='No atiende'});
 await p.evaluate(()=>window.__dyReload());await p.waitForTimeout(700);
 const av=await p.locator('#dyAvisosBox .dy-av').innerText().catch(()=>'');
 chk('T3 aviso "Salieron con el delivery: Odilda"',/Salieron con el delivery: Odilda/.test(av),av);
 chk('T4 aviso "✅ Entregado · Vale"',/Entregado · Vale/.test(av));
 chk('T5 aviso de incidencia con motivo',/No responde · Nota \(No atiende\)/.test(av));
 chk('T6 aparece el aviso flotante arriba',await p.locator('#dyToastT').isVisible());
 k=await kp();chk('T7 panel actualizado: 1 entregado, 1 incidencia, 1 en camino',k.includes('✅ Entregados=1')&&k.includes('⚠️ Incidencias=1')&&k.includes('🏍️ En camino=1'),k);
 await p.screenshot({path:SHOT+'av_tienda.png'});
 await p.reload();await p.waitForTimeout(2000);chk('T8 al volver a abrir no repite avisos viejos',await p.locator('#dyAvisosBox .dy-av').count()===0);
 await p.click('#dyKpis .dy-kpi[data-f="entregado"]');await p.waitForTimeout(200);
 chk('T9 tocar "Entregados" abre Mis pedidos filtrado',await p.evaluate(()=>!document.getElementById('pedidos').classList.contains('hide')&&document.getElementById('filterOrders').value==='entregado'));
 await ctx.close();
 // ---- Central: cuadro por tienda ----
 [ctx,p]=await abrir('http://localhost:8765/central.html',fake);
 chk('C1 Inicio muestra "Pedidos por tienda"',await p.locator('#dyPorTienda').isVisible());
 const fila=await p.locator('#dyPorTienda tbody tr').first().innerText().catch(()=>'');chk('C2 fila de la tienda con sus enviados',/T3/.test(fila)&&/11|10/.test(fila),fila);
 await p.locator('#dyPorTienda').scrollIntoViewIfNeeded();await p.screenshot({path:SHOT+'av_central.png'});
 chk('X sin errores JS',!errs.length,errs);console.log(ok+'/'+n);await b.close()})();
