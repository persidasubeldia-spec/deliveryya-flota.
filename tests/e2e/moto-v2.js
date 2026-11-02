const {chromium,devices}=require('playwright');const fs=require('fs');
async function abrir(b,fake,dark){const ctx=await b.newContext({...devices['Galaxy S9+']});const p=await ctx.newPage();p.on('pageerror',e=>console.log('ERROR JS',e.message));p.on('dialog',d=>d.accept());
 if(dark)await ctx.addInitScript(()=>{try{localStorage.setItem('deliveryya-moto-theme','dark');localStorage.setItem('theme','dark')}catch(_){}});
 await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fs.readFileSync(__dirname+'/'+fake,'utf8')}));await p.route(/maps\.googleapis\.com/,r=>r.abort());
 await p.goto('http://localhost:8765/motorista.html');await p.waitForTimeout(2500);if(dark&&!(await p.evaluate(()=>document.body.classList.contains('dark'))))await p.evaluate(()=>document.getElementById('themeToggle').click());await p.waitForTimeout(300);return p}
(async()=>{const b=await chromium.launch();const R=[];const ok=(n,c,d)=>R.push((c?'OK    ':'FALLA ')+n+(d?' → '+d:''));
// Caso con pendientes
let p=await abrir(b,'fake-moto3.js',false);
ok('Optimizar visible junto a "Abrir mi ruta"',await p.locator('#rutaCompleta + #dyOptWrap #optimizeMine').isVisible(),await p.locator('#optimizeMine').innerText());
ok('Mis rutas bajo el mapa',await p.locator('#dyRutas .dy-ruta').count()===1&&(await p.evaluate(()=>{const m=document.getElementById('map').closest('.card');return !!(m.compareDocumentPosition(document.getElementById('dyRutas'))&4)})),(await p.locator('#dyRutas').innerText()).replace(/\n/g,' | ').slice(0,160));
await p.locator('#dyRutas [data-arch]').click();await p.waitForTimeout(200);
ok('Archivar ruta la oculta y ofrece verlas',await p.locator('#dyRutas .dy-ruta').count()===0&&/Ver rutas archivadas \(1\)/.test(await p.locator('#dyRutas').innerText()));
await p.locator('#dyVerArch').click();await p.waitForTimeout(200);ok('Se puede volver a abrir la archivada',await p.locator('#dyRutas .dy-ruta').count()===1&&/Desarchivar/.test(await p.locator('#dyRutas').innerText()));
await p.locator('#dyRutas [data-arch]').click();await p.waitForTimeout(200);
await p.locator('[data-tab=caja]').click();await p.waitForTimeout(300);
ok('Botón Verificar mis entregas',await p.locator('#dyVerificarBtn').isVisible());
await p.locator('#dyVerificarBtn').click();await p.waitForTimeout(300);const ver=await p.locator('.dy-sh').innerText();
ok('Verificación: detalle por pedido, cobro e incidencias',/N.º 1 · Ana Gómez[\s\S]*125\.000/.test(ver)&&/Motivo: Cliente rechazó/.test(ver)&&/No responde · No atiende/.test(ver)&&/Te faltan 2/.test(ver),ver.replace(/\n/g,' | ').slice(0,260));
await p.screenshot({path:'/tmp/v2-verificar.png'});
await p.locator('.dy-sh .dy-cancel').click();
await p.locator('#submitClose').click();await p.waitForTimeout(300);ok('Terminar ruta pasa primero por la verificación',await p.getByText('Está todo bien · Terminar ruta y enviar').isVisible());
await p.locator('.dy-sh .dy-cancel').click();await p.locator('[data-tab=ajustes]').click();await p.waitForTimeout(200);const aj=await p.locator('.t-ajustes').innerText();
ok('Ajustes sin Optimizar (ahora en Entregas) y con lo necesario',!/Optimizar/.test(aj)&&/Modo noche/.test(aj)&&/WhatsApp del jefe/.test(aj)&&/Cerrar sesión/.test(aj),aj.replace(/\n/g,' | '));
await p.context().close();
// Caso real en modo noche
p=await abrir(b,'fake-moto-real.js',true);
await p.locator('[data-tab=caja]').click();await p.waitForTimeout(300);
const col=await p.evaluate(()=>{const k=document.querySelector('.dy-kpi-main'),c=document.querySelector('.dy-cerrada'),g=e=>[getComputedStyle(e).backgroundColor,getComputedStyle(e).color];return {kpi:g(k),kpiNum:getComputedStyle(k.querySelector('.number')).color,msg:g(c),txt:c.textContent}});
const lum=s=>{const [r,g,b]=s.match(/\d+/g).map(Number);return (0.299*r+0.587*g+0.114*b)};
ok('Modo noche: "Entrego al jefe" legible',Math.abs(lum(col.kpi[0])-lum(col.kpiNum))>90,JSON.stringify(col.kpi)+' num '+col.kpiNum);
ok('Modo noche: aviso de rendición legible',Math.abs(lum(col.msg[0])-lum(col.msg[1]))>90,JSON.stringify(col.msg));
ok('Rendición "presentada" se explica bien',/Rendición enviada · declaraste ₲ 0/.test(col.txt),col.txt);
await p.screenshot({path:'/tmp/v2-caja-noche.png'});
await p.locator('[data-tab=entregas]').click();await p.waitForTimeout(300);await p.screenshot({path:'/tmp/v2-entregas-noche.png',fullPage:true});
console.log(R.join('\n'));await b.close()})();
