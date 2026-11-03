// Ubicación compartida desde WhatsApp/Maps abre "Nuevo pedido" con el destino cargado.
const {chromium}=require('playwright');const fs=require('fs');
const src=fs.readFileSync(__dirname+'/ingreso-por-rol.js','utf8');const fake=eval(src.match(/const fake=(`[\s\S]*?`);/)[1]);
async function caso(b,param,roles=['tienda']){const ctx=await b.newContext({viewport:{width:390,height:844}});const p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push(e.message));
 await p.route(/maps\.googleapis/,r=>r.abort());await p.route(/\/api\/resolve-map/,r=>r.fulfill({contentType:'application/json',body:'{"coords":{"lat":-25.40,"lng":-57.50}}'}));
 await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:'window.__ROLES='+JSON.stringify(roles)+';'+fake}));
 await p.route(/localhost:8765\/(motorista|central)$/,r=>r.fulfill({contentType:'text/html',body:'<title>otro</title>'}));
 await p.addInitScript(()=>{if(!sessionStorage.getItem('x')){sessionStorage.setItem('x',1);localStorage.setItem('dyf-auth-tienda',JSON.stringify({access_token:'a',refresh_token:'r',user:{id:'u1'}}))}});
 await p.goto('http://localhost:8765/index.html?nuevo_pedido_mapa='+encodeURIComponent(param));await p.waitForTimeout(2500);
 const r=await p.evaluate(()=>({nuevo:!document.getElementById('nuevo').classList.contains('hide'),map:document.getElementById('mapLink').value,addr:document.getElementById('address').value,aviso:document.getElementById('dyMapaAviso')?.textContent||'',url:location.pathname+location.search,res:document.getElementById('mapResult').textContent})).catch(()=>({url:p.url()}));r.errs=errs;await ctx.close();return r}
(async()=>{const b=await chromium.launch();let ok=0,n=0;const chk=(t,c,d)=>{n++;if(c)ok++;console.log(c?'OK   ':'FALLA',t,JSON.stringify(d).slice(0,260))};
 let r=await caso(b,'geo:-25.3712,-57.5291?q=-25.3712,-57.5291(Elizabet)');chk('W1 geo de WhatsApp → Nuevo pedido con coordenadas',r.nuevo&&r.map==='-25.3712,-57.5291'&&r.aviso&&r.url==='/index.html'&&!r.errs.length,r);
 r=await caso(b,'geo:0,0?q=-25.30,-57.60(Casa)');chk('W2 geo:0,0?q=lat,lng',r.nuevo&&r.map==='-25.3,-57.6',r);
 r=await caso(b,'https://maps.google.com/?q=-25.28,-57.63');chk('W3 enlace maps.google.com',r.nuevo&&r.map==='-25.28,-57.63',r);
 r=await caso(b,'Mi ubicación: https://maps.app.goo.gl/AbC123xyz');chk('W4 texto compartido con enlace corto → se resuelve a coordenadas',r.nuevo&&(r.map==='-25.4,-57.5'||r.map==='https://maps.app.goo.gl/AbC123xyz'),r);
 r=await caso(b,'geo:0,0?q=Avda.+Laguna+Grande+123');chk('W5 geo con dirección escrita → dirección',r.nuevo&&r.addr==='Avda. Laguna Grande 123',r);
 r=await caso(b,'geo:-25.3712,-57.5291',['motorista']);chk('W6 motorista no se queda en Tienda',/\/motorista$/.test(r.url),r);
 console.log(ok+'/'+n);await b.close()})();
