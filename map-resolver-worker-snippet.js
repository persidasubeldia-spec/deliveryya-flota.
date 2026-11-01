async function resolveMapRequest(req) {
const reply=(body,status=200)=>new Response(JSON.stringify(body),{status,headers:{"content-type":"application/json","cache-control":"no-store"}});
if(req.method!=="POST")return reply({error:"Método no permitido"},405);
let body;try{body=await req.json()}catch(e){return reply({error:"Datos inválidos"},400)}
let url;try{url=new URL(String(body.url||""))}catch(e){return reply({error:"Enlace inválido"},400)}
const hosts=new Set(["maps.app.goo.gl","goo.gl","share.google","maps.google.com","www.google.com","google.com"]);
const permitted=u=>u.protocol==="https:"&&hosts.has(u.hostname.toLowerCase());
if(!permitted(url))return reply({error:"Solo enlaces HTTPS de Google Maps"},400);
const patterns=[/@(-?\d{1,2}(?:\.\d+)?),(-?\d{1,3}(?:\.\d+)?)/,/!3d(-?\d{1,2}(?:\.\d+)?)!4d(-?\d{1,3}(?:\.\d+)?)/,/[?&](?:q|query|ll|center|destination|daddr)=(-?\d{1,2}(?:\.\d+)?),(-?\d{1,3}(?:\.\d+)?)/];
function coord(s){let text=s;try{text=decodeURIComponent(s)}catch(e){}for(const t of [text,s])for(const re of patterns){const m=t.match(re);if(m){const lat=Number(m[1]),lng=Number(m[2]);if(lat>=-90&&lat<=90&&lng>=-180&&lng<=180)return {lat,lng}}}return null}
try{
for(let i=0;i<5;i++){
const c=coord(url.toString());if(c)return reply({coords:c});
const r=await fetch(url.toString(),{redirect:"manual",signal:AbortSignal.timeout(8000)});
const loc=r.headers.get("location");
if(loc&&r.status>=300&&r.status<400){url=new URL(loc,url);if(!permitted(url))return reply({error:"Redirección fuera de Google Maps"},422);continue}
if(r.ok){const c=coord((await r.text()).slice(0,300000));if(c)return reply({coords:c})}
break
}
return reply({error:"Google no publicó coordenadas verificables. Compartí la ubicación exacta o pegá latitud,longitud."},422)
}catch(e){return reply({error:"No se pudo consultar el enlace de Google Maps."},502)}
}