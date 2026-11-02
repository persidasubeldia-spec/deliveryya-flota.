const {chromium,devices}=require('playwright');const fs=require('fs');
(async()=>{const b=await chromium.launch();const errs=[];
const p=await (await b.newContext({...devices['iPhone 13']})).newPage();p.on('pageerror',e=>errs.push('moto: '+e.message));
await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fs.readFileSync(__dirname+'/fake-supabase-estados.js','utf8')}));await p.route(/maps\.googleapis\.com/,r=>r.abort());
await p.goto('http://localhost:8765/motorista.html');await p.waitForTimeout(3000);
const mk=await p.$$eval('.moto-marker',els=>els.map(e=>e.textContent+':'+getComputedStyle(e).backgroundColor));console.log('Moto · marcadores:',mk.join('  '));
await p.screenshot({path:'/tmp/moto-colores.png'});
// Central con un pedido entregado y otro rechazado
const prod=JSON.parse(fs.readFileSync(__dirname+'/proddata.json','utf8'));const m=prod.pedidos.filter(x=>x.turno==='manana');m.forEach((x,i)=>{x.ruta_general_id='r1';x.numero_general=i+1;x.motorista_id='e7d06427-1a1b-49d4-8448-f94997c5284a'});m[0].estado='entregado';m[1].estado='rechazado';m[2].estado='no_responde';prod.rutas_generales.push({id:'r1',empresa_id:prod.flota_usuarios[0].empresa_id,fecha:'2026-11-02',turno:'manana',estado:'en_reparto'});
const c=await (await b.newContext({viewport:{width:1500,height:950}})).newPage();c.on('pageerror',e=>errs.push('central: '+e.message));
await c.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:'window.__PROD='+JSON.stringify(prod)+';'+fs.readFileSync(__dirname+'/fake-prod.js','utf8')}));await c.route(/maps\.googleapis\.com/,r=>r.abort());
await c.goto('http://localhost:8765/central.html');await c.waitForTimeout(2000);await c.locator('#nav button',{hasText:'Rutas'}).click();await c.waitForTimeout(800);await c.locator('[data-shift-button="manana"]').click();await c.waitForTimeout(800);
const cols=await c.$$eval('#routeMap .leaflet-marker-icon div',els=>els.map(e=>e.textContent+':'+e.style.background));console.log('Central · marcadores:',cols.join('  '));
console.log('Central · tarjeta moto:',(await c.locator('#driverQuickCards').innerText()).replace(/\n/g,' '));
console.log('Central · leyenda:',await c.locator('#dyVivo').innerText());
await c.screenshot({path:'/tmp/central-colores.png'});
console.log(errs.join('\n')||'sin errores JS');await b.close()})();
