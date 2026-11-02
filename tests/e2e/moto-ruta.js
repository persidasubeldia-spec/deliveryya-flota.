const {chromium,devices}=require('playwright');const fs=require('fs');
(async()=>{const b=await chromium.launch();const p=await (await b.newContext({...devices['iPhone 13']})).newPage();const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fs.readFileSync(__dirname+'/fake-supabase.js','utf8')}));await p.route(/maps\.googleapis\.com/,r=>r.abort());
await p.goto('http://localhost:8765/motorista.html');await p.waitForTimeout(2500);
const href=await p.locator('#rutaCompleta a').first().getAttribute('href');console.log('botón:',await p.locator('#rutaCompleta a').first().innerText());console.log('enlace:',decodeURIComponent(href));
await p.screenshot({path:'/tmp/moto-ruta.png'});console.log(errs.join('|')||'sin errores JS');await b.close()})();
