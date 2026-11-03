// Un pedido nuevo (p. ej. desde WhatsApp) aparece al instante en el despacho de la Central, en rojo, y se suma al optimizar.
const {chromium}=require('playwright');
const fake=`(function(){window.__rpc=[];
const pts=[[-25.33,-57.52],[-25.33,-57.52],[-25.32,-57.51],[-25.26,-57.60],[-25.25,-57.62],[-25.27,-57.61],[-25.40,-57.55],[-25.41,-57.57],[-25.39,-57.56]];
const DB={flota_usuarios:[{rol:'propietario',empresa_id:'e1',usuario_id:'u1',activo:true,puede_motoristas:true}],
 motoristas:[{id:'m1',empresa_id:'e1',nombre:'Edgar Daniel',telefono:'0986260417',activo:true,usuario_id:'x1',color_identificador:'#1765ba'},{id:'m2',empresa_id:'e1',nombre:'Freddy',telefono:'0972798907',activo:true,usuario_id:'x2',color_identificador:'#e8590c'},{id:'m3',empresa_id:'e1',nombre:'Repartidor Principal',telefono:'0982123456',activo:true,usuario_id:null}],
 tiendas:[{id:'t1',empresa_id:'e1',codigo:'T3',nombre_comercial:'Persa'}],rutas_generales:[],
 pedidos:pts.map((p,i)=>({id:'p'+i,empresa_id:'e1',tienda_id:'t1',nombre_cliente:'Cliente '+(i+1),telefono_cliente:'0981',direccion_cliente:'Dir '+i,lat:p[0],lng:p[1],estado:'pendiente',turno:'manana',motorista_id:null,ruta_general_id:null,numero_general:null,precio_mercaderia:100000,precio_delivery:25000,modalidad_pago:'pendiente',created_at:'2026-11-02T10:0'+i+':00Z'})).concat([{id:'pt',empresa_id:'e1',tienda_id:'t1',nombre_cliente:'Cqroli',lat:-25.31,lng:-57.53,estado:'pendiente',turno:'tarde',motorista_id:null,ruta_general_id:null,numero_general:null,version_edicion:1,precio_mercaderia:0,precio_delivery:0,modalidad_pago:'pendiente',created_at:'2026-11-02T10:00:00Z'},{id:'px',empresa_id:'e1',tienda_id:'t1',nombre_cliente:'Sin GPS',lat:null,lng:null,estado:'pendiente',turno:'manana',motorista_id:null,ruta_general_id:null,numero_general:null,precio_mercaderia:0,precio_delivery:0,modalidad_pago:'pendiente',created_at:'2026-11-02T10:00:00Z'}])};
window.__DB=DB;
window.supabase={createClient:()=>{const user={id:'u1',email:'jefe@x.com'};
 const q=t=>{const c={then:(a,b)=>Promise.resolve({data:(DB[t]||[]).map(x=>({...x})),error:null,count:(DB[t]||[]).length}).then(a,b)};['select','eq','limit','order','in','gte','lte','neq','is','not','range','ilike','or','filter','match','gt','lt','contains'].forEach(m=>c[m]=()=>c);c.single=()=>Promise.resolve({data:(DB[t]||[])[0]||null,error:null});c.maybeSingle=c.single;c.insert=()=>c;c.update=()=>c;return c};
 return {from:q,auth:{getSession:async()=>({data:{session:{user,access_token:'a',refresh_token:'r'}}}),getUser:async()=>({data:{user}}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>({})},
  rpc:async(n,a)=>{window.__rpc.push([n,a]);
   if(n==='flota_crear_ruta_turno'){let r=DB.rutas_generales.find(r=>r.turno===a.p_turno);if(!r){r={id:'r1',empresa_id:'e1',fecha:a.p_fecha,turno:a.p_turno,estado:'abierta'};DB.rutas_generales.push(r)}return {data:r.id,error:null}}
   if(n==='admin_confirmar_ruta_optimizada'){a.p_orden_ids.forEach((id,i)=>{const o=DB.pedidos.find(x=>x.id===id);o.numero_general=i+1;o.ruta_general_id=a.p_ruta_general_id});DB.rutas_generales[0].estado='optimizada';return {data:null,error:null}}
   if(n==='flota_asignar_lote'){a.p_pedidos.forEach(id=>{DB.pedidos.find(x=>x.id===id).motorista_id=a.p_motorista});return {data:a.p_pedidos.length,error:null}}
   if(n==='flota_cambiar_turno_pedido'){const o=DB.pedidos.find(x=>x.id===a.p_pedido);o.turno=a.p_turno;return {data:null,error:null}}
   if(n==='flota_anexar_pedidos_a_ruta'){const mx=Math.max(0,...DB.pedidos.map(o=>o.numero_general||0));a.p_pedidos.forEach((id,i)=>{const o=DB.pedidos.find(x=>x.id===id);o.numero_general=mx+i+1;o.ruta_general_id=a.p_ruta});return {data:a.p_pedidos.length,error:null}}
   if(n==='flota_leer_comision_general')return {data:25,error:null};
   return {data:[],error:null}},
  channel:()=>{const ch={on:(e,f,cb)=>{(window.__rt=window.__rt||[]).push(cb);return ch},subscribe:()=>ch};return ch},removeChannel:()=>{}}}}})();`;
