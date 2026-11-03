// Central › Rutas › Despacho rápido: optimiza desde el GPS, reparte por zonas, asigna y arma WhatsApp.
const {chromium}=require('playwright');const SHOT='/tmp/claude-0/-home-claude/17f6e967-50a2-5a83-8608-c130999d8c94/scratchpad/';
const fake=`(function(){window.__rpc=[];
const pts=[[-25.33,-57.52],[-25.34,-57.50],[-25.32,-57.51],[-25.26,-57.60],[-25.25,-57.62],[-25.27,-57.61],[-25.40,-57.55],[-25.41,-57.57],[-25.39,-57.56]];
const DB={flota_usuarios:[{rol:'propietario',empresa_id:'e1',usuario_id:'u1',activo:true,puede_motoristas:true}],
 motoristas:[{id:'m1',empresa_id:'e1',nombre:'Edgar Daniel',telefono:'0986260417',activo:true,usuario_id:'x1',color_identificador:'#1765ba'},{id:'m2',empresa_id:'e1',nombre:'Freddy',telefono:'0972798907',activo:true,usuario_id:'x2',color_identificador:'#e8590c'},{id:'m3',empresa_id:'e1',nombre:'Repartidor Principal',telefono:'0982123456',activo:true,usuario_id:null}],
 tiendas:[{id:'t1',empresa_id:'e1',codigo:'T3',nombre_comercial:'Persa'}],rutas_generales:[],
 pedidos:pts.map((p,i)=>({id:'p'+i,empresa_id:'e1',tienda_id:'t1',nombre_cliente:'Cliente '+(i+1),telefono_cliente:'0981',direccion_cliente:'Dir '+i,lat:p[0],lng:p[1],estado:'pendiente',turno:'manana',motorista_id:null,ruta_general_id:null,numero_general:null,precio_mercaderia:100000,precio_delivery:25000,modalidad_pago:'pendiente',created_at:'2026-11-02T10:0'+i+':00Z'})).concat([{id:'px',empresa_id:'e1',tienda_id:'t1',nombre_cliente:'Sin GPS',lat:null,lng:null,estado:'pendiente',turno:'manana',motorista_id:null,ruta_general_id:null,numero_general:null,precio_mercaderia:0,precio_delivery:0,modalidad_pago:'pendiente',created_at:'2026-11-02T10:00:00Z'}])};
window.__DB=DB;
window.supabase={createClient:()=>{const user={id:'u1',email:'jefe@x.com'};
 const q=t=>{const c={then:(a,b)=>Promise.resolve({data:(DB[t]||[]).map(x=>({...x})),error:null,count:(DB[t]||[]).length}).then(a,b)};['select','eq','limit','order','in','gte','lte','neq','is','not','range','ilike','or','filter','match','gt','lt','contains'].forEach(m=>c[m]=()=>c);c.single=()=>Promise.resolve({data:(DB[t]||[])[0]||null,error:null});c.maybeSingle=c.single;c.insert=()=>c;c.update=()=>c;return c};
 return {from:q,auth:{getSession:async()=>({data:{session:{user,access_token:'a',refresh_token:'r'}}}),getUser:async()=>({data:{user}}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>({})},
  rpc:async(n,a)=>{window.__rpc.push([n,a]);
   if(n==='flota_crear_ruta_turno'){let r=DB.rutas_generales.find(r=>r.turno===a.p_turno);if(!r){r={id:'r1',empresa_id:'e1',fecha:a.p_fecha,turno:a.p_turno,estado:'abierta'};DB.rutas_generales.push(r)}return {data:r.id,error:null}}
   if(n==='admin_confirmar_ruta_optimizada'){a.p_orden_ids.forEach((id,i)=>{const o=DB.pedidos.find(x=>x.id===id);o.numero_general=i+1;o.ruta_general_id=a.p_ruta_general_id});DB.rutas_generales[0].estado='optimizada';return {data:null,error:null}}
   if(n==='flota_asignar_lote'){a.p_pedidos.forEach(id=>{DB.pedidos.find(x=>x.id===id).motorista_id=a.p_motorista});return {data:a.p_pedidos.length,error:null}}
   if(n==='flota_leer_comision_general')return {data:25,error:null};
   return {data:[],error:null}},
  channel:()=>{const ch={on:()=>ch,subscribe:()=>ch};return ch},removeChannel:()=>{}}}}})();`;
