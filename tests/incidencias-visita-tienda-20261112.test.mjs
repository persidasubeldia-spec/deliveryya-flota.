import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const main=readFileSync(new URL('../central.html',import.meta.url),'utf8');
const migration=readFileSync(new URL('../supabase/migrations/20261112230000_flota_incidencias_visita_auditadas.sql',import.meta.url),'utf8');
const a=main.indexOf('function rdLineaTienda('),b=main.indexOf('function rdMotos(',a);
assert.ok(a>=0&&b>a);
const shop={id:'boom',codigo:'T14',nombre_comercial:'Boom Store'};
const f=new Function('stores','routes','diaPY','rdGs',main.slice(a,b)+'return {rdTiendas,rdValidarTienda}')([shop],[],()=> '2026-11-12',n=>String(n));
function datos(){
 const movs=[],pedidos=[],rech=new Map();
 for(let i=0;i<4;i++){
 const p={id:'e'+i,tienda_id:'boom',nombre_cliente:'Entrega '+i,estado:'entregado',modalidad_pago:'pendiente',created_at:'2026-11-12T15:00:00Z',precio_delivery:25000,delivery_cliente:20000,delivery_subsidio_tienda:5000,precio_mercaderia:[70000,100000,70000,105000][i],turno:'manana'};
 pedidos.push(p);movs.push({id:'em'+i,pedido_id:p.id,tienda_id:'boom',monto_mercaderia:p.precio_mercaderia,monto_delivery:25000,efectivo_cobrado:p.precio_mercaderia+20000,transferencia_cobrada:0,comision_motorista:18750,comision_empresa:6250});
 }
 for(const [id,name] of [['d','Diego Britez'],['g','Gael']]){
  const p={id,tienda_id:'boom',nombre_cliente:name,estado:'rechazado',motivo_incidencia:'Incidencia facturable: visita realizada y no cobrada',modalidad_pago:'pendiente',created_at:'2026-11-12T15:00:00Z',precio_delivery:25000,delivery_cliente:20000,delivery_subsidio_tienda:5000,precio_mercaderia:100000,turno:'manana'};
  pedidos.push(p);movs.push({id:'im'+id,pedido_id:p.id,tienda_id:'boom',monto_mercaderia:0,monto_delivery:25000,efectivo_cobrado:0,transferencia_cobrada:0,comision_motorista:18750,comision_empresa:6250,es_rechazo_facturable:true});
  rech.set(id,{responsable_pago:'tienda',importe_cobrado:0,importe_pendiente:25000});
 }
 return {fecha:'2026-11-12',movs,porPedido:new Map(pedidos.map(p=>[p.id,p])),rech,compensaciones:[],pagos:[],rechazosDeuda:[],reprogramados:[]};
}
test('12/11 T14: 4 entregas, 2 incidencias facturables, neto tienda 275.000',()=>{
 const d=datos(),t=f.rdTiendas(d)[0],v=f.rdValidarTienda(t,d);
 assert.equal(t.ent,4);assert.equal(t.rej,2);
 assert.equal(t.merc,345000);assert.equal(t.subsidiosTienda,20000);
 assert.equal(t.cargosPendientes,50000);assert.equal(t.neto,275000);
 assert.equal(v.esperado,275000);assert.deepEqual(v.errores,[]);
});
test('Boli y Central: comisiones incidencias 37.500 + 12.500; clientes abonaron cero',()=>{
 const d=datos(),inc=d.movs.filter(m=>m.es_rechazo_facturable);
 assert.equal(inc.reduce((n,m)=>n+m.comision_motorista,0),37500);
 assert.equal(inc.reduce((n,m)=>n+m.comision_empresa,0),12500);
 assert.equal(inc.reduce((n,m)=>n+m.efectivo_cobrado,0),0);
 assert.equal(d.movs.reduce((n,m)=>n+m.comision_motorista,0),112500);
 assert.equal(d.movs.reduce((n,m)=>n+m.comision_empresa,0),37500);
});
test('Incidencias NO suman el subsidio 5.000 ni mercadería de pedidos no entregados',()=>{
 const t=f.rdTiendas(datos())[0];assert.equal(t.subsidiosTienda,20000);assert.equal(t.merc,345000);
});
test('No_recibio sin movimiento ni detalle permanece sin facturar automáticamente',()=>{
 const d=datos();const p={id:'n',tienda_id:'boom',estado:'no_recibio',motivo_incidencia:'No encontró al cliente',created_at:'2026-11-12T15:00:00Z'};
 d.porPedido.set('n',p);
 const t=f.rdTiendas(d)[0];assert.equal(t.neto,275000);assert.deepEqual(f.rdValidarTienda(t,d).errores,[]);
});
test('Central y PDF distinguen incidencia facturable y muestran el cargo a tienda',()=>{
 assert.match(main,/Visitas fallidas facturables a la tienda:/);
 assert.match(main,/cargo deducido una sola vez de la rendición/i);
 assert.match(main,/\?'Incidencia':label\(p\)/);
 assert.match(main,/Rechazos e incidencias facturables a tienda \(-\)/);
 assert.match(main,/verificacion\.componentes\.rechazos/);
});
test('Auditoría dedicada inmutable desde API pública y única por pedido',()=>{
 assert.match(migration,/CONSTRAINT flota_incidencias_visita_pedido_unico UNIQUE\(pedido_id\)/);
 assert.match(migration,/ENABLE ROW LEVEL SECURITY/);
 assert.match(migration,/REVOKE ALL .* FROM PUBLIC,anon,authenticated/);
 assert.doesNotMatch(migration,/\bUPDATE public\.pedidos\b/);
});
