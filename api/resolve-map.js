// Resuelve redirecciones de Google Maps sin exponer servidores internos.
// Solo acepta dominios de Google Maps o share.google.
const allowed = host => host === 'share.google' || host === 'maps.app.goo.gl' || host === 'goo.gl' || host === 'google.com' || host.endsWith('.google.com') || host === 'google.com.py' || host.endsWith('.google.com.py');
function coords(value) {
  let text=value; try{text=decodeURIComponent(value)}catch{}
  const patterns=[/@(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)/,/!3d(-?\d{1,2}\.\d+)!4d(-?\d{1,3}\.\d+)/,/[?&](?:q|query|ll|center|destination)=(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)/];
  for(const re of patterns){const m=text.match(re);if(m){const lat=Number(m[1]),lng=Number(m[2]);if(lat>=-28&&lat<=-19&&lng>=-63&&lng<=-54)return {lat,lng}}}
  return null;
}
export default async function handler(req,res){
  res.setHeader('Cache-Control','no-store');
  if(req.method!=='POST')return res.status(405).json({error:'Método no permitido'});
  const raw=req.body?.url;
  if(typeof raw!=='string'||raw.length>2000)return res.status(400).json({error:'Enlace inválido'});
  try{
    let url=new URL(raw);
    if(url.protocol!=='https:'||!allowed(url.hostname.toLowerCase())||url.username||url.password)return res.status(400).json({error:'Solo se aceptan enlaces HTTPS de Google Maps'});
    let found=coords(url.href);
    if(found)return res.status(200).json({coords:found,url:url.href});
    for(let i=0;i<6;i++){
      const controller=new AbortController();
      const timeout=setTimeout(()=>controller.abort(),3500);
      let response;
      try{response=await fetch(url.href,{method:'GET',redirect:'manual',signal:controller.signal,headers:{'User-Agent':'Mozilla/5.0'}})}
      finally{clearTimeout(timeout)}
      const loc=response.headers.get('location');
      if(!loc)break;
      url=new URL(loc,url);
      if(url.protocol!=='https:'||!allowed(url.hostname.toLowerCase())||url.username||url.password)break;
      found=coords(url.href);
      if(found)return res.status(200).json({coords:found,url:url.href});
    }
    return res.status(422).json({error:'No pudimos extraer coordenadas de ese enlace. Probá compartir la ubicación desde Google Maps o ingresá las coordenadas.'});
  }catch{return res.status(422).json({error:'No se pudo verificar el enlace. Comprobá que sea válido.'})}
}
