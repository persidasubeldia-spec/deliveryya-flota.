import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const html=readFileSync(new URL('../central.html',import.meta.url),'utf8');
const start=html.indexOf('function rdLineaTienda(m,p,r){'),end=html.indexOf('function rdMotos(d){',start);
assert.ok(start>=0&&end>start,'Rendición y auditoría disponibles');
const tienda={id:'boom',codigo:'T14',nombre_comercial:'Boom Store'};
const rdGs=n=>'Gs. '+Number(n||0).toLocaleString('es-PY');
const fx=new Function('stores','routes','diaPY','rdGs',html.slice(start,end)+';return {rdLineaTienda,rdTiendas,rdValidarTienda}')( [tienda],[],()=> '2026-11-11',rdGs);
function dataset(){
 const movs=[],orders=[],rech=new Map();
 // 12 entregas subsidiadas: 12 × 5.000 = 60.000. Mercadería: 960.000.
 for(let i=0;i<12;i++){
  const id='min'+i;
  orders.push({id,tienda_id:'boom',nombre_cliente:'Cliente mínimo '+i,estado:'entregado',modalidad_pago:'pendiente',
   created_at:'2026-11-11T14:00:00Z',precio_mercaderia:80000,precio_delivery:25000,
   delivery_cliente:20000,delivery_subsidio_tienda:5000,turno:'manana'});
  movs.push({id:'mov'+id,pedido_id:id,tienda_id:'boom',motorista_id:'boli',monto_mercaderia:80000,monto_delivery:25000,
   efectivo_cobrado:100000,transferencia_cobrada:0,comision_motorista:18750,comision_empresa:6250});
 }
 // 5 entregas sin subsidio: 5 × 100.000 = 500.000. Total mercadería 1.460.000.
 for(let i=0;i<5;i++){
  const id='alta'+i;
  orders.push({id,tienda_id:'boom',nombre_cliente:'Cliente alta '+i,estado:'entregado',modalidad_pago:'pendiente',
   created_at:'2026-11-11T14:00:00Z',precio_mercaderia:100000,precio_delivery:30000,
   delivery_cliente:30000,delivery_subsidio_tienda:0,turno:'tarde'});
  movs.push({id:'mov'+id,pedido_id:id,tienda_id:'boom',motorista_id:'boli',monto_mercaderia:100000,monto_delivery:30000,
   efectivo_cobrado:130000,transferencia_cobrada:0,comision_motorista:22500,comision_empresa:7500});
 }
 orders.push({id:'fabby',tienda_id:'boom',nombre_cliente:'Fabby',estado:'rechazado',modalidad_pago:'pendiente',
  created_at:'2026-11-11T14:00:00Z',precio_mercaderia:100000,precio_delivery:25000,
  delivery_cliente:20000,delivery_subsidio_tienda:5000,turno:'manana'});
 movs.push({id:'rechazo',pedido_id:'fabby',tienda_id:'boom',monto_delivery:25000,
  monto_mercaderia:0,efectivo_cobrado:0,transferencia_cobrada:0,
  comision_motorista:18750,comision_empresa:6250,es_rechazo_facturable:true});
 rech.set('fabby',{responsable_pago:'tienda',importe_cobrado:0,importe_pendiente:25000});
 return {fecha:'2026-11-11',movs,porPedido:new Map(orders.map(x=>[x.id,x])),rech,
  compensaciones:[],pagos:[],rechazosDeuda:[],reprogramados:[]};
}
const calc=d=>fx.rdTiendas(d)[0];
test('Boom Store: 17 entregas + rechazo Fabby resultan exactamente Gs. 1.375.000',()=>{
 const d=dataset(),t=calc(d),v=fx.rdValidarTienda(t,d);
 assert.equal(t.ent,17);assert.equal(t.rej,1);
 assert.equal(t.merc,1460000);assert.equal(t.subsidiosTienda,60000);
 assert.equal(t.cargosPendientes,25000);assert.equal(t.neto,1375000);
 assert.equal(v.esperado,1375000);assert.deepEqual(v.errores,[]);
});
test('No incluir mercadería rechazada, ni 5.000 de subsidio del mismo rechazo',()=>{
 const d=dataset(),t=calc(d);
 assert.equal(t.subsidiosTienda,60000);
 assert.equal(t.cargosPendientes,25000);
 assert.equal(t.merc,1460000);
});
test('Compensación de rechazo sustituye descuento directo, sin descontar dos veces',()=>{
 const d=dataset();
 d.compensaciones=[{pedido_id:'fabby',tienda_id:'boom',importe:25000}];
 const t=calc(d),v=fx.rdValidarTienda(t,d);
 assert.equal(t.cargosPendientes,0);
 assert.equal(t.compensado,25000);
 assert.equal(t.neto,1375000);
 assert.deepEqual(v.errores,[]);
});
test('Pago confirmado a tienda resta sólo del saldo pendiente',()=>{
 const d=dataset();d.pagos=[{tienda_id:'boom',importe:500000}];
 const t=calc(d),v=fx.rdValidarTienda(t,d);
 assert.equal(t.neto,1375000);assert.equal(t.saldo,875000);
 assert.deepEqual(v.errores,[]);
});
test('Detectar cobro incorrecto; bloquear rendición y PDF',()=>{
 const d=dataset();d.movs[0].efectivo_cobrado=105000;
 const v=fx.rdValidarTienda(calc(d),d);
 assert.ok(v.errores.some(e=>e.includes('Cobro diferente')));
 assert.match(html,/Rendición bloqueada por inconsistencias/);
 assert.match(html,/PDF bloqueado/);
 assert.match(html,/data-rdpdf=\"'\+i\+'\" '\+\(ver.errores.length\?'disabled/);
});
test('Detectar doble movimiento y reparto incorrecto de comisión',()=>{
 const d=dataset();const f={...d.movs[0],id:'duplicado',comision_empresa:5000};
 d.movs.push(f);
 const v=fx.rdValidarTienda(calc(d),d);
 assert.ok(v.errores.some(e=>e.includes('duplicado')));
 assert.ok(v.errores.some(e=>e.includes('comisión')));
});
test('Detectar rechazo sin detalle y no generar saldo provisional falso',()=>{
 const d=dataset();d.rech.delete('fabby');
 const v=fx.rdValidarTienda(calc(d),d);
 assert.ok(v.errores.some(e=>e.includes('Rechazo sin detalle')));
});
test('PDF usa datos frescos y muestra subsidio separado y encabezado correcto',()=>{
 const f=html.slice(html.indexOf('async function rdPdf(t,fecha){'),html.indexOf('async function rdPdf(t,fecha){')+16000);
 assert.match(f,/const datosAudit=await rdCargar\(fecha\)/);
 assert.match(f,/const verificacion=rdValidarTienda\(t,datosAudit\)/);
 assert.match(f,/Envío cliente','Subsidio tienda','Cobrado/);
 assert.doesNotMatch(f,/Envío de Iván/);
 assert.match(f,/verificacion.componentes.rechazos/);
 assert.match(f,/verificacion.componentes.subsidio/);
 assert.match(f,/verificacion.esperado/);
 assert.match(f,/AUDITORÍA DE RENDICIÓN/);
});
