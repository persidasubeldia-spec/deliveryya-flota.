// La observación y el producto se ven en Tienda, en la Central (Rutas, Pedidos, detalle) y en el WhatsApp al motorista.
const {chromium}=require('playwright');const fs=require('fs');const SHOT='/tmp/claude-0/-home-claude/17f6e967-50a2-5a83-8608-c130999d8c94/scratchpad/';
let fake=fs.readFileSync(__dirname+'/despacho-rapido.js','utf8').match(/const fake=`([\s\S]*?)`;/)[1];
fake=fake.replace("modalidad_pago:'pendiente',created_at:'2026-11-02T10:0'+i+':00Z'}","modalidad_pago:'pendiente',created_at:'2026-11-02T10:0'+i+':00Z',observaciones:i===0?'Hasta las 19:00':'',producto:i===0?'Camisa negra':''}");
const fakeT=fs.readFileSync(__dirname+'/nuevo-pedido-rapido.js','utf8').match(/const fake=`([\s\S]*?)`;/)[1].replace("const rows=t=>t==='tienda_miembros'","const rows=t=>t==='pedidos'?[{id:'p1',created_at:new Date().toISOString(),nombre_cliente:'Tuermana',telefono_cliente:'0972798907',direccion_cliente:'Ubicación GPS',lat:-25.38,lng:-57.38,estado:'pendiente',turno:'manana',precio_mercaderia:120000,precio_delivery:25000,modalidad_pago:'pendiente',observaciones:'Hasta las 19:00',producto:'Camisa negra',creado_por:'u1'}]:t==='tienda_miembros'");
(async()=>{const b=await chromium.launch();let ok=0,n=0;const chk=(t,c,d)=>{n++;if(c)ok++;console.log(c?'OK   ':'FALLA',t,d!==undefined?JSON.stringify(d).slice(0,200):'')};
 // Central
 let ctx=await b.newContext({viewport:{width:390,height:844},deviceScaleFactor:2,serviceWorkers:'block',geolocation:{latitude:-25.335,longitude:-57.54},permissions:['geolocation']});let p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push(e.message));p.on('dialog',d=>d.accept());
 await p.route(/maps\.googleapis|maps\.gstatic/,r=>r.abort());await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fake}));
 await p.addInitScript(()=>{localStorage.setItem('dyf-auth',JSON.stringify({access_token:'a',refresh_token:'r'}));window.__abiertos=[];window.open=u=>{window.__abiertos.push(String(u));return null}});
 await p.goto('http://localhost:8765/central.html');await p.waitForTimeout(1600);await p.evaluate(()=>page('Rutas'));await p.waitForTimeout(700);
 chk('O1 Central › Rutas: la lista muestra 📝 Hasta las 19:00',await p.locator('#routeRows .dy-obs:has-text("Hasta las 19:00")').count()===1);
 chk('O2 Central › Rutas: muestra el producto',await p.locator('#routeRows .dy-prod:has-text("Camisa negra")').count()===1);
 await p.click('#dyDGo');await p.waitForTimeout(1200);
 chk('O3 Despacho rápido: la nota aparece en el reparto',await p.locator('#dyDPlan .dy-obs:has-text("Hasta las 19")').count()===1);
 await p.click('#dyDAsig');await p.waitForTimeout(900);for(const wbtn of await p.locator('[data-wa]').all())await wbtn.click();
 const txt=decodeURIComponent((await p.evaluate(()=>window.__abiertos.join(' ')))||'');chk('O4 WhatsApp al motorista incluye la observación',txt.includes('📝 Hasta las 19:00'));
 await p.locator('#routeRows .dy-obs').first().scrollIntoViewIfNeeded();await p.screenshot({path:SHOT+'obs_central.png'});
 await p.evaluate(()=>page('Pedidos'));await p.waitForTimeout(400);
 chk('O5 Central › Pedidos: tabla con la observación',await p.locator('#orderResults .dy-obs:has-text("Hasta las 19:00")').count()===1);
 await p.fill('#orderSearch','19:00');await p.waitForTimeout(200);chk('O6 buscar "19:00" encuentra el pedido',/1 pedidos/.test(await p.locator('#orderCount').innerText()));
 await p.click('#orderResults [data-order]');await p.waitForTimeout(200);chk('O7 detalle muestra Producto y Observaciones',/Observaciones\s*Hasta las 19:00/.test(await p.locator('#orderDetail').innerText())&&/Producto\s*Camisa negra/.test(await p.locator('#orderDetail').innerText()));
 await ctx.close();
 // Tienda
 ctx=await b.newContext({viewport:{width:390,height:844},deviceScaleFactor:2,serviceWorkers:'block'});p=await ctx.newPage();p.on('pageerror',e=>errs.push('T:'+e.message));
 await p.route(/maps\.googleapis|unpkg\.com\/leaflet/,r=>r.abort());await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fakeT}));
 await p.addInitScript(()=>localStorage.setItem('dyf-auth',JSON.stringify({access_token:'a',refresh_token:'r'})));
 await p.goto('http://localhost:8765/index.html');await p.waitForTimeout(1800);await p.evaluate(()=>window.dyGo('pedidos'));await p.waitForTimeout(300);
 chk('O8 Tienda › Mis pedidos: muestra 📝 Hasta las 19:00 y 📦 Camisa negra',await p.locator('#orderList .dy-obs-t:has-text("Hasta las 19:00")').count()===1&&await p.locator('#orderList:has-text("📦 Camisa negra")').count()===1);
 await p.screenshot({path:SHOT+'obs_tienda.png'});
 chk('O9 sin errores JS',!errs.length,errs);console.log(ok+'/'+n);await b.close()})();
