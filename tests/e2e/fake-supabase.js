// Cliente Supabase falso para probar la interfaz sin tocar la base real.
(function(){
 const pedidos=[
  {id:'p1',nombre_cliente:'Cliente Uno',telefono_cliente:'0971 000 001',direccion_cliente:'Calle 1',lat:-25.28,lng:-57.63,numero_general:1,turno:'manana',precio_mercaderia:100000,precio_delivery:25000,modalidad_pago:'pendiente',estado:'pendiente',version_edicion:1},
  {id:'p2',nombre_cliente:'Cliente Dos',telefono_cliente:'0971000002',direccion_cliente:'Calle 2',lat:-25.29,lng:-57.62,numero_general:2,turno:'manana',precio_mercaderia:80000,precio_delivery:25000,modalidad_pago:'todo_pagado',estado:'pendiente',version_edicion:1},
  {id:'p3',nombre_cliente:'Cliente Tres',telefono_cliente:'0971000003',direccion_cliente:'Calle 3',lat:-25.30,lng:-57.61,numero_general:3,turno:'manana',precio_mercaderia:50000,precio_delivery:25000,modalidad_pago:'producto_pagado',estado:'no_recibio',version_edicion:1}];
 window.__rpc=[];
 const data={motoristas:[{id:'m1',usuario_id:'u1',nombre:'Moto Prueba',activo:true,porcentaje_empresa_pct:25,color_identificador:'#16A34A'}],pedidos,motorista_ordenes_pedidos:[],movimientos_financieros:[],flota_cierres_motoristas:[],flota_rechazos_detalle:[]};
 function q(table){const res={data:data[table]||[],error:null};const c={then:(r,j)=>Promise.resolve(res).then(r,j)};for(const m of ['select','eq','order','limit','gte','lte','in','neq','is','not','range','filter','match'])c[m]=()=>c;c.single=()=>Promise.resolve({data:(data[table]||[])[0]||null,error:null});c.maybeSingle=c.single;return c}
 const client={auth:{getSession:async()=>({data:{session:{user:{id:'u1',email:'moto@test.local'}}}}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),signOut:async()=>({}),signInWithPassword:async()=>({data:{},error:null})},
  from:q,rpc:async(name,args)=>{window.__rpc.push({name,args});return {data:true,error:null}},
  channel:()=>{const ch={on:()=>ch,subscribe:()=>ch,unsubscribe(){}};return ch},removeChannel(){}};
 window.supabase={createClient:()=>client};
})();
