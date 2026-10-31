// Resolución de enlaces compartidos de Google Maps (sin servicios externos).
const allowed = h => ['share.google','maps.app.goo.gl','goo.gl','google.com','www.google.com','maps.google.com','google.com.py','www.google.com.py'].includes(h);
function validUrl(raw){const u=new URL(raw);if(u.protocol!=='https:'||!allowed(u.hostname.toLowerCase())||u.username||u.password||u.port)return null;return u;}
function extract(value){
 const text=String(value||'').replace(/&amp;/g,'&').replace(/\\u003d/g,'=').replace(/\\u0026/g,'&');
 let decoded=text;try{decoded=decodeURIComponent(text)}catch{}
 const patterns=[/!3d(-?\d{1,2}\.\d+)!4d(-?\d{1,3}\.\d+)/,/[?&](?:q|query|destination|daddr|ll)=(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)/,/@(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)/, /(-?\d{1,2}\.\d+),\s*(-?\d{1,3}\.\d+)/];
 for(const s of [decoded,text])for(const p of patterns){const m=s.match(p);if(m){const lat=Number(m[1]),lng=Number(m[2]);if(lat>=-28&&lat<=-19&&lng>=-63&&lng<=-54)return {lat,lng}}}
 return null;
}
function candidates(html){
 const out=[];
 const patterns=[/<link[^>]+rel=["']canonical["'][^>]+href=["']([^"']+)/gi,/<meta[^>]+(?:property|name)=["'](?:og:url|twitter:url)["'][^>]+content=["']([^"']+)/gi, /(?:https?:\\?\/\\?\/)(?:www\\?\.)?google\\?\.com[^"'<>\s]{1,1000}/gi];
 for(const p of patterns){for(const m of html.matchAll(p)){out.push(m[1]||m[0]);if(out.length>=15)return out}}
 return out;
}
export default async function handler(req,res){
 res.setHeader('Cache-Control','no-store');res.setHeader('Content-Type','application/json');
 if(req.method!=='POST')return res.status(405).json({error:'Método no permitido'});
 const raw=req.body?.url;
 if(typeof raw!=='string'||raw.length>2048)return res.status(400).json({error:'Enlace inválido'});
 let url;try{url=validUrl(raw)}catch{}
 if(!url)return res.status(400).json({error:'Ingresá un enlace HTTPS válido de Google Maps'});
 const visited=new Set();
 try{
  for(let i=0;i<7;i++){
   if(visited.has(url.href))break;visited.add(url.href);
   const direct=extract(url.href);if(direct)return res.status(200).json({coords:direct});
   const controller=new AbortController();const timeout=setTimeout(()=>controller.abort(),6000);
   let response;
   try{response=await fetch(url.href,{redirect:'manual',signal:controller.signal,headers:{'User-Agent':'Mozilla/5.0 (compatible; DeliveryYa/1.0)','Accept':'text/html,application/xhtml+xml'}})}
   finally{clearTimeout(timeout)}
   const location=response.headers.get('location');
   if(location){const next=validUrl(new URL(location,url).href);if(!next)break;url=next;continue}
   const type=response.headers.get('content-type')||'';
   if(response.ok&&type.includes('text/html')){
    const html=(await response.text()).slice(0,350000);
    for(const candidate of candidates(html)){
      const found=extract(candidate);if(found)return res.status(200).json({coords:found});
    }
    const next=candidates(html).map(c=>{try{return validUrl(new URL(c.replace(/&amp;/g,'&'),url).href)}catch{return null}}).find(u=>u&&!visited.has(u.href));
    if(next){url=next;continue}
   }
   break;
  }
  return res.status(422).json({error:'Google no proporcionó las coordenadas de este enlace corto. Abrí el lugar en Google Maps y usá Compartir → Copiar vínculo de la ubicación exacta, o pegá sus coordenadas.'});
 }catch{return res.status(422).json({error:'Google no respondió o bloqueó la consulta. No se pudo comprobar esta ubicación.'})}
}
