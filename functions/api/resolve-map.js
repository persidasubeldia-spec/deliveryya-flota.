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
export async function onRequestPost({request}){
 let body;try{body=await request.json()}catch{return json({error:'Cuerpo inválido'},400)}
 if(typeof body?.url!=='string'||body.url.length>2048)return json({error:'Enlace inválido'},400);
 let current;try{current=safe(body.url)}catch{}
 if(!current)return json({error:'Solo enlaces HTTPS de Google Maps'},400);
 const visited=new Set();
 try{
  for(let i=0;i<6;i++){
   if(visited.has(current.href))break;visited.add(current.href);
   let coords=extract(current.href);if(coords)return json({coords});
   const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),7000);
   let response;
   try{response=await fetch(current.href,{redirect:'manual',signal:controller.signal,headers:{Accept:'text/html,application/xhtml+xml'}})}
   finally{clearTimeout(timer)}
   const location=response.headers.get('location');
   if(location){let next;try{next=safe(new URL(location,current).href)}catch{}if(!next)return json({error:'Redirección externa no admitida'},422);current=next;continue;}
   if(response.ok&&(response.headers.get('content-type')||'').includes('text/html')){
    const html=(await response.text()).slice(0,300000);
    const candidates=[...html.matchAll(/(?:https?:\\?\\/\\?\\/)(?:www\\?\\.)?google\\?\\.com[^"'<>\\s]{1,1600}/gi)].slice(0,35).map(x=>x[0].replace(/\\\\\\//g,'/').replace(/&amp;/g,'&'));
    for(const candidate of candidates){coords=extract(candidate);if(coords)return json({coords});}
    // Google Maps puede ubicar el punto real en datos embebidos (no en la URL).
    // Priorizar !3d(lat)!4d(lng) de lugares; jamás confundir con el centro del mapa.
    const direct=html.match(/!3d(-?\\d{1,2}\\.\\d+)!4d(-?\\d{1,3}\\.\\d+)/);
    if(direct){coords={lat:Number(direct[1]),lng:Number(direct[2])};if(coords.lat>=-28&&coords.lat<=-19&&coords.lng>=-63&&coords.lng<=-54)return json({coords});}
    const embedded=[...html.matchAll(/\\[(-?2[3-7]\\.\\d{4,}),\\s*(-?5[4-9]\\.\\d{4,})\\]/g)].slice(0,60).map(m=>({lat:Number(m[1]),lng:Number(m[2])}));
    // No elegir coordenadas ambiguas: solo aceptar un único punto cercano.
    if(embedded.length){const first=embedded[0];const consistent=embedded.every(p=>Math.abs(p.lat-first.lat)<0.00015&&Math.abs(p.lng-first.lng)<0.00015);if(consistent)return json({coords:first});}

   }
   break;
  }
 }catch{return json({error:'Google Maps no respondió o bloqueó la resolución. Pegá coordenadas directas o usá tu GPS.'},422)}
 return json({error:'No fue posible comprobar coordenadas en este enlace de Google Maps. Probá copiar el enlace de un punto específico.'},422);
}
