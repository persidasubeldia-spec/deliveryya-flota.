const {chromium}=require('playwright');const L=require('../../../play/src/lib');const fs=require('fs');
const fake=`(function(){const D=window.__MOTO;let vinc=false,sess=null;window.__rpc=[];
const moto={id:'m1',usuario_id:'um1',nombre:'Freddy Fernández',activo:true,porcentaje_empresa_pct:25,modalidad_liquidacion:'rendir_todo'};
function q(t){const c={};const rows=()=>t==='motoristas'?(vinc?[moto]:[]):[];c.then=(r,j)=>Promise.resolve({data:rows(),error:null}).then(r,j);for(const m of ['select','order','limit','in','neq','gte','lte','eq'])c[m]=()=>c;c.single=()=>Promise.resolve({data:rows()[0]||null,error:null});return c}
const client={auth:{getSession:async()=>({data:{session:sess}}),signInWithPassword:async({email})=>{sess={user:{id:'um1',email}};return {error:null}},onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>({})},from:q,
rpc:async(n,a)=>{window.__rpc.push(n);if(n==='motorista_aceptar_invitacion'){if(window.__FALLA)return {data:null,error:{message:window.__FALLA}};vinc=true;return {data:'m1',error:null}}if(n==='motorista_contacto_jefe')return {data:[],error:null};if(n==='motorista_mis_tiendas')return {data:[],error:null};return {data:true,error:null}},
channel:()=>{const ch={on:()=>ch,subscribe:()=>ch};return ch}};window.supabase={createClient:()=>client}})();`;
async function caso(b,url,falla){const {ctx,p}=await L.nuevo(b,{w:390,h:844});
 await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:'window.__MOTO={pedidos:[],mov:[],tiendas:[]};'+(falla?'window.__FALLA='+JSON.stringify(falla)+';':'')+fake}));
 await p.goto('http://localhost:8765/'+url);await p.waitForTimeout(1500);
 const aviso=await p.locator('#dyInvAviso').count();const qs=await p.evaluate(()=>location.search);
 await p.fill('#email','freddy@ejemplo.com');await p.fill('#password','x');await p.click('#login');await p.waitForTimeout(2000);
 const r={aviso,qs,app:await p.locator('#app').isVisible(),msg:await p.locator('#msg').innerText(),rpc:await p.evaluate(()=>window.__rpc.filter(x=>x.includes('invit'))),guardado:await p.evaluate(()=>localStorage.getItem('dyf-invite-moto'))};await ctx.close();return r}
(async()=>{const b=await chromium.launch();
 console.log('1 con enlace:',await caso(b,'motorista.html?invite='+'a'.repeat(48)));
 console.log('2 sin enlace:',await caso(b,'motorista.html'));
 console.log('3 correo distinto:',await caso(b,'motorista.html?invite='+'b'.repeat(48),'Correo no verificado o incorrecto'));
 await b.close()})();
