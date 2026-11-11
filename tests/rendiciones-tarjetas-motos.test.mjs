import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const html=readFileSync(new URL('../central.html',import.meta.url),'utf8');
const i=html.indexOf('function rdMotos(d){'),j=html.indexOf('function rdAuditar(d){',i);
assert.ok(i>=0&&j>i);
const id='motorista-test',moto={id,nombre:'Boli Diego',activo:true,modalidad_liquidacion:'retener_comision'};
const money=n=>'Gs. '+Number(n||0).toLocaleString('es-PY'),escapeHtml=s=>String(s??'');
const h=new Function('drivers','routes','stores','account','money','escapeHtml',html.slice(i,j)+'return {rdMotos,rdEstadoMoto,rdCardMoto,rdDetalleMoto,rdSaldoMoto}')([moto],[],[],{rol:'propietario',puede_confirmar_rendiciones:true},money,escapeHtml);
const p1={id:'a',nombre_cliente:'Cliente entregado',estado:'entregado',numero_general:1,precio_mercaderia:100000,delivery_cliente:20000,motorista_id:id,modalidad_pago:'pendiente'};
const p2={id:'b',nombre_cliente:'Cliente rechazado',estado:'rechazado',numero_general:2,motorista_id:id,precio_mercaderia:100000};
const m1={pedido_id:'a',motorista_id:id,efectivo_cobrado:120000,transferencia_cobrada:0,comision_motorista:18750,comision_empresa:6250,monto_mercaderia:100000,monto_delivery:25000};
const m2={pedido_id:'b',motorista_id:id,efectivo_cobrado:0,transferencia_cobrada:0,comision_motorista:18750,comision_empresa:6250,monto_mercaderia:0,monto_delivery:25000};
const data={fecha:'2026-11-11',movs:[m1,m2],cierres:[],porPedido:new Map([['a',p1],['b',p2]]),rech:new Map([['b',{importe_pendiente:25000,responsable_pago:'tienda'}]]),reprogramados:[]};
test('Tarjeta individual accesible con botón de motorista',()=>{
 const [r]=h.rdMotos(data),card=h.rdCardMoto(r,0);
 assert.match(card,/Boli Diego/);assert.match(card,/data-rdmoto="0"/);assert.match(card,/aria-expanded="false"/);
});
test('Rechazo no cobrado separado del efectivo y su comisión',()=>{
 const [r]=h.rdMotos(data);assert.equal(r.ef,120000);
 assert.equal(r.cmEnt,18750);assert.equal(r.cmRej,18750);
 assert.equal(r.rendir,82500);assert.equal(r.rendirEntregas,101250);
 const detail=h.rdDetalleMoto(r,data);
 assert.match(detail,/Comisión de rechazos/);assert.match(detail,/Gs. 25.000/);
 assert.match(detail,/Gs. 101.250/);assert.match(detail,/Cliente rechazado/);
});
test('Declarado no equivale a efectivo recibido',()=>{
 const d={...data,cierres:[{motorista_id:id,a_rendir_esperado:82500,estado:'presentada',efectivo_declarado:82500,efectivo_recibido:null,transferencia_confirmada:null}]};
 const [r]=h.rdMotos(d);assert.equal(h.rdSaldoMoto(r),82500);
 assert.match(h.rdDetalleMoto(r,d),/No registrado/);
});
test('Cierre registrado confirmado tiene saldo cero',()=>{
 const d={...data,cierres:[{motorista_id:id,a_rendir_esperado:82500,estado:'confirmada',efectivo_declarado:82500,efectivo_recibido:82500,transferencia_confirmada:0}]};
 const [r]=h.rdMotos(d);assert.equal(h.rdSaldoMoto(r),0);assert.match(h.rdEstadoMoto(r),/confirmado/);
});
test('Existe PDF individual y confirmación autorizada de recepción',()=>{
 assert.match(html,/rdPdfMotoCentral\(r,d\)/);assert.match(html,/data-rdrecibirm/);
 assert.match(html,/flota_confirmar_cierre_completo/);
 assert.match(html,/if\(!confirm\('¿YA recibiste/);
 assert.match(html,/Number\.isSafeInteger\(efectivo\)/);
});