(async()=>{const b=await chromium.launch();let ok=0,n=0;const chk=(t,c,d)=>{n++;if(c)ok++;console.log(c?'OK   ':'FALLA',t,d!==undefined?JSON.stringify(d).slice(0,240):'')};const errs=[];
 const ctx=await b.newContext({viewport:{width:1300,height:900},serviceWorkers:'block',geolocation:{latitude:-25.335,longitude:-57.54},permissions:['geolocation']});const p=await ctx.newPage();p.on('pageerror',e=>errs.push(e.message));p.on('dialog',d=>d.accept());
 await p.route(/maps\.googleapis|maps\.gstatic/,r=>r.abort());await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fake}));
 await p.addInitScript(()=>{localStorage.setItem('dyf-auth',JSON.stringify({access_token:'a',refresh_token:'r'}));window.open=()=>({closed:false,location:{},close(){}})});
 await p.goto('http://localhost:8765/central.html');await p.waitForTimeout(1800);await p.evaluate(()=>page('Rutas'));await p.waitForTimeout(800);
 await p.click('#dyDGo');await p.waitForTimeout(1200);
 await p.click('#dyDList label:has(.num:text-is("1")) input');await p.click('#dyBarra [data-moto="m2"]');await p.click('#dyDAsig');await p.waitForTimeout(900);
 await p.waitForTimeout(2500);
 await p.evaluate(()=>{window.__DB.pedidos.push({id:'nuevo',empresa_id:'e1',tienda_id:'t1',nombre_cliente:'Carmen',telefono_cliente:'0981',direccion_cliente:'Ubicación GPS',lat:-25.3282308,lng:-57.5530462,estado:'pendiente',turno:'manana',motorista_id:null,ruta_general_id:null,numero_general:null,precio_mercaderia:1,precio_delivery:1,modalidad_pago:'pendiente',created_at:new Date().toISOString(),version_edicion:1});(window.__rt||[]).forEach(f=>{try{f({})}catch(_){}})});
 await p.waitForTimeout(1600);
 chk('N1 en menos de 2 s aparece en la lista',await p.locator('#dyDList .stop:has-text("Carmen")').count()===1);
 const m=await p.evaluate(()=>[...document.querySelectorAll('#dyMap .leaflet-marker-icon div')].map(d=>d.textContent));chk('N2 en el mapa se ve en rojo "NUEVO"',m.includes('NUEVO'),m);
 chk('N3 aviso "🆕 Pedido nuevo: Carmen"',/Pedido nuevo: Carmen/.test(await p.locator('#dyDAv').innerText()));
 await p.click('#dyDGo');await p.waitForTimeout(1200);
 const num=await p.evaluate(()=>window.__DB.pedidos.find(o=>o.id==='nuevo').numero_general);
 chk('N4 al optimizar se suma al final (N.º 10) sin tocar los ya repartidos',num===10&&await p.evaluate(()=>window.__DB.pedidos.find(o=>o.numero_general===1).motorista_id==='m2'),num);
 chk('N5 sin errores JS',!errs.length,errs);console.log(ok+'/'+n);await b.close()})();
