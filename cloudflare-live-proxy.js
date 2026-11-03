/* DeliveryYa Flota: app Android conserva origen pages.dev; el HTML actualizado viene de Vercel.
   Mantener este archivo versionado para reproducir la publicación directa de Cloudflare Pages.
   No agregar redirecciones a Vercel, para conservar sesión y verificaciones Android. */
const allow=new Set(['maps.app.goo.gl','goo.gl','share.google','google.com','www.google.com','maps.google.com','google.com.py','www.google.com.py']);
function safe(raw){const u=new URL(raw);if(u.protocol!=='https:'||!allow.has(u.hostname.toLowerCase())||u.username||u.password||u.port)return null;return u;}
function extract(text){
 const parts=[String(text||'')];try{parts.push(decodeURIComponent(parts[0]))}catch{}
 for(const value of parts){
  const patterns=[/!3d(-?\d{1,2}(?:\.\d+)?)!4d(-?\d{1,3}(?:\.\d+)?)/,/[?&](?:q|query|destination|daddr|ll)=(-?\d{1,2}(?:\.\d+)?),(-?\d{1,3}(?:\.\d+)?)/,/@(-?\d{1,2}(?:\.\d+)?),(-?\d{1,3}(?:\.\d+)?)/];
  for(const p of patterns){const m=value.match(p);if(m){const lat=Number(m[1]),lng=Number(m[2]);if(lat>=-28&&lat<=-19&&lng>=-63&&lng<=-54)return {lat,lng};}}
 }
 return null;
}
const json=(body,status=200)=>new Response(JSON.stringify(body),{status,headers:{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store'}});
async function resolveGoogleMapLink(request){
 let body;try{body=await request.json()}catch{return json({error:'Cuerpo inválido'},400)}
 if(typeof body?.url!=='string'||body.url.length>2048)return json({error:'Enlace inválido'},400);
 let current;try{current=safe(body.url)}catch{}
 if(!current)return json({error:'Solo enlaces HTTPS de Google Maps'},400);
 const visited=new Set();
 try{
  for(let i=0;i<6;i++){
   if(visited.has(current.href))break;visited.add(current.href);
   // Los vínculos de Google Maps de tipo /maps/dir/origen/destino
   // deben resolverse al DESTINO y no a la ubicación del remitente.
   if(current.pathname.includes('/maps/dir/')){
    const parts=current.pathname.split('/').filter(Boolean);
    const dir=parts.indexOf('dir');
    const stops=parts.slice(dir+1).filter(p=>!p.startsWith('data='));
    const points=stops.map(p=>{const a=decodeURIComponent(p).split(',');if(a.length!==2||!a.every(x=>/^-?[0-9]+(?:\.[0-9]+)?$/.test(x)))return null;return {lat:Number(a[0]),lng:Number(a[1])};}).filter(Boolean);
    if(points.length>=2){const destination=points[points.length-1];if(destination.lat>=-28&&destination.lat<=-19&&destination.lng>=-63&&destination.lng<=-54)return json({coords:destination,source:'directions_destination'});}
   }
   let coords=extract(current.href);if(coords)return json({coords});
   const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),7000);
   let response;
   try{response=await fetch(current.href,{redirect:'manual',signal:controller.signal,headers:{Accept:'text/html,application/xhtml+xml'}})}
   finally{clearTimeout(timer)}
   const location=response.headers.get('location');
   if(location){let next;try{next=safe(new URL(location,current).href)}catch{}if(!next)return json({error:'Redirección externa no admitida'},422);current=next;continue;}
   if(response.ok&&(response.headers.get('content-type')||'').includes('text/html')){
    const html=(await response.text()).slice(0,300000);
    const candidates=[...html.matchAll(/https?:[^\s"'<>]{5,1200}/gi)].slice(0,35).map(x=>x[0].replace(/\\\//g,'/').replace(/&amp;/g,'&'));
    for(const candidate of candidates){coords=extract(candidate);if(coords)return json({coords});}
    // Google Maps puede ubicar el punto real en datos embebidos (no en la URL).
    // Priorizar !3d(lat)!4d(lng) de lugares; jamás confundir con el centro del mapa.
    const direct=html.match(/!3d(-?\d{1,2}\.\d+)!4d(-?\d{1,3}\.\d+)/);
    if(direct){const lat=Number(direct[1]),lng=Number(direct[2]);if(lat>=-28&&lat<=-19&&lng>=-63&&lng<=-54)return json({coords:{lat,lng},source:'place_pin'});}


   }
   break;
  }
 }catch{return json({error:'Google Maps no respondió o bloqueó la resolución. Pegá coordenadas directas o usá tu GPS.'},422)}
 return json({error:'No fue posible comprobar coordenadas en este enlace de Google Maps. Probá copiar el enlace de un punto específico.'},422);
}


const LIVE=new Set(['/','/index.html','/app.html','/central.html','/motorista.html','/tienda-registro.html','/tienda-alta.html','/reporte-tienda.html']);
export default {
 async fetch(request,env){
  const url=new URL(request.url);
  if(url.pathname==='/api/resolve-map'){
   if(request.method!=='POST')return new Response(JSON.stringify({error:'Método no permitido'}),{status:405,headers:{'content-type':'application/json','allow':'POST'}});
   return resolveGoogleMapLink(request);
  }
  let p=url.pathname;
  if(p==='/central'||p==='/motorista'||p==='/app')p+='.html';
  if(!LIVE.has(p)||request.method!=='GET')return env.ASSETS.fetch(request);
  try{
   const target='https://deliveryya-flota-persida.vercel.app'+(p==='/'?'/index.html':p)+url.search;
   const response=await fetch(target,{method:'GET',headers:{accept:'text/html'},redirect:'follow',cf:{cacheTtl:0}});
   if(!response.ok)return env.ASSETS.fetch(request);
   const h=new Headers(response.headers);
   for(const key of ['content-encoding','content-length','transfer-encoding','set-cookie','content-security-policy'])h.delete(key);
   h.set('cache-control','no-store, max-age=0');
   h.set('x-deliveryya-source','vercel-live');
   return new Response(response.body,{status:response.status,headers:h});
  }catch(e){return env.ASSETS.fetch(request)}
 }
};
