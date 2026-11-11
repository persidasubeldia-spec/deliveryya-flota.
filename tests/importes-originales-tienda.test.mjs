import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const file=p=>readFileSync(new URL('../'+p,import.meta.url),'utf8');
const tienda=file('index.html');
const central=file('central.html');
const migration=file('supabase/migrations/20261111160000_flota_importes_originales_tienda.sql');
const rollback=file('supabase/rollback/20261111160000_flota_importes_originales_tienda.sql');
const begin=central.indexOf('function dyEnvioValoresCentral(o){');
const end=central.indexOf("const pages=['Inicio','Pedidos'",begin);
assert.ok(begin>=0&&end>begin);
const h=new Function('money',central.slice(begin,end)+'return {dyPrecioOriginalTienda,dyMercaderiaVistaCentral,dyEnvioVistaCentral};')(n=>'Gs. '+Number(n||0).toLocaleString('es-PY'));
test('Tienda envía al servidor los dos importes originales antes de regla Boom',()=>{
 assert.match(tienda,/precio_mercaderia_cargado_tienda:v\.goods/);
 assert.match(tienda,/precio_delivery_cargado_tienda:v\.shipping/);
 assert.match(tienda,/precio_delivery:boomImportes\(v\.shipping\)\.real/);
 assert.match(tienda,/Delivery que ingresaste:/);
 assert.match(tienda,/Tarifa seleccionada:/);
});
test('Central muestra exactamente lo que tienda cargó aunque tarifa interna cambió',()=>{
 const p={precio_mercaderia:100000,precio_mercaderia_cargado_tienda:100000,
   precio_delivery:25000,precio_delivery_cargado_tienda:20000,
   delivery_cliente:20000,delivery_subsidio_tienda:5000};
 const envio=h.dyEnvioVistaCentral(p);
 assert.match(envio,/Tienda cargó: Gs\. 20\.000/);
 assert.match(envio,/Cliente paga: Gs\. 20\.000/);
 assert.match(envio,/Tienda: Gs\. 5\.000/);
 assert.match(envio,/Tarifa real: Gs\. 25\.000/);
 assert.match(h.dyMercaderiaVistaCentral(p),/Tienda cargó: Gs\. 100\.000/);
});
test('Pedidos anteriores muestran no registrado, NO dato inventado',()=>{
 const old={precio_mercaderia:70000,precio_delivery:25000,delivery_cliente:20000,delivery_subsidio_tienda:5000};
 assert.match(h.dyEnvioVistaCentral(old),/Tienda cargó: No registrado/);
 assert.match(h.dyMercaderiaVistaCentral(old),/Tienda cargó: No registrado/);
});
test('Lista, detalle y editor de Central muestran ambos precios iniciales',()=>{
 for(const x of ['Mercadería (actual / original)','Envío (original tienda / cliente / subsidio / real)',
   "dyMercaderiaVistaCentral(o)+'</td><td>'+dyEnvioVistaCentral(o)",
   "dyPrecioOriginalTienda(o,'precio_mercaderia_cargado_tienda')",
   "dyPrecioOriginalTienda(o,'precio_delivery_cargado_tienda')",
   'Original ingresado por tienda: Mercadería']){
    assert.ok(central.includes(x),x);
   }
});
test('SQL guarda valores originales inmutables y valida posibles inconsistencias',()=>{
 assert.match(migration,/ADD COLUMN IF NOT EXISTS precio_mercaderia_cargado_tienda integer/);
 assert.match(migration,/ADD COLUMN IF NOT EXISTS precio_delivery_cargado_tienda integer/);
 assert.match(migration,/BEFORE UPDATE OF precio_mercaderia_cargado_tienda,precio_delivery_cargado_tienda/);
 assert.match(migration,/AFTER INSERT ON public\.pedidos/);
 assert.match(migration,/NEW\.precio_delivery_cargado_tienda=20000/);
 assert.match(migration,/NEW\.delivery_subsidio_tienda=5000/);
 assert.match(rollback,/Conservar las columnas/);
 assert.doesNotMatch(migration,/\bUPDATE\s+public\.pedidos\b/i);
});
