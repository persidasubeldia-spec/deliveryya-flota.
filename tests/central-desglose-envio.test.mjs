import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const html=readFileSync(new URL('../central.html',import.meta.url),'utf8');
const start=html.indexOf('function dyEnvioValoresCentral(o){');
const end=html.indexOf("const pages=['Inicio','Pedidos'",start);
assert.ok(start>=0&&end>start,'Funciones de desglose en Central');
const helpers=new Function('money',html.slice(start,end)+'; return {dyEnvioValoresCentral,dyEnvioPreviewCentral,dyEnvioVistaCentral};')(n=>'Gs. '+Number(n||0).toLocaleString('es-PY'));
const boom={precio_mercaderia:100000,precio_delivery:25000,delivery_cliente:20000,delivery_subsidio_tienda:5000,regla_comercial:'boom_25k_cliente_20k_v1',modalidad_pago:'pendiente'};
const sinSubsidio={precio_mercaderia:100000,precio_delivery:30000,delivery_cliente:null,delivery_subsidio_tienda:null,regla_comercial:null};

test('Boom Store existente muestra 20.000 al cliente, 5.000 a tienda y 25.000 real',()=>{
 assert.deepEqual(helpers.dyEnvioValoresCentral(boom),{real:25000,cliente:20000,subsidio:5000});
 const vista=helpers.dyEnvioVistaCentral(boom);
 for(const v of ['Cliente: Gs. 20.000','Tienda: Gs. 5.000','Tarifa real: Gs. 25.000'])assert.ok(vista.includes(v),v);
 assert.equal(boom.precio_mercaderia+helpers.dyEnvioValoresCentral(boom).cliente,120000);
});
test('La misma visualización sirve para pedidos de hoy y futuros sin fecha especial',()=>{
 for(const fecha of ['2026-11-11','2026-11-12','2027-01-01']){
  const order={...boom,created_at:fecha};
  assert.equal(helpers.dyEnvioValoresCentral(order).cliente,20000);
  assert.equal(helpers.dyEnvioValoresCentral(order).subsidio,5000);
 }
});
test('Pedidos anteriores o sin subsidio conservan la tarifa real como cobro cliente',()=>{
 assert.deepEqual(helpers.dyEnvioValoresCentral(sinSubsidio),{real:30000,cliente:30000,subsidio:0});
});
test('La edición de tarifa Boom respeta la regla oficial y recalcula el cobro al cliente',()=>{
 assert.deepEqual(helpers.dyEnvioPreviewCentral(boom,20000),{real:25000,cliente:20000,subsidio:5000});
 assert.deepEqual(helpers.dyEnvioPreviewCentral(boom,25000),{real:25000,cliente:20000,subsidio:5000});
 assert.deepEqual(helpers.dyEnvioPreviewCentral(boom,30000),{real:30000,cliente:30000,subsidio:0});
 assert.deepEqual(helpers.dyEnvioPreviewCentral(sinSubsidio,35000),{real:35000,cliente:35000,subsidio:0});
});
test('Lista, detalle y ruta usan desglose; WhatsApp toma delivery del cliente',()=>{
 assert.match(html,/<th>Envío \(cliente \/ tienda \/ real\)<\/th>/);
 assert.match(html,/money\(o\.precio_mercaderia\)\+'<\/td><td>'\+dyEnvioVistaCentral\(o\)/);
 assert.match(html,/Envío: '\+dyEnvioVistaCentral\(o\)/);
 assert.match(html,/Total a cobrar cliente/);
 assert.match(html,/dyEnvioValoresCentral\(o\)\.cliente,o\.modalidad_pago/);
 assert.match(html,/const envioAlCliente=tarifaReal=>dyEnvioPreviewCentral\(o,tarifaReal\)/);
 assert.match(html,/const v=envioAlCliente\(e\)/);
 assert.match(html,/Tarifa real del delivery \(₲\)/);
});
