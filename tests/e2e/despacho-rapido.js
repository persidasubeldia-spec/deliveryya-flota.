// Central › Rutas › Despacho: Optimizar numera 1..N (sin asignar), el jefe marca, elige moto, asigna y manda WhatsApp.
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
 await p.addInitScript(()=>{localStorage.setItem('dyf-auth',JSON.stringify({access_token:'a',refresh_token:'r'}));window.__abiertos=[];window.open=u=>{window.__abiertos.push(String(u));return {closed:false,location:{set href(v){window.__abiertos.push(String(v))}},close(){}}}});
 await p.goto('http://localhost:8765/central.html');await p.waitForTimeout(1800);
 await p.evaluate(()=>page('Rutas'));await p.waitForTimeout(900);
 chk(w+' C1 panel de despacho arriba y vista vieja plegada',await p.locator('#dyDesp').isVisible()&&await p.locator('#dyAvz').count()===1&&!(await p.locator('#dyAvz').getAttribute('open')));
 chk(w+' C2 antes de optimizar: casilleros bloqueados y aviso de optimizar',await p.locator('#dyDList [data-ck]:not([disabled])').count()===0&&/Optimizar ruta/.test(await p.locator('#dyDAv').innerText()));
 await p.click('#dyDGo');await p.waitForTimeout(1300);
 const m=await p.locator('#dyDMsg').innerText();chk(w+' C3 "Ruta ordenada: N.º 1 al 9"',/N\.º 1 al 9/.test(m),m);
 const db=await p.evaluate(()=>window.__DB.pedidos.filter(o=>o.numero_general!=null).sort((a,b)=>a.numero_general-b.numero_general));
 chk(w+' C4 numerados 1..9 y NADIE asignado',db.map(o=>o.numero_general).join()==='1,2,3,4,5,6,7,8,9'&&db.every(o=>!o.motorista_id));
 const lista=await p.evaluate(()=>[...document.querySelectorAll('#dyDList .num')].map(x=>x.textContent));
 chk(w+' C5 la lista sigue el mismo orden 1..9',lista.slice(0,9).join()==='1,2,3,4,5,6,7,8,9',lista);
 const cruces=await p.evaluate(()=>{const ps=window.__DB.pedidos.filter(o=>o.numero_general!=null).sort((a,b)=>a.numero_general-b.numero_general).map(o=>[o.lng,o.lat]);const o=[-57.54,-25.335];const pts=[o,...ps];const cr=(a,b,c,d)=>{const f=(p,q,r)=>(q[0]-p[0])*(r[1]-p[1])-(q[1]-p[1])*(r[0]-p[0]);return f(a,b,c)*f(a,b,d)<0&&f(c,d,a)*f(c,d,b)<0};let n=0;for(let i=0;i<pts.length-1;i++)for(let j=i+2;j<pts.length-1;j++)if(cr(pts[i],pts[i+1],pts[j],pts[j+1]))n++;return n});
 chk(w+' C6 el recorrido no se cruza',cruces===0,cruces);
 const box=await p.locator('#dyDList [data-ck]').first().boundingBox();chk(w+' C7 casillero grande (≥28px)',box.width>=28&&box.height>=28,box);
 for(const k of [1,2,3,4,5])await p.locator('#dyDList label:has(.num:text-is("'+k+'")) input').check();
 await p.waitForTimeout(200);
 const bar=await p.locator('#dyBarra .cnt').innerText();chk(w+' C8 barra: 5 marcados N.º 1–5',/5 marcado/.test(bar)&&/1, 2, 3, 4, 5/.test(bar),bar);
 const sel=await p.evaluate(()=>document.querySelectorAll('#dyMap .leaflet-marker-icon div[style*="#f5a000"], #dyMap .leaflet-marker-icon div[style*="rgb(245, 160, 0)"]').length);chk(w+' C9 en el mapa se resaltan los 5 marcados',sel===5,sel);
 chk(w+' C10 sin moto elegida no deja asignar',await p.locator('#dyDAsig').isDisabled());
 await p.click('#dyBarra [data-moto="m2"]');await p.waitForTimeout(150);
 if(w<500)await p.screenshot({path:SHOT+'ctl_movil1.png'});else await p.screenshot({path:SHOT+'ctl_pc1.png'});
 await p.click('#dyDAsigW');await p.waitForTimeout(1000);
 const asig=await p.evaluate(()=>window.__DB.pedidos.filter(o=>o.motorista_id).map(o=>o.motorista_id+':'+o.numero_general).sort());
 chk(w+' C11 solo los 5 marcados quedaron para Freddy',asig.join()==='m2:1,m2:2,m2:3,m2:4,m2:5',asig);
 const wa=decodeURIComponent((await p.evaluate(()=>window.__abiertos.join(' ')))||'');chk(w+' C12 se abrió WhatsApp a Freddy con su ruta',wa.includes('595972798907')&&wa.includes('tenés 5 entrega'),wa.slice(0,90));
 const pint=await p.evaluate(()=>[...document.querySelectorAll('#dyDList label.asig')].length);chk(w+' C13 en la lista quedan 5 con la moto pintada',pint===5,pint);
 const col=await p.evaluate(()=>document.querySelectorAll('#dyMap .leaflet-marker-icon div[style*="#e8590c"], #dyMap .leaflet-marker-icon div[style*="rgb(232, 89, 12)"]').length);chk(w+' C14 en el mapa los 5 se pintan con el color de Freddy',col===5,col);
 for(const k of [6,7,8,9])await p.locator('#dyDList label:has(.num:text-is("'+k+'")) input').check();
 await p.click('#dyBarra [data-moto="m1"]');await p.click('#dyDAsig');await p.waitForTimeout(900);
 const asig2=await p.evaluate(()=>window.__DB.pedidos.filter(o=>o.motorista_id==='m1').length);chk(w+' C15 los siguientes 4 para Edgar',asig2===4,asig2);
 await p.click('#dyDGo');await p.waitForTimeout(900);chk(w+' C16 optimizar con todo repartido no cambia números',/ya está ordenada/.test(await p.locator('#dyDMsg').innerText())&&(await p.evaluate(()=>window.__DB.pedidos.filter(o=>o.numero_general!=null).map(o=>o.numero_general).sort((a,b)=>a-b).join()))==='1,2,3,4,5,6,7,8,9');
 if(w<500)await p.screenshot({path:SHOT+'ctl_movil2.png',fullPage:false});else await p.screenshot({path:SHOT+'ctl_pc2.png'});
 chk(w+' C17 sin errores JS',!errs.length,errs);await ctx.close()}
 console.log(ok+'/'+n);await b.close()})();
