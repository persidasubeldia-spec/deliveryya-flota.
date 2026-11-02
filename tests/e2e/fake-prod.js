(function(){
 const data=window.__PROD; window.__rpc=[];
 function q(t){let rows=data[t]||[];const c={};const res=()=>({data:rows,error:null});c.then=(r,j)=>Promise.resolve(res()).then(r,j);for(const m of ['select','order','limit','gte','lte','in','neq','is','not','filter','match','or','gt','lt'])c[m]=()=>c;c.eq=(k,v)=>{rows=rows.filter(x=>x[k]===v||x[k]===undefined);return c};c.range=(a,b)=>{rows=rows.slice(a,b+1);return c};c.single=()=>Promise.resolve({data:rows[0]||null,error:null});c.maybeSingle=c.single;return c}
 const client={auth:{getSession:async()=>({data:{session:{user:{id:'u1',email:'a@b'}}}}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>({})},from:q,
  rpc:async(n,a)=>{window.__rpc.push({n,a});
  if(n==='flota_crear_ruta_turno'){let r=data.rutas_generales.find(x=>x.turno===a.p_turno&&x.fecha===a.p_fecha);if(!r){r={id:'r-'+a.p_turno,empresa_id:data.flota_usuarios[0].empresa_id,fecha:a.p_fecha,turno:a.p_turno,estado:'abierta'};data.rutas_generales.push(r)}return {data:r.id,error:null}}
  if(n==='flota_reorganizar_pendientes_heredados'){const d=data.rutas_generales.find(x=>x.turno===a.p_turno&&x.fecha===a.p_fecha);let c=0;data.pedidos.forEach(p=>{if(p.ruta_general_id&&p.ruta_general_id!==d.id&&(p.turno||'sin_definir')===a.p_turno){p.ruta_general_id=d.id;c++}});return {data:c,error:null}}
  if(n==='admin_confirmar_ruta_optimizada'){a.p_orden_ids.forEach((id,i)=>{const p=data.pedidos.find(x=>x.id===id);p.numero_general=i+1;p.ruta_general_id=a.p_ruta_general_id});data.rutas_generales.find(x=>x.id===a.p_ruta_general_id).estado='optimizada';return {data:null,error:null}}
  if(n==='flota_asignar_lote'){a.p_pedidos.forEach(id=>{data.pedidos.find(x=>x.id===id).motorista_id=a.p_motorista});return {data:a.p_pedidos.length,error:null}}
  if(n==='flota_anexar_pedidos_a_ruta'){const r=data.rutas_generales.find(x=>x.id===a.p_ruta);if(!['optimizada','en_reparto'].includes(r.estado))return {data:null,error:{message:'Solo se puede anexar a una ruta confirmada con turno'}};let mx=Math.max(0,...data.pedidos.filter(p=>p.ruta_general_id===r.id).map(p=>p.numero_general||0));a.p_pedidos.forEach((id,i)=>{const p=data.pedidos.find(x=>x.id===id);p.ruta_general_id=r.id;p.numero_general=mx+i+1});return {data:a.p_pedidos.length,error:null}}
  if(n==='flota_cerrar_ruta'){const ab=data.pedidos.filter(p=>p.ruta_general_id===a.p_ruta&&!['entregado','rechazado','cancelado'].includes(p.estado)).length;if(ab)return {data:null,error:{message:'Quedan '+ab+' pedidos pendientes o con incidencias; resolvelos antes de cerrar'}};data.rutas_generales.find(x=>x.id===a.p_ruta).estado='cerrada';return {data:true,error:null}}
  return {data:null,error:null}},
  channel:()=>{const ch={on:()=>ch,subscribe:()=>ch,unsubscribe(){}};return ch},removeChannel(){},removeAllChannels(){}};
 window.supabase={createClient:()=>client};
})();