(async()=>{const b=await chromium.launch();let ok=0,n=0;const chk=(t,c,d)=>{n++;if(c)ok++;console.log(c?'OK   ':'FALLA',t,d!==undefined?JSON.stringify(d).slice(0,300):'')};
 for(const vp of [{width:1366,height:900},{width:390,height:844}]){const w=vp.width;
 const ctx=await b.newContext({viewport:vp,deviceScaleFactor:w<500?2:1,serviceWorkers:'block',geolocation:{latitude:-25.335,longitude:-57.54},permissions:['geolocation']});
 const p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push(e.message));p.on('dialog',d=>d.accept());
 await p.route(/maps\.googleapis|maps\.gstatic/,r=>r.abort());await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fake}));
 await p.addInitScript(()=>{localStorage.setItem('dyf-auth',JSON.stringify({access_token:'a',refresh_token:'r'}));window.__abiertos=[];window.open=u=>{window.__abiertos.push(String(u));return null}});
 await p.goto('http://localhost:8765/central.html');await p.waitForTimeout(1800);
 await p.evaluate(()=>page('Rutas'));await p.waitForTimeout(800);
 chk(w+' D1 aparece "Despacho rápido" arriba',await p.locator('#dyDesp h3').isVisible());
 chk(w+' D2 herramientas viejas plegadas',await p.locator('#dyAvz').count()===1&&!(await p.locator('#dyAvz').getAttribute('open')));
 const t=await p.locator('#dyDT [data-t="manana"]').innerText();chk(w+' D3 turno mañana con 10 sin asignar',/10 sin asignar/.test(t)&&await p.locator('#dyDT [data-t="manana"].on').count()===1,t);
 chk(w+' D4 motos con app preseleccionadas (2)',await p.locator('#dyDM .on').count()===2);
 chk(w+' D5 avisa el pedido sin ubicación',/Sin GPS/.test(await p.locator('#dyDesp .aviso').innerText()));
 await p.click('#dyDGo');await p.waitForTimeout(1200);
 const m=await p.locator('#dyDMsg').innerText();chk(w+' D6 ruta lista desde mi ubicación',/Ruta lista: 9 parada/.test(m),m);
 const st=await p.evaluate(()=>{const ps=window.__DB.pedidos.filter(o=>o.numero_general!=null).sort((a,b)=>a.numero_general-b.numero_general);return {n:ps.length,nums:ps.map(o=>o.numero_general),org:document.getElementById('routeOrigin')?.value}});
 chk(w+' D7 9 paradas numeradas 1..9 (sin el de sin GPS)',st.n===9&&st.nums.join()==='1,2,3,4,5,6,7,8,9',st);
 const cards=await p.locator('#dyDPlan .moto').count();chk(w+' D8 reparto en 2 zonas (una por moto)',cards===2,cards);
 const zonas=await p.evaluate(()=>[...document.querySelectorAll('#dyDPlan .moto')].map(c=>c.querySelector('.n').textContent));
 chk(w+' D9 cada moto recibe números seguidos (4–5 paradas)',zonas.every(z=>/[45] parada/.test(z)),zonas);
 if(w<500)await p.screenshot({path:SHOT+'desp1.png',fullPage:false});else await p.screenshot({path:SHOT+'desp_pc.png'});
 await p.click('#dyDAsig');await p.waitForTimeout(1000);
 const asig=await p.evaluate(()=>{const g={};window.__DB.pedidos.forEach(o=>{if(o.motorista_id)(g[o.motorista_id]=g[o.motorista_id]||[]).push(o.numero_general)});return g});
 chk(w+' D10 asignado: Edgar y Freddy con sus zonas',Object.keys(asig).length===2&&(asig.m1.length+asig.m2.length)===9&&!asig.m3,asig);
 chk(w+' D11 botones de WhatsApp por moto',await p.locator('[data-wa]').count()===2);
 await p.click('[data-wa="m2"]');const url=await p.evaluate(()=>window.__abiertos.at(-1)||'');
 chk(w+' D12 WhatsApp a Freddy con ruta de Maps y orden',url.includes('phone=595972798907')&&decodeURIComponent(url).includes('google.com/maps/dir')&&decodeURIComponent(url).includes('Orden de entrega'),url.slice(0,120));
 if(w<500)await p.screenshot({path:SHOT+'desp2.png',fullPage:false});
 // GPS denegado → mensaje claro; punto manual funciona
 const ctx2=await b.newContext({viewport:vp,serviceWorkers:'block',permissions:[]});const p2=await ctx2.newPage();p2.on('dialog',d=>d.accept());
 await p2.route(/maps\.googleapis|maps\.gstatic/,r=>r.abort());await p2.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fake}));
 await p2.addInitScript(()=>{localStorage.setItem('dyf-auth',JSON.stringify({access_token:'a',refresh_token:'r'}));navigator.geolocation.getCurrentPosition=(ok,no)=>no({code:1,message:'denied'})});
 await p2.goto('http://localhost:8765/central.html');await p2.waitForTimeout(1500);await p2.evaluate(()=>page('Rutas'));await p2.waitForTimeout(600);
 await p2.click('#dyDGo');await p2.waitForTimeout(500);chk(w+' D13 sin permiso de GPS: explica qué hacer',/Permití la ubicación/.test(await p2.locator('#dyDMsg').innerText()));
 await p2.click('#dyDOtro');await p2.fill('#dyDOrig','-25.335,-57.54');await p2.click('#dyDGo');await p2.waitForTimeout(1200);
 chk(w+' D14 con punto de salida manual también optimiza',/Ruta lista/.test(await p2.locator('#dyDMsg').innerText()));await ctx2.close();
 chk(w+' D15 sin errores JS',!errs.length,errs);await ctx.close()}
 console.log(ok+'/'+n);await b.close()})();
