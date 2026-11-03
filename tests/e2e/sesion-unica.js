// Una sola sesión para todas las apps: migra las viejas y no se pierde al recargar.
const {chromium}=require('playwright');const fs=require('fs');
const src=fs.readFileSync(__dirname+'/ingreso-por-rol.js','utf8');const fake=eval(src.match(/const fake=(`[\s\S]*?`);/)[1]);
const S=(exp)=>JSON.stringify({access_token:'a',refresh_token:'r'+exp,expires_at:exp,user:{id:'u1'}});
async function caso(b,pagina,roles,pre,{recargar=false}={}){const ctx=await b.newContext({viewport:{width:390,height:844},serviceWorkers:'block'});const p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push(e.message));
 await p.route(/maps\.googleapis/,r=>r.abort());
 await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:'window.__ROLES='+JSON.stringify(roles)+';'+fake}));
 await p.route(/localhost:8765\/(motorista|central)$/,r=>r.fulfill({contentType:'text/html',body:'<title>destino</title>'}));
 await p.addInitScript(pre=>{if(!sessionStorage.getItem('x')){sessionStorage.setItem('x',1);for(const [k,v] of pre)localStorage.setItem(k,v)}},pre);
 await p.goto('http://localhost:8765/'+pagina);await p.waitForTimeout(2200);
 if(recargar){await p.reload();await p.waitForTimeout(2200)}
 const r=await p.evaluate(()=>({keys:Object.keys(localStorage).filter(k=>k.startsWith('dyf-auth')),ses:localStorage.getItem('dyf-auth'),ult:localStorage.getItem('dyf-ultimo-rol'),gate:!!document.getElementById('authGate')&&!document.getElementById('authGate').classList.contains('hide'),login:document.getElementById('login')?!document.getElementById('login').classList.contains('hidden'):null})).catch(()=>({}));r.url=new URL(p.url()).pathname;r.errs=errs;await ctx.close();return r}
(async()=>{const b=await chromium.launch();let ok=0,n=0;const chk=(t,c,d)=>{n++;if(c)ok++;console.log(c?'OK   ':'FALLA',t,JSON.stringify(d).slice(0,240))};
 let r=await caso(b,'index.html',['tienda'],[['dyf-auth-tienda',S(100)],['dyf-auth-central',S(200)]]);
 chk('S1 dos sesiones viejas → queda una sola (la más nueva)',r.keys.length===1&&r.keys[0]==='dyf-auth'&&/r200/.test(r.ses),r);
 r=await caso(b,'index.html',['tienda'],[['dyf-auth-tienda',S(100)]],{recargar:true});
 chk('S2 Tienda: sesión vieja se conserva y sigue abierta al volver a abrir',r.url==='/index.html'&&!r.gate&&r.keys.join()==='dyf-auth',r);
 r=await caso(b,'app.html',['motorista'],[['dyf-auth-motorista',S(100)]]);
 chk('S3 app.html con sesión vieja de moto entra directo a /motorista',r.url==='/motorista',r);
 r=await caso(b,'central.html',['central'],[['dyf-auth-central',S(100)]],{recargar:true});
 chk('S4 Central: sigue adentro al volver a abrir',r.url==='/central.html'&&r.login===false,r);
 r=await caso(b,'index.html',['central'],[['dyf-auth-tienda',S(100)]]);
 chk('S5 cuenta de Central que estaba en Tienda → va a la Central sin pedir login',r.url==='/central'&&r.keys.join()==='dyf-auth',r);
 console.log(ok+'/'+n);await b.close()})();
